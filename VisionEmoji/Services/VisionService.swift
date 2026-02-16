//
//  VisionService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import Foundation
import Vision
import CoreImage
import Combine
import UIKit

class VisionService: ObservableObject {
    @Published var detectionResults: [DetectionResult] = []
    @Published var isProcessing = false
    
    private var frameProcessingQueue = DispatchQueue(label: "vision.frame.processing", qos: .userInitiated)
    private var lastProcessingTime: CFTimeInterval = 0
    private let processingInterval: CFTimeInterval = 1.0 / 30.0 // 30 FPS
    
    // Vision requests
    private lazy var faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
        self?.handleFaceDetection(request: request, error: error)
    }
    
    private lazy var handGestureRequest = VNDetectHumanHandPoseRequest { [weak self] request, error in
        self?.handleHandGestureDetection(request: request, error: error)
    }
    
    private lazy var objectClassificationRequest = VNClassifyImageRequest { [weak self] request, error in
        self?.handleObjectClassification(request: request, error: error)
    }
    
    // Detection settings
    var isFaceDetectionEnabled = true
    var isHandGestureDetectionEnabled = true
    var isBuildingDetectionEnabled = true
    var isCarDetectionEnabled = true
    var isObjectDetectionEnabled = true
    var isFlowerDetectionEnabled = true
    var isAnimalDetectionEnabled = true
    
    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        let currentTime = CACurrentMediaTime()
        
        // Throttle processing to maintain performance
        guard currentTime - lastProcessingTime >= processingInterval else { return }
        lastProcessingTime = currentTime
        
        guard !isProcessing else { return }
        
        isProcessing = true
        
        frameProcessingQueue.async { [weak self] in
            self?.performVisionRequests(pixelBuffer)
        }
    }
    
    private func performVisionRequests(_ pixelBuffer: CVPixelBuffer) {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        var requests: [VNRequest] = []
        
        if isFaceDetectionEnabled {
            requests.append(faceDetectionRequest)
        }
        
        if isHandGestureDetectionEnabled {
            requests.append(handGestureRequest)
        }
        
        if isBuildingDetectionEnabled || isCarDetectionEnabled || isObjectDetectionEnabled {
            requests.append(objectClassificationRequest)
        }
        
        do {
            try handler.perform(requests)
        } catch {
            print("Vision request failed: \(error)")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.isProcessing = false
        }
    }
    
    // MARK: - Face Detection
    private func handleFaceDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNFaceObservation] else { return }
        
        let newResults = observations.compactMap { observation -> DetectionResult in
            let confidence = observation.confidence
            let boundingBox = observation.boundingBox
            let emojiDisplay = EmojiMapping.emojiForType(.face, confidence: confidence)
            
            return DetectionResult(
                type: .face,
                boundingBox: boundingBox,
                confidence: confidence,
                emojiDisplay: emojiDisplay,
                timestamp: Date()
            )
        }
        
        addDetectionResults(newResults)
    }
    
    // MARK: - Hand Gesture Detection
    private func handleHandGestureDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNHumanHandPoseObservation] else { return }
        
        let newResults = observations.compactMap { observation -> DetectionResult? in
            let confidence = observation.confidence
            guard confidence > 0.3 else { return nil }
            
            // Get bounding box for the whole hand if possible, or use a default
            // VNHumanHandPoseObservation doesn't have a direct bounding box, we'd need to calculate from landmarks
            // For now, let's use a simplified approach or a default centered point
            let boundingBox = CGRect(x: 0.4, y: 0.4, width: 0.2, height: 0.2)
            let emojiDisplay = EmojiMapping.emojiForType(.handGesture, confidence: confidence)
            
            return DetectionResult(
                type: .handGesture,
                boundingBox: boundingBox,
                confidence: confidence,
                emojiDisplay: emojiDisplay,
                timestamp: Date()
            )
        }
        
        addDetectionResults(newResults)
    }
    
    // MARK: - Object Classification

    private static let keywordMapping: [DetectionType: [String]] = [
        .building: ["building", "house", "architecture", "tower", "bridge", "church", "temple", "mosque", "castle"],
        .vehicle: ["car", "vehicle", "automobile", "truck", "bus", "motorcycle", "bicycle", "train", "boat", "ship", "airplane", "helicopter"],
        .flower: ["flower", "plant", "rose", "tulip", "tree", "grass", "leaf", "garden", "botanical"],
        .animal: ["dog", "cat", "animal", "pet", "bear", "rabbit", "bird", "fish", "insect", "reptile", "horse", "cow", "pig", "sheep", "lion", "tiger", "elephant", "monkey"],
        .food: ["food", "meal", "dish", "burger", "pizza", "sandwich", "pasta", "rice", "bread", "cheese", "meat", "chicken", "fish", "soup", "salad", "dessert", "cake", "cookie"],
        .fruit: ["fruit", "apple", "banana", "orange", "grape", "strawberry", "watermelon", "lemon", "cherry", "peach", "pear", "mango", "pineapple", "kiwi", "coconut"],
        .sport: ["sport", "ball", "game", "soccer", "basketball", "tennis", "golf", "football", "baseball", "swimming", "running", "cycling", "skiing", "surfing", "boxing"],
        .music: ["music", "instrument", "guitar", "piano", "drum", "violin", "trumpet", "saxophone", "microphone", "speaker", "headphone", "radio"],
        .technology: ["computer", "phone", "tablet", "laptop", "screen", "monitor", "keyboard", "mouse", "camera", "television", "printer", "scanner", "router", "modem", "cable"],
        .clothing: ["clothing", "shirt", "pants", "dress", "jacket", "coat", "shoes", "hat", "glasses", "watch", "jewelry", "bag", "purse", "backpack", "umbrella"],
        .nature: ["nature", "sky", "cloud", "sun", "moon", "star", "mountain", "beach", "ocean", "river", "lake", "forest", "desert", "snow", "rain", "storm", "rainbow", "lightning"],
        .tool: ["tool", "hammer", "screwdriver", "wrench", "drill", "saw", "knife", "scissors", "ruler", "ladder", "shovel", "axe", "pliers", "tape", "glue"]
    ]

    private func detectionType(for identifier: String) -> DetectionType? {
        for (type, keywords) in VisionService.keywordMapping {
            for keyword in keywords {
                if identifier.contains(keyword) {
                    return type
                }
            }
        }
        return nil
    }

    private func handleObjectClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation] else { return }
        
        let newResults = observations.compactMap { observation -> DetectionResult? in
            let confidence = observation.confidence
            let identifier = observation.identifier.lowercased()
            
            let detectionType: DetectionType?
            
            if let mappedType = self.detectionType(for: identifier) {
                detectionType = mappedType
            } else if confidence > 0.3 {
                detectionType = .object
            } else {
                return nil
            }
            
            // Use a default bounding box for object classifications
            let boundingBox = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
            let emojiDisplay = EmojiMapping.emojiForType(detectionType!, confidence: confidence)
            
            return DetectionResult(
                type: detectionType!,
                boundingBox: boundingBox,
                confidence: confidence,
                emojiDisplay: emojiDisplay,
                timestamp: Date()
            )
        }
        
        addDetectionResults(newResults)
    }
    
    private func addDetectionResults(_ results: [DetectionResult]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Add new results
            self.detectionResults.append(contentsOf: results)
            
            // Keep only recent results (last 2 seconds)
            let cutoffTime = Date().addingTimeInterval(-2.0)
            self.detectionResults.removeAll { $0.timestamp < cutoffTime }
        }
    }
    
    private func updateDetectionResults(_ results: [DetectionResult], for type: DetectionType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Remove old results of this type
            self.detectionResults.removeAll { $0.type == type }
            
            // Add new results
            self.detectionResults.append(contentsOf: results)
            
            // Keep only recent results (last 2 seconds)
            let cutoffTime = Date().addingTimeInterval(-2.0)
            self.detectionResults.removeAll { $0.timestamp < cutoffTime }
        }
    }
    
    func clearAllResults() {
        DispatchQueue.main.async { [weak self] in
            self?.detectionResults.removeAll()
        }
    }
}
