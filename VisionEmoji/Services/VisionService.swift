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
        
        DispatchQueue.main.async { [weak self] in
            self?.addDetectionResults(newResults)
        }
    }
    
    // MARK: - Hand Gesture Detection
    private func handleHandGestureDetection(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNRecognizedObjectObservation] else { return }
        
        let newResults = observations.compactMap { observation -> DetectionResult in
            let confidence = observation.confidence
            let boundingBox = observation.boundingBox
            let emojiDisplay = EmojiMapping.emojiForType(.handGesture, confidence: confidence)
            
            return DetectionResult(
                type: .handGesture,
                boundingBox: boundingBox,
                confidence: confidence,
                emojiDisplay: emojiDisplay,
                timestamp: Date()
            )
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.addDetectionResults(newResults)
        }
    }
    
    // MARK: - Object Classification
    private func handleObjectClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation] else { return }
        
        let newResults = observations.compactMap { observation -> DetectionResult? in
            let confidence = observation.confidence
            let identifier = observation.identifier.lowercased()
            
            // Map classification to our detection types with comprehensive keyword matching
            let detectionType: DetectionType?
            
            // Buildings and architecture
            if identifier.contains("building") || identifier.contains("house") || identifier.contains("architecture") || 
               identifier.contains("tower") || identifier.contains("bridge") || identifier.contains("church") ||
               identifier.contains("temple") || identifier.contains("mosque") || identifier.contains("castle") {
                detectionType = .building
            }
            // Cars and vehicles
            else if identifier.contains("car") || identifier.contains("vehicle") || identifier.contains("automobile") ||
                    identifier.contains("truck") || identifier.contains("bus") || identifier.contains("motorcycle") ||
                    identifier.contains("bicycle") || identifier.contains("train") || identifier.contains("boat") ||
                    identifier.contains("ship") || identifier.contains("airplane") || identifier.contains("helicopter") {
                detectionType = .vehicle
            }
            // Flowers and plants
            else if identifier.contains("flower") || identifier.contains("plant") || identifier.contains("rose") || 
                    identifier.contains("tulip") || identifier.contains("tree") || identifier.contains("grass") ||
                    identifier.contains("leaf") || identifier.contains("garden") || identifier.contains("botanical") {
                detectionType = .flower
            }
            // Animals and pets
            else if identifier.contains("dog") || identifier.contains("cat") || identifier.contains("animal") || 
                    identifier.contains("pet") || identifier.contains("bear") || identifier.contains("rabbit") ||
                    identifier.contains("bird") || identifier.contains("fish") || identifier.contains("insect") ||
                    identifier.contains("reptile") || identifier.contains("horse") || identifier.contains("cow") ||
                    identifier.contains("pig") || identifier.contains("sheep") || identifier.contains("lion") ||
                    identifier.contains("tiger") || identifier.contains("elephant") || identifier.contains("monkey") {
                detectionType = .animal
            }
            // Food items
            else if identifier.contains("food") || identifier.contains("meal") || identifier.contains("dish") ||
                    identifier.contains("burger") || identifier.contains("pizza") || identifier.contains("sandwich") ||
                    identifier.contains("pasta") || identifier.contains("rice") || identifier.contains("bread") ||
                    identifier.contains("cheese") || identifier.contains("meat") || identifier.contains("chicken") ||
                    identifier.contains("fish") || identifier.contains("soup") || identifier.contains("salad") ||
                    identifier.contains("dessert") || identifier.contains("cake") || identifier.contains("cookie") {
                detectionType = .food
            }
            // Fruits
            else if identifier.contains("fruit") || identifier.contains("apple") || identifier.contains("banana") ||
                    identifier.contains("orange") || identifier.contains("grape") || identifier.contains("strawberry") ||
                    identifier.contains("watermelon") || identifier.contains("lemon") || identifier.contains("cherry") ||
                    identifier.contains("peach") || identifier.contains("pear") || identifier.contains("mango") ||
                    identifier.contains("pineapple") || identifier.contains("kiwi") || identifier.contains("coconut") {
                detectionType = .fruit
            }
            // Sports and recreation
            else if identifier.contains("sport") || identifier.contains("ball") || identifier.contains("game") ||
                    identifier.contains("soccer") || identifier.contains("basketball") || identifier.contains("tennis") ||
                    identifier.contains("golf") || identifier.contains("football") || identifier.contains("baseball") ||
                    identifier.contains("swimming") || identifier.contains("running") || identifier.contains("cycling") ||
                    identifier.contains("skiing") || identifier.contains("surfing") || identifier.contains("boxing") {
                detectionType = .sport
            }
            // Music and audio
            else if identifier.contains("music") || identifier.contains("instrument") || identifier.contains("guitar") ||
                    identifier.contains("piano") || identifier.contains("drum") || identifier.contains("violin") ||
                    identifier.contains("trumpet") || identifier.contains("saxophone") || identifier.contains("microphone") ||
                    identifier.contains("speaker") || identifier.contains("headphone") || identifier.contains("radio") {
                detectionType = .music
            }
            // Technology and electronics
            else if identifier.contains("computer") || identifier.contains("phone") || identifier.contains("tablet") ||
                    identifier.contains("laptop") || identifier.contains("screen") || identifier.contains("monitor") ||
                    identifier.contains("keyboard") || identifier.contains("mouse") || identifier.contains("camera") ||
                    identifier.contains("television") || identifier.contains("printer") || identifier.contains("scanner") ||
                    identifier.contains("router") || identifier.contains("modem") || identifier.contains("cable") {
                detectionType = .technology
            }
            // Clothing and accessories
            else if identifier.contains("clothing") || identifier.contains("shirt") || identifier.contains("pants") ||
                    identifier.contains("dress") || identifier.contains("jacket") || identifier.contains("coat") ||
                    identifier.contains("shoes") || identifier.contains("hat") || identifier.contains("glasses") ||
                    identifier.contains("watch") || identifier.contains("jewelry") || identifier.contains("bag") ||
                    identifier.contains("purse") || identifier.contains("backpack") || identifier.contains("umbrella") {
                detectionType = .clothing
            }
            // Nature and weather
            else if identifier.contains("nature") || identifier.contains("sky") || identifier.contains("cloud") ||
                    identifier.contains("sun") || identifier.contains("moon") || identifier.contains("star") ||
                    identifier.contains("mountain") || identifier.contains("beach") || identifier.contains("ocean") ||
                    identifier.contains("river") || identifier.contains("lake") || identifier.contains("forest") ||
                    identifier.contains("desert") || identifier.contains("snow") || identifier.contains("rain") ||
                    identifier.contains("storm") || identifier.contains("rainbow") || identifier.contains("lightning") {
                detectionType = .nature
            }
            // Tools and equipment
            else if identifier.contains("tool") || identifier.contains("hammer") || identifier.contains("screwdriver") ||
                    identifier.contains("wrench") || identifier.contains("drill") || identifier.contains("saw") ||
                    identifier.contains("knife") || identifier.contains("scissors") || identifier.contains("ruler") ||
                    identifier.contains("ladder") || identifier.contains("shovel") || identifier.contains("axe") ||
                    identifier.contains("pliers") || identifier.contains("tape") || identifier.contains("glue") {
                detectionType = .tool
            }
            // Generic object fallback
            else if confidence > 0.3 {
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
        
        DispatchQueue.main.async { [weak self] in
            self?.addDetectionResults(newResults)
            // Keep only recent results (last 2 seconds)
            let cutoffTime = Date().addingTimeInterval(-2.0)
            self?.detectionResults.removeAll { $0.timestamp < cutoffTime }
        }
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
