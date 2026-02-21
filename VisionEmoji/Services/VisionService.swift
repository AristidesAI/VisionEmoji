//
//  VisionService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import Foundation
import Vision
import CoreML
import AVFoundation
import Combine
import CoreImage

@MainActor
class VisionService: ObservableObject {
    // MARK: - Published Properties

    @Published var detectionResults: [DetectionResult] = []
    @Published var isProcessing = false

    // Task toggle
    @Published var isClassificationEnabled = true {
        didSet { if isClassificationEnabled { ensureModelLoaded(task: .classify) } }
    }

    // Detection tuning
    @Published var confidenceThreshold: Float = 0.25
    @Published var maxDetections: Int = 50

    // Classification tuning
    @Published var classificationConfidenceThreshold: Float = 0.3
    @Published var labelPriority: Float = 0.5  // 0=YOLO, 1=ImageNet

    // Processing controls
    @Published var targetFPS: Int = 30

    // Performance metrics (throttled to avoid UI re-render storms)
    @Published var objectProcessingTime: Double = 0
    @Published var classifyProcessingTime: Double = 0
    @Published var fps: Double = 0
    @Published var classificationsCached: Int = 0

    // Internal metric accumulators (updated every frame, published throttled)
    private var internalFPS: Double = 0
    private var internalDetMs: Double = 0
    private var internalClsMs: Double = 0
    private var lastMetricPublish: CFAbsoluteTime = 0
    private let metricPublishInterval: Double = 0.5

    // MARK: - Private Properties

    // Cached VNCoreMLModel instances (lazy-loaded per task)
    nonisolated(unsafe) private var loadedModels: [ModelKey: VNCoreMLModel] = [:]
    nonisolated(unsafe) private var modelLock = NSLock()

    // Single detection queue at highest priority
    nonisolated(unsafe) private let detectionQueue = DispatchQueue(
        label: "com.visionemoji.detection",
        qos: DispatchQoS(qosClass: .userInteractive, relativePriority: 0)
    )

    // Track objects across frames (protected by trackingLock)
    nonisolated(unsafe) private var trackedObjects: [UUID: TrackedObject] = [:]
    nonisolated(unsafe) private var trackingLock = NSLock()

    // Per-object classification cache
    nonisolated(unsafe) private var clsCache: [UUID: ClsCacheEntry] = [:]
    nonisolated(unsafe) private var clsCacheLock = NSLock()

    // CIContext for efficient cropping (reusable, thread-safe)
    nonisolated(unsafe) private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    // Device-optimized compute units
    nonisolated(unsafe) private let preferredComputeUnits: MLComputeUnits = {
        // A17 Pro+ (iPhone 15 Pro, 16 series) benefit from .cpuAndNeuralEngine
        // to avoid GPU contention with camera/display pipeline.
        // Older devices use .all to let the system decide.
        var sysInfo = utsname()
        uname(&sysInfo)
        let machine = withUnsafePointer(to: &sysInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }

        // iPhone16,* = iPhone 15 Pro/Max (A17 Pro)
        // iPhone17,* = iPhone 16 series (A18/A18 Pro)
        // iPhone18,* = iPhone 17 series (A19)
        if machine.hasPrefix("iPhone16,") ||
           machine.hasPrefix("iPhone17,") ||
           machine.hasPrefix("iPhone18,") {
            return .cpuAndNeuralEngine
        }
        return .all
    }()

    nonisolated(unsafe) private let objectLifetime: TimeInterval = 1.5

    // Frame counter & FPS cap
    private var frameCounter = 0
    private var lastProcessedTime: CFAbsoluteTime = 0
    private var lastCleanupTime: CFAbsoluteTime = 0

    // FPS tracking (exponential smoothing)
    private var lastFrameTimestamp: CFAbsoluteTime = 0

    // MARK: - Init

    init() {
        ensureModelLoaded(task: .detect)
        ensureModelLoaded(task: .classify)
    }

    // MARK: - Model Loading

    private func ensureModelLoaded(task: YOLOTask) {
        detectionQueue.async { [weak self] in
            self?.getOrLoadModel(task: task)
        }
    }

