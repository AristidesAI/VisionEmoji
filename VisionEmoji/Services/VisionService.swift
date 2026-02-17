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

@MainActor
class VisionService: ObservableObject {
    // MARK: - Published Properties
    @Published var detectionResults: [DetectionResult] = []
    @Published var isProcessing = false

    // Model selection — user can switch at runtime
    @Published var selectedModel: YOLOModel = .yolo11n {
        didSet {
            if oldValue != selectedModel {
                clearTrackedObjects()
                ensureModelLoaded(selectedModel)
            }
        }
    }

    // Detection tuning
    @Published var confidenceThreshold: Float = 0.25

    // Detection toggles
    @Published var isFaceDetectionEnabled = true
    @Published var isHandDetectionEnabled = false
    @Published var isBodyDetectionEnabled = false

    // Performance metrics
    @Published var objectProcessingTime: Double = 0
    @Published var faceProcessingTime: Double = 0
    @Published var handProcessingTime: Double = 0
    @Published var bodyProcessingTime: Double = 0
    @Published var fps: Double = 0

    // MARK: - Private Properties

    // Cached VNCoreMLModel instances (lazy-loaded per model)
    nonisolated(unsafe) private var loadedModels: [YOLOModel: VNCoreMLModel] = [:]
    nonisolated(unsafe) private var modelLock = NSLock()

    // Separate queues for parallel processing
    nonisolated(unsafe) private let objectQueue = DispatchQueue(label: "com.visionemoji.object", qos: .userInitiated)
    nonisolated(unsafe) private let faceQueue = DispatchQueue(label: "com.visionemoji.face", qos: .userInitiated)
    nonisolated(unsafe) private let handQueue = DispatchQueue(label: "com.visionemoji.hand", qos: .userInitiated)
    nonisolated(unsafe) private let bodyQueue = DispatchQueue(label: "com.visionemoji.body", qos: .userInitiated)

    // Track objects across frames (protected by trackingLock)
    nonisolated(unsafe) private var trackedObjects: [UUID: TrackedObject] = [:]
    nonisolated(unsafe) private var trackingLock = NSLock()

    private let maxTrackedObjects = 50
    nonisolated(unsafe) private let objectLifetime: TimeInterval = 1.5

    // Frame throttling
    private var frameCounter = 0
    private let processEveryNthFrame = 1

    // FPS tracking
    private var fpsFrameCount = 0
    private var fpsLastTimestamp: CFAbsoluteTime = 0

    // MARK: - Init

    init() {
        ensureModelLoaded(selectedModel)
    }

    // MARK: - Model Loading

    private func ensureModelLoaded(_ model: YOLOModel) {
        objectQueue.async { [weak self] in
            self?.getOrLoadModel(model)
        }
    }

