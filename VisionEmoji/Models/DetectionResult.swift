//
//  DetectionResult.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import Foundation
import CoreGraphics

struct DetectionResult: Identifiable, Equatable {
    let id: UUID
    let type: DetectionType
    let label: String
    let boundingBox: CGRect
    let confidence: Float
    let emoji: String

    init(id: UUID = UUID(), type: DetectionType, label: String = "", boundingBox: CGRect, confidence: Float, emoji: String) {
        self.id = id
        self.type = type
        self.label = label
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.emoji = emoji
    }

    static func == (lhs: DetectionResult, rhs: DetectionResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Detection Types

enum DetectionType: String, CaseIterable {
    case object = "Object"
    case face = "Face"
    case hand = "Hand"
    case body = "Body"

    /// Higher-priority types win when bounding boxes overlap
    var priority: Int {
        switch self {
        case .face: 4
        case .hand: 3
        case .object: 2
        case .body: 1
        }
    }

    var overlayColor: CGColor {
        switch self {
        case .object: CGColor(red: 0, green: 1, blue: 0, alpha: 0.5)
        case .face:   CGColor(red: 0, green: 0.5, blue: 1, alpha: 0.5)
        case .hand:   CGColor(red: 1, green: 0.2, blue: 0.2, alpha: 0.5)
        case .body:   CGColor(red: 1, green: 0.6, blue: 0, alpha: 0.5)
        }
    }
}

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable, Identifiable {
    case emoji = "Emoji"
    case yolo = "YOLO Boxes"
    case debug = "Debug"

    var id: String { rawValue }
}

// MARK: - YOLO Model Selection

enum YOLOModel: String, CaseIterable, Identifiable {
    case yolov3tiny = "YOLOv3 Tiny"
    case yolo11n = "YOLO11 Nano"
    case yolo26n = "YOLO26 Nano"

    var id: String { rawValue }

    var resourceName: String {
        switch self {
        case .yolov3tiny: "YOLOv3TinyFP16"
        case .yolo11n: "yolo11n"
        case .yolo26n: "yolo26n"
        }
    }

    /// YOLO26n is end-to-end (no NMS pipeline) — outputs raw tensor [1, 300, 6]
    var isEndToEnd: Bool {
        switch self {
        case .yolo26n: true
        default: false
        }
    }

    /// Model input resolution
    var inputSize: CGFloat {
        switch self {
        case .yolov3tiny: 416
        case .yolo11n, .yolo26n: 640
        }
    }

    var subtitle: String {
        switch self {
        case .yolov3tiny: "17 MB  •  80 classes  •  Fastest"
        case .yolo11n: "5 MB  •  80 classes  •  NMS pipeline"
        case .yolo26n: "5 MB  •  80 classes  •  End-to-end"
        }
    }
}

// MARK: - Emoji Mapping

struct EmojiMapping {

    /// COCO 80-class labels in index order (0-79) — used for YOLO26n raw tensor decoding
    static let cocoLabels: [String] = [
        "person", "bicycle", "car", "motorcycle", "airplane",
        "bus", "train", "truck", "boat", "traffic light",
        "fire hydrant", "stop sign", "parking meter", "bench", "bird",
        "cat", "dog", "horse", "sheep", "cow",
        "elephant", "bear", "zebra", "giraffe", "backpack",
        "umbrella", "handbag", "tie", "suitcase", "frisbee",
        "skis", "snowboard", "sports ball", "kite", "baseball bat",
        "baseball glove", "skateboard", "surfboard", "tennis racket", "bottle",
        "wine glass", "cup", "fork", "knife", "spoon",
        "bowl", "banana", "apple", "sandwich", "orange",
        "broccoli", "carrot", "hot dog", "pizza", "donut",
        "cake", "chair", "couch", "potted plant", "bed",
        "dining table", "toilet", "tv", "laptop", "mouse",
        "remote", "keyboard", "cell phone", "microwave", "oven",
        "toaster", "sink", "refrigerator", "book", "clock",
        "vase", "scissors", "teddy bear", "hair drier", "toothbrush",
    ]

    /// COCO label → (primary emoji, alternate emoji)
    /// Primary used at high confidence (>=0.7), alternate at lower confidence
    static let cocoLabelToEmojiPair: [String: (primary: String, alternate: String)] = [
        "person": ("🧑", "👤"),
        "bicycle": ("🚲", "🚴"),
        "car": ("🚗", "🚙"),
        "motorcycle": ("🏍️", "🛵"),
        "airplane": ("✈️", "🛩️"),
        "bus": ("🚌", "🚍"),
        "train": ("🚆", "🚂"),
        "truck": ("🚚", "🛻"),
        "boat": ("⛵", "🚤"),
        "traffic light": ("🚦", "🚥"),
        "fire hydrant": ("🧯", "🚒"),
        "stop sign": ("🛑", "⛔"),
        "parking meter": ("🅿️", "🏧"),
        "bench": ("🪑", "💺"),
        "bird": ("🐦", "🐤"),
        "cat": ("🐱", "😺"),
        "dog": ("🐶", "🐕"),
        "horse": ("🐴", "🐎"),
        "sheep": ("🐑", "🐏"),
        "cow": ("🐄", "🐮"),
        "elephant": ("🐘", "🦣"),
        "bear": ("🐻", "🧸"),
        "zebra": ("🦓", "🐴"),
        "giraffe": ("🦒", "🐪"),
        "backpack": ("🎒", "👝"),
        "umbrella": ("☂️", "🌂"),
        "handbag": ("👜", "👛"),
        "tie": ("👔", "🎀"),
        "suitcase": ("🧳", "💼"),
        "frisbee": ("🥏", "💿"),
        "skis": ("⛷️", "🎿"),
        "snowboard": ("🏂", "🛷"),
        "sports ball": ("⚽", "🏐"),
        "kite": ("🪁", "🪂"),
        "baseball bat": ("⚾", "🏏"),
        "baseball glove": ("🧤", "🥊"),
        "skateboard": ("🛹", "🛼"),
        "surfboard": ("🏄", "🏊"),
        "tennis racket": ("🎾", "🏸"),
        "bottle": ("🍾", "🧴"),
        "wine glass": ("🍷", "🥂"),
        "cup": ("☕", "🍵"),
        "fork": ("🍴", "🥢"),
        "knife": ("🔪", "🗡️"),
        "spoon": ("🥄", "🥣"),
        "bowl": ("🥣", "🍜"),
        "banana": ("🍌", "🥝"),
        "apple": ("🍎", "🍏"),
        "sandwich": ("🥪", "🌯"),
        "orange": ("🍊", "🍋"),
        "broccoli": ("🥦", "🥬"),
        "carrot": ("🥕", "🌽"),
        "hot dog": ("🌭", "🥓"),
        "pizza": ("🍕", "🫓"),
        "donut": ("🍩", "🧁"),
        "cake": ("🎂", "🍰"),
        "chair": ("🪑", "💺"),
        "couch": ("🛋️", "🪑"),
        "potted plant": ("🪴", "🌿"),
        "bed": ("🛏️", "🛌"),
        "dining table": ("🍽️", "🪵"),
        "toilet": ("🚽", "🪠"),
        "tv": ("📺", "🖥️"),
        "laptop": ("💻", "🖥️"),
        "mouse": ("🖱️", "🖲️"),
        "remote": ("📱", "🎮"),
        "keyboard": ("⌨️", "🔤"),
        "cell phone": ("📱", "📲"),
        "microwave": ("📦", "🔲"),
        "oven": ("🔥", "♨️"),
        "toaster": ("🍞", "🥐"),
        "sink": ("🚰", "🪣"),
        "refrigerator": ("🧊", "🗄️"),
        "book": ("📖", "📚"),
        "clock": ("🕐", "⏰"),
        "vase": ("🏺", "🫙"),
        "scissors": ("✂️", "🪡"),
        "teddy bear": ("🧸", "🐻"),
        "hair drier": ("💨", "🌬️"),
        "toothbrush": ("🪥", "🦷"),
    ]

    /// Backward-compatible: returns the primary emoji for each label
    static var cocoLabelToEmoji: [String: String] {
        cocoLabelToEmojiPair.mapValues { $0.primary }
    }

    static let highConfidenceThreshold: Float = 0.7

    /// Returns primary emoji at high confidence, alternate at lower confidence
    static func emoji(forLabel label: String, confidence: Float) -> String {
        guard let pair = cocoLabelToEmojiPair[label] else { return "❓" }
        return confidence >= highConfidenceThreshold ? pair.primary : pair.alternate
    }

    /// Look up emoji by COCO class index with confidence-based selection
    static func emoji(forClassIndex index: Int, confidence: Float) -> (label: String, emoji: String)? {
        guard index >= 0 && index < cocoLabels.count else { return nil }
        let label = cocoLabels[index]
        let emoji = emoji(forLabel: label, confidence: confidence)
        return (label, emoji)
    }

    /// Look up emoji by COCO class index (primary only, for backward compat)
    static func emoji(forClassIndex index: Int) -> (label: String, emoji: String)? {
        guard index >= 0 && index < cocoLabels.count else { return nil }
        let label = cocoLabels[index]
        let emoji = cocoLabelToEmojiPair[label]?.primary ?? "❓"
        return (label, emoji)
    }
}