    @discardableResult
    nonisolated private func getOrLoadModel(task: YOLOTask) -> VNCoreMLModel? {
        let key = ModelKey(task: task)

        modelLock.lock()
        if let cached = loadedModels[key] {
            modelLock.unlock()
            return cached
        }
        modelLock.unlock()

        let resourceName = task.resourceName
        guard let modelURL = Bundle.main.url(forResource: resourceName, withExtension: "mlmodelc") else {
            print("[\(resourceName)] Model not found in bundle")
            return nil
        }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = preferredComputeUnits

            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            let vnModel = try VNCoreMLModel(for: mlModel)

            modelLock.lock()
            loadedModels[key] = vnModel
            modelLock.unlock()

            print("[\(resourceName)] Loaded successfully")
            return vnModel
        } catch {
            print("[\(resourceName)] Load failed: \(error)")
            return nil
        }
    }

    private func clearTrackedObjects() {
        trackingLock.lock()
        trackedObjects.removeAll()
        trackingLock.unlock()
        detectionResults = []
    }

    // MARK: - Public Methods

    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // FPS cap gating
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastProcessedTime >= 1.0 / Double(targetFPS) else { return }
        lastProcessedTime = now

        frameCounter += 1

        // Capture settings on main actor before dispatching
        let threshold = confidenceThreshold
        let maxDet = maxDetections
        let clsOn = isClassificationEnabled
        let frame = frameCounter
        let clsThreshold = classificationConfidenceThreshold
        let priority = labelPriority

        updateFPS()

        // Throttle cleanup to every 500ms instead of every frame
        if now - lastCleanupTime >= 0.5 {
            lastCleanupTime = now
            cleanupOldObjects()
            cleanupClassificationCache()
        }

        let group = DispatchGroup()

        // Primary: YOLO26m detection (every frame)
        group.enter()
        detectionQueue.async { [weak self] in
            self?.performDetection(on: pixelBuffer, threshold: threshold, maxDet: maxDet)
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // After detection, optionally run per-object classification
            if clsOn && frame % 3 == 0 {
                self.dispatchPerObjectClassification(
                    pixelBuffer: pixelBuffer,
                    clsThreshold: clsThreshold,
                    priority: priority
                )
            }

            self.resolveOverlapsAndPublish(maxDet: maxDet, clsThreshold: clsThreshold, priority: priority)
        }
    }

    func updateCameraPosition(isFront: Bool) {
        _ = isFront
    }

    func unloadAndReload() {
        modelLock.lock()
        loadedModels.removeAll()
        modelLock.unlock()

        clsCacheLock.lock()
        clsCache.removeAll()
        clsCacheLock.unlock()

        clearTrackedObjects()
        // Models auto-reload on next processFrame()
    }

    // MARK: - FPS Tracking (Exponential Smoothing, throttled publishing)

    private func updateFPS() {
        let now = CFAbsoluteTimeGetCurrent()
        if lastFrameTimestamp > 0 {
            let dt = now - lastFrameTimestamp
            if dt > 0 {
                let instantFPS = 1.0 / dt
                internalFPS = 0.05 * instantFPS + 0.95 * internalFPS
            }
        }
        lastFrameTimestamp = now

        // Throttle @Published metric updates to reduce SwiftUI re-renders
        if now - lastMetricPublish >= metricPublishInterval {
            lastMetricPublish = now
            fps = internalFPS
            objectProcessingTime = internalDetMs
            classifyProcessingTime = internalClsMs
            classificationsCached = internalClsCached
        }
    }

    // MARK: - Object Detection (YOLO26m — end-to-end, tensor [1, 300, 6])

    nonisolated private func performDetection(on pixelBuffer: CVPixelBuffer, threshold: Float, maxDet: Int) {
        guard let vnModel = getOrLoadModel(task: .detect) else { return }

        let startTime = CFAbsoluteTimeGetCurrent()

        let request = VNCoreMLRequest(model: vnModel) { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                print("Object detection error: \(error)")
                return
            }

            self.handleDetectionResults(request: request, threshold: threshold, inputSize: 640, maxDet: maxDet)

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            DispatchQueue.main.async {
                self.internalDetMs = 0.05 * (elapsed * 1000) + 0.95 * self.internalDetMs
            }
        }

        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do { try handler.perform([request]) }
        catch { print("Object detection failed: \(error)") }
    }

    nonisolated private func handleDetectionResults(request: VNRequest, threshold: Float, inputSize: CGFloat, maxDet: Int) {
        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let multiArray = results.first?.featureValue.multiArrayValue else { return }

        let shape = multiArray.shape.map { $0.intValue }
        guard shape.count == 3, shape[2] == 6 else {
            print("Unexpected detection output shape: \(shape)")
            return
        }

        let strides = multiArray.strides.map { $0.intValue }
        let pointer = multiArray.dataPointer.assumingMemoryBound(to: Float.self)

        let numDetections = shape[1]
        let detStride = strides[1]
        let fieldStride = strides[2]

        var count = 0
        for i in 0..<numDetections {
            guard count < maxDet else { break }

            let base = i * detStride
            let conf = pointer[base + 4 * fieldStride]
            guard conf > threshold else { continue }

            let x1 = CGFloat(pointer[base])
            let y1 = CGFloat(pointer[base + fieldStride])
            let x2 = CGFloat(pointer[base + 2 * fieldStride])
            let y2 = CGFloat(pointer[base + 3 * fieldStride])
            let classIndex = Int(pointer[base + 5 * fieldStride])

            let normalizedBox = CGRect(
                x: x1 / inputSize,
                y: 1.0 - (y2 / inputSize),
                width: (x2 - x1) / inputSize,
                height: (y2 - y1) / inputSize
            )

            guard let mapping = EmojiMapping.emoji(forClassIndex: classIndex, confidence: conf) else { continue }

            addOrUpdateTrackedObject(
                label: mapping.label, emoji: mapping.emoji,
                boundingBox: normalizedBox, confidence: conf
            )
            count += 1
        }
    }

    // MARK: - Per-Object Crop Classification

    private func dispatchPerObjectClassification(
        pixelBuffer: CVPixelBuffer,
        clsThreshold: Float,
        priority: Float
    ) {
        trackingLock.lock()
        let objectsToClassify = Array(trackedObjects.values)
            .filter { $0.confidence > 0.3 }
            .prefix(5)  // Max 5 crops per frame for performance
        trackingLock.unlock()

        guard !objectsToClassify.isEmpty else { return }

        for tracked in objectsToClassify {
            detectionQueue.async { [weak self] in
                self?.classifyObjectCrop(
                    from: pixelBuffer,
                    bbox: tracked.boundingBox,
                    objectID: tracked.id
                )
            }
        }
    }

    nonisolated private func classifyObjectCrop(
        from pixelBuffer: CVPixelBuffer,
        bbox: CGRect,
        objectID: UUID
    ) {
        guard let vnModel = getOrLoadModel(task: .classify) else { return }

        let startTime = CFAbsoluteTimeGetCurrent()

        // Convert Vision normalized coords to pixel coords
        let width = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let height = CGFloat(CVPixelBufferGetHeight(pixelBuffer))

        let pixelX = bbox.origin.x * width
        let pixelY = (1.0 - bbox.origin.y - bbox.height) * height
        let pixelW = bbox.width * width
        let pixelH = bbox.height * height

        // Clamp to buffer bounds with minimum size
        let cropRect = CGRect(
            x: max(0, pixelX),
            y: max(0, pixelY),
            width: min(pixelW, width - max(0, pixelX)),
            height: min(pixelH, height - max(0, pixelY))
        )

        guard cropRect.width > 10 && cropRect.height > 10 else { return }

        // Create cropped CIImage (efficient — no pixel buffer allocation)
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).cropped(to: cropRect)

        let request = VNCoreMLRequest(model: vnModel) { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                print("Crop classification error: \(error)")
                return
            }

            if let classifications = request.results as? [VNClassificationObservation],
               let top = classifications.first {
                self.clsCacheLock.lock()
                self.clsCache[objectID] = ClsCacheEntry(
                    label: top.identifier,
                    confidence: top.confidence,
                    timestamp: Date()
                )
                self.clsCacheLock.unlock()
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            DispatchQueue.main.async {
                self.internalClsMs = 0.05 * (elapsed * 1000) + 0.95 * self.internalClsMs
            }
        }

        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(ciImage: ciImage, orientation: .up, options: [:])
        do { try handler.perform([request]) }
        catch { print("Crop classification failed: \(error)") }
    }

    // MARK: - Shared Tracking

    nonisolated private func addOrUpdateTrackedObject(
        label: String, emoji: String,
        boundingBox: CGRect, confidence: Float
    ) {
        trackingLock.lock()
        defer { trackingLock.unlock() }

        // Find existing tracked object by IoU match
        let existingObject = trackedObjects.values.first { tracked in
            iou(tracked.boundingBox, boundingBox) > 0.3
        }

        if let existing = existingObject {
            let newCenter = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
            if let prevCenter = trackedObjects[existing.id]?.previousCenter {
                let dt = Date().timeIntervalSince(existing.lastSeen)
                if dt > 0 && dt < 1.0 {
                    let vx = (newCenter.x - prevCenter.x) / CGFloat(dt)
                    let vy = (newCenter.y - prevCenter.y) / CGFloat(dt)
                    trackedObjects[existing.id]?.velocity = CGPoint(x: vx, y: vy)
                }
            }

            trackedObjects[existing.id]?.boundingBox = boundingBox
            trackedObjects[existing.id]?.confidence = confidence
            trackedObjects[existing.id]?.lastSeen = Date()
            trackedObjects[existing.id]?.emoji = emoji
            trackedObjects[existing.id]?.label = label
            trackedObjects[existing.id]?.previousCenter = newCenter
        } else if trackedObjects.count < 100 {
            let id = UUID()
            let center = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
            trackedObjects[id] = TrackedObject(
                id: id, label: label,
                boundingBox: boundingBox,
                confidence: confidence,
                emoji: emoji, lastSeen: Date(),
                previousCenter: center
            )
        }
    }

    // MARK: - Helper Methods

    private func cleanupOldObjects() {
        trackingLock.lock()
        defer { trackingLock.unlock() }

        let now = Date()
        trackedObjects = trackedObjects.filter { _, tracked in
            now.timeIntervalSince(tracked.lastSeen) < objectLifetime
        }
    }

    private var internalClsCached: Int = 0

    private func cleanupClassificationCache() {
        clsCacheLock.lock()
        defer { clsCacheLock.unlock() }

        let now = Date()
        clsCache = clsCache.filter { _, entry in
            now.timeIntervalSince(entry.timestamp) < 2.0
        }
        internalClsCached = clsCache.count
    }

    private func resolveOverlapsAndPublish(maxDet: Int, clsThreshold: Float, priority: Float) {
        trackingLock.lock()
        let allTracked = Array(trackedObjects.values)
        trackingLock.unlock()

        // Sort by confidence (highest first)
        let sorted = allTracked.sorted { $0.confidence > $1.confidence }

        var keptResults: [DetectionResult] = []
        var keptEntries: [(label: String, box: CGRect)] = []

        clsCacheLock.lock()
        let clsSnapshot = clsCache
        clsCacheLock.unlock()

        for tracked in sorted {
            guard keptResults.count < maxDet else { break }

            var shouldDrop = false
            for entry in keptEntries {
                let overlap = iou(tracked.boundingBox, entry.box)

                // Same label → stricter de-duplication (IoU > 0.2)
                if tracked.label == entry.label && overlap > 0.2 {
                    shouldDrop = true
                    break
                }

                // Different label → standard overlap threshold
                if overlap > 0.4 {
                    shouldDrop = true
                    break
                }
            }

            if !shouldDrop {
                // Blend labels based on classification cache and priority slider
                var finalLabel = tracked.label
                var finalEmoji = tracked.emoji
                var clsLabel: String? = nil

                if let cls = clsSnapshot[tracked.id], cls.confidence >= clsThreshold {
                    clsLabel = "\(cls.label) (\(Int(cls.confidence * 100))%)"

                    let useClsLabel: Bool
                    if priority >= 0.7 {
                        useClsLabel = true
                    } else if priority <= 0.3 {
                        useClsLabel = false
                    } else {
                        // Blend zone: use cls when its confidence exceeds detection confidence
                        useClsLabel = cls.confidence > tracked.confidence
                    }

                    if useClsLabel {
                        if let imageNetEmoji = EmojiMapping.emojiForImageNetLabel(cls.label) {
                            finalEmoji = imageNetEmoji
                            finalLabel = cls.label
                        }
                    }
                }

                keptResults.append(DetectionResult(
                    id: tracked.id,
                    label: finalLabel,
                    boundingBox: tracked.boundingBox,
                    confidence: tracked.confidence,
                    emoji: finalEmoji,
                    classificationLabel: clsLabel
                ))
                keptEntries.append((label: finalLabel, box: tracked.boundingBox))
            }
        }

        self.detectionResults = keptResults
        self.isProcessing = !keptResults.isEmpty
    }

    nonisolated private func iou(_ box1: CGRect, _ box2: CGRect) -> CGFloat {
        let intersection = box1.intersection(box2)
        guard intersection.width > 0 && intersection.height > 0 else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let union = box1.width * box1.height + box2.width * box2.height - intersectionArea
        return union > 0 ? intersectionArea / union : 0
    }
}

private struct TrackedObject {
    let id: UUID
    var label: String
    var boundingBox: CGRect
    var confidence: Float
    var emoji: String
    var lastSeen: Date
    var classificationLabel: String?
    var velocity: CGPoint = .zero
    var previousCenter: CGPoint?
}

private struct ClsCacheEntry {
    let label: String
    let confidence: Float
    let timestamp: Date
}