    @discardableResult
    nonisolated private func getOrLoadModel(_ model: YOLOModel) -> VNCoreMLModel? {
        modelLock.lock()
        if let cached = loadedModels[model] {
            modelLock.unlock()
            return cached
        }
        modelLock.unlock()

        // Load model (first-time only — Xcode pre-compiles .mlpackage/.mlmodel to .mlmodelc)
        guard let modelURL = Bundle.main.url(forResource: model.resourceName, withExtension: "mlmodelc") else {
            print("[\(model.rawValue)] Model not found in bundle")
            return nil
        }

        do {
            let config = MLModelConfiguration()
            config.computeUnits = .all

            let mlModel = try MLModel(contentsOf: modelURL, configuration: config)
            let vnModel = try VNCoreMLModel(for: mlModel)

            modelLock.lock()
            loadedModels[model] = vnModel
            modelLock.unlock()

            print("[\(model.rawValue)] Loaded successfully")
            return vnModel
        } catch {
            print("[\(model.rawValue)] Load failed: \(error)")
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
        frameCounter += 1
        guard frameCounter % processEveryNthFrame == 0 else { return }

        // Capture settings on main actor before dispatching to background
        let currentModel = selectedModel
        let currentThreshold = confidenceThreshold

        updateFPS()
        cleanupOldObjects()

        let group = DispatchGroup()

        // Object detection (YOLO model)
        group.enter()
        objectQueue.async { [weak self] in
            self?.performObjectDetection(on: pixelBuffer, model: currentModel, threshold: currentThreshold)
            group.leave()
        }

        if isFaceDetectionEnabled {
            group.enter()
            faceQueue.async { [weak self] in
                self?.performFaceDetection(on: pixelBuffer)
                group.leave()
            }
        }

        if isHandDetectionEnabled {
            group.enter()
            handQueue.async { [weak self] in
                self?.performHandDetection(on: pixelBuffer)
                group.leave()
            }
        }

        if isBodyDetectionEnabled {
            group.enter()
            bodyQueue.async { [weak self] in
                self?.performBodyDetection(on: pixelBuffer)
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.resolveOverlapsAndPublish()
        }
    }

    func updateCameraPosition(isFront: Bool) {
        _ = isFront
    }

    // MARK: - FPS Tracking

    private func updateFPS() {
        let now = CFAbsoluteTimeGetCurrent()
        fpsFrameCount += 1

        let elapsed = now - fpsLastTimestamp
        if elapsed >= 1.0 {
            fps = Double(fpsFrameCount) / elapsed
            fpsFrameCount = 0
            fpsLastTimestamp = now
        }
    }

    // MARK: - Object Detection (YOLO models)

    nonisolated private func performObjectDetection(on pixelBuffer: CVPixelBuffer, model: YOLOModel, threshold: Float) {
        guard let vnModel = getOrLoadModel(model) else { return }

        let startTime = CFAbsoluteTimeGetCurrent()

        let request = VNCoreMLRequest(model: vnModel) { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                print("Object detection error: \(error)")
                return
            }

            if model.isEndToEnd {
                // YOLO26n: raw tensor output [1, 300, 6]
                self.handleEndToEndResults(request: request, threshold: threshold, modelInputSize: model.inputSize)
            } else {
                // YOLOv3Tiny / YOLO11n: NMS pipeline → VNRecognizedObjectObservation
                self.handlePipelineResults(request: request, threshold: threshold)
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            DispatchQueue.main.async { self.objectProcessingTime = elapsed * 1000 }
        }

        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do { try handler.perform([request]) }
        catch { print("Object detection failed: \(error)") }
    }

    /// Handle NMS pipeline models (YOLOv3Tiny, YOLO11n) — returns VNRecognizedObjectObservation
    nonisolated private func handlePipelineResults(request: VNRequest, threshold: Float) {
        guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }

        for observation in observations.prefix(50) {
            guard observation.confidence > threshold else { continue }
            guard let topLabel = observation.labels.first else { continue }

            let label = topLabel.identifier.lowercased()
            if label == "person" { continue }

            let emoji = EmojiMapping.emoji(forLabel: label, confidence: observation.confidence)
            addOrUpdateTrackedObject(
                type: .object, label: label, emoji: emoji,
                boundingBox: observation.boundingBox,
                confidence: observation.confidence
            )
        }
    }

    /// Handle end-to-end models (YOLO26n) — returns raw MLMultiArray [1, 300, 6]
    nonisolated private func handleEndToEndResults(request: VNRequest, threshold: Float, modelInputSize: CGFloat) {
        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let multiArray = results.first?.featureValue.multiArrayValue else { return }

        let shape = multiArray.shape.map { $0.intValue }
        guard shape.count == 3, shape[2] == 6 else {
            print("Unexpected YOLO26 output shape: \(shape)")
            return
        }

        let strides = multiArray.strides.map { $0.intValue }
        let pointer = multiArray.dataPointer.assumingMemoryBound(to: Float.self)

        let numDetections = shape[1] // 300
        let detStride = strides[1]
        let fieldStride = strides[2]

        for i in 0..<numDetections {
            let base = i * detStride
            let conf = pointer[base + 4 * fieldStride]
            guard conf > threshold else { continue }

            // Pixel coords relative to model input size (640x640)
            let x1 = CGFloat(pointer[base])
            let y1 = CGFloat(pointer[base + fieldStride])
            let x2 = CGFloat(pointer[base + 2 * fieldStride])
            let y2 = CGFloat(pointer[base + 3 * fieldStride])
            let classIndex = Int(pointer[base + 5 * fieldStride])

            // Normalize to Vision coordinate space [0,1] — y-flipped (bottom-left origin)
            let normalizedBox = CGRect(
                x: x1 / modelInputSize,
                y: 1.0 - (y2 / modelInputSize),
                width: (x2 - x1) / modelInputSize,
                height: (y2 - y1) / modelInputSize
            )

            guard let mapping = EmojiMapping.emoji(forClassIndex: classIndex, confidence: conf) else { continue }
            if mapping.label == "person" { continue }

            addOrUpdateTrackedObject(
                type: .object, label: mapping.label, emoji: mapping.emoji,
                boundingBox: normalizedBox,
                confidence: conf
            )
        }
    }

    // MARK: - Shared Tracking

    nonisolated private func addOrUpdateTrackedObject(
        type: DetectionType, label: String, emoji: String,
        boundingBox: CGRect, confidence: Float
    ) {
        trackingLock.lock()
        defer { trackingLock.unlock() }

        let existingObject = trackedObjects.values.first { tracked in
            tracked.type == type && iou(tracked.boundingBox, boundingBox) > 0.3
        }

        if let existing = existingObject {
            trackedObjects[existing.id]?.boundingBox = boundingBox
            trackedObjects[existing.id]?.confidence = confidence
            trackedObjects[existing.id]?.lastSeen = Date()
            trackedObjects[existing.id]?.emoji = emoji
            trackedObjects[existing.id]?.label = label
        } else if trackedObjects.count < maxTrackedObjects {
            let id = UUID()
            trackedObjects[id] = TrackedObject(
                id: id, type: type, label: label,
                boundingBox: boundingBox,
                confidence: confidence,
                emoji: emoji, lastSeen: Date()
            )
        }
    }

    // MARK: - Face Detection

    nonisolated private func performFaceDetection(on pixelBuffer: CVPixelBuffer) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request = VNDetectFaceRectanglesRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                print("Face detection error: \(error)")
                return
            }

