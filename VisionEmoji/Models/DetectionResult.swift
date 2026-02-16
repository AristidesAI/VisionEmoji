//
//  DetectionResult.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import Foundation
import CoreGraphics
import Vision

enum DetectionType: String, CaseIterable {
    case face
    case handGesture
    case building
    case car
    case object
    case flower
    case animal
    case food
    case fruit
    case vehicle
    case sport
    case music
    case technology
    case clothing
    case nature
    case tool
    
    var displayName: String {
        switch self {
        case .face: return "Face"
        case .handGesture: return "Hand Gesture"
        case .building: return "Building"
        case .car: return "Car"
        case .object: return "Object"
        case .flower: return "Flower"
        case .animal: return "Animal"
        case .food: return "Food"
        case .fruit: return "Fruit"
        case .vehicle: return "Vehicle"
        case .sport: return "Sport"
        case .music: return "Music"
        case .technology: return "Technology"
        case .clothing: return "Clothing"
        case .nature: return "Nature"
        case .tool: return "Tool"
        }
    }
}

struct DetectionResult: Identifiable, Equatable {
    let id = UUID()
    let type: DetectionType
    let boundingBox: CGRect
    let confidence: Float
    let emojiDisplay: EmojiDisplay
    let timestamp: Date
    
    static func == (lhs: DetectionResult, rhs: DetectionResult) -> Bool {
        return lhs.id == rhs.id
    }
}

struct EmojiMapping {
    static func emojiForType(_ type: DetectionType, confidence: Float) -> EmojiDisplay {
        return EmojiAssetService.shared.getEmojiDisplay(for: type, confidence: confidence)
    }
}

enum EmojiDisplay {
    case animated(code: String)
    case staticEmoji(emoji: String)
}