            guard let observations = request.results as? [VNFaceObservation] else { return }

            for observation in observations.prefix(10) {
                guard observation.confidence > 0.5 else { continue }
                self.addOrUpdateTrackedObject(
                    type: .face, label: "face", emoji: "😄",
                    boundingBox: observation.boundingBox,
                    confidence: observation.confidence
                )
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            DispatchQueue.main.async { self.faceProcessingTime = elapsed * 1000 }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do { try handler.perform([request]) }
        catch { print("Face detection failed: \(error)") }
    }

    // MARK: - Hand Detection

    nonisolated private func performHandDetection(on pixelBuffer: CVPixelBuffer) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request = VNDetectHumanHandPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                print("Hand detection error: \(error)")
                return
            }

            guard let observations = request.results as? [VNHumanHandPoseObservation] else { return }

            for observation in observations.prefix(4) {
                guard observation.confidence > 0.5 else { continue }
                guard let allPoints = try? observation.recognizedPoints(.all) else { continue }

                var minX: CGFloat = 1.0, minY: CGFloat = 1.0
                var maxX: CGFloat = 0.0, maxY: CGFloat = 0.0

                for (_, point) in allPoints where point.confidence > 0.3 {
                    minX = min(minX, point.location.x)
                    minY = min(minY, point.location.y)
                    maxX = max(maxX, point.location.x)
                    maxY = max(maxY, point.location.y)
                }

                guard maxX > minX && maxY > minY else { continue }

                let boundingBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                self.addOrUpdateTrackedObject(
                    type: .hand, label: "hand", emoji: "👋",
                    boundingBox: boundingBox,
                    confidence: observation.confidence
                )
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            DispatchQueue.main.async { self.handProcessingTime = elapsed * 1000 }
        }

        request.maximumHandCount = 4

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do { try handler.perform([request]) }
        catch { print("Hand detection failed: \(error)") }
    }

    // MARK: - Body Detection

    nonisolated private func performBodyDetection(on pixelBuffer: CVPixelBuffer) {
        let startTime = CFAbsoluteTimeGetCurrent()

        let request = VNDetectHumanBodyPoseRequest { [weak self] request, error in
            guard let self = self else { return }
            if let error = error {
                print("Body detection error: \(error)")
                return
            }

            guard let observations = request.results as? [VNHumanBodyPoseObservation] else { return }

            for observation in observations.prefix(4) {
                guard observation.confidence > 0.5 else { continue }
                guard let allPoints = try? observation.recognizedPoints(.all) else { continue }

                var minX: CGFloat = 1.0, minY: CGFloat = 1.0
                var maxX: CGFloat = 0.0, maxY: CGFloat = 0.0

                for (_, point) in allPoints where point.confidence > 0.3 {
                    minX = min(minX, point.location.x)
                    minY = min(minY, point.location.y)
                    maxX = max(maxX, point.location.x)
                    maxY = max(maxY, point.location.y)
                }

                guard maxX > minX && maxY > minY else { continue }

                let boundingBox = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
                self.addOrUpdateTrackedObject(
                    type: .body, label: "body", emoji: "🧍",
                    boundingBox: boundingBox,
                    confidence: observation.confidence
                )
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - startTime
            DispatchQueue.main.async { self.bodyProcessingTime = elapsed * 1000 }
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do { try handler.perform([request]) }
        catch { print("Body detection failed: \(error)") }
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

    private func resolveOverlapsAndPublish() {
        trackingLock.lock()
        let allTracked = Array(trackedObjects.values)
        trackingLock.unlock()

        // Sort by priority: face > hand > object > body
        let sorted = allTracked.sorted { $0.type.priority > $1.type.priority }

        var keptResults: [DetectionResult] = []
        var keptBoxes: [CGRect] = []

        for tracked in sorted {
            guard keptResults.count < maxTrackedObjects else { break }

            let overlaps = keptBoxes.contains { box in
                iou(tracked.boundingBox, box) > 0.4
            }

            if !overlaps {
                keptResults.append(DetectionResult(
                    id: tracked.id,
                    type: tracked.type,
                    label: tracked.label,
                    boundingBox: tracked.boundingBox,
                    confidence: tracked.confidence,
                    emoji: tracked.emoji
                ))
                keptBoxes.append(tracked.boundingBox)
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
    let type: DetectionType
    var label: String
    var boundingBox: CGRect
    var confidence: Float
    var emoji: String
    var lastSeen: Date
}
