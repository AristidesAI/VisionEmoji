//
//  DetectionResult.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import Foundation
import CoreGraphics
<<<<<<< HEAD
import AVFoundation

struct DetectionResult: Identifiable, Equatable {
    let id: UUID
    let type: DetectionType
    let label: String
    let boundingBox: CGRect
    let confidence: Float
    let emoji: String
    var classificationLabel: String?

    init(id: UUID = UUID(), type: DetectionType = .object, label: String = "", boundingBox: CGRect, confidence: Float, emoji: String, classificationLabel: String? = nil) {
        self.id = id
        self.type = type
        self.label = label
        self.boundingBox = boundingBox
        self.confidence = confidence
        self.emoji = emoji
        self.classificationLabel = classificationLabel
    }

    static func == (lhs: DetectionResult, rhs: DetectionResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Detection Types

enum DetectionType: String, CaseIterable {
    case object = "Object"

    var priority: Int { 2 }

    var overlayColor: CGColor {
        CGColor(red: 0, green: 1, blue: 0, alpha: 0.5)
    }
}

// MARK: - Display Mode

enum DisplayMode: String, CaseIterable, Identifiable {
    case emoji = "Emoji"
    case debug = "Debug"

    var id: String { rawValue }
}

// MARK: - YOLO Task

enum YOLOTask: String, CaseIterable, Identifiable {
    case detect = "Detection"
    case classify = "Classification"

    var id: String { rawValue }

    var inputSize: CGFloat { self == .classify ? 224 : 640 }

    var resourceName: String {
        switch self {
        case .detect: "yolo26m"
        case .classify: "yolo26m-cls"
=======
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
>>>>>>> parent of b614d2fa (1.0)
        }
    }
}

<<<<<<< HEAD
// MARK: - Camera Descriptor

struct CameraDescriptor: Identifiable, Equatable {
    let id: String
    let deviceType: AVCaptureDevice.DeviceType
    let position: AVCaptureDevice.Position

    var displayName: String {
        switch (position, deviceType) {
        case (.front, _): "Front"
        case (.back, .builtInWideAngleCamera): "Wide"
        case (.back, .builtInUltraWideCamera): "Ultra Wide"
        case (.back, .builtInTelephotoCamera): "Telephoto"
        default: "Camera"
        }
    }

    static func == (lhs: CameraDescriptor, rhs: CameraDescriptor) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Model Key (for caching)

struct ModelKey: Hashable {
    let task: YOLOTask
=======
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
>>>>>>> parent of b614d2fa (1.0)
}

struct EmojiMapping {
<<<<<<< HEAD

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

    static var cocoLabelToEmoji: [String: String] {
        cocoLabelToEmojiPair.mapValues { $0.primary }
    }

    static let highConfidenceThreshold: Float = 0.7

    static func emoji(forLabel label: String, confidence: Float) -> String {
        guard let pair = cocoLabelToEmojiPair[label] else { return "❓" }
        return confidence >= highConfidenceThreshold ? pair.primary : pair.alternate
    }

    static func emoji(forClassIndex index: Int, confidence: Float) -> (label: String, emoji: String)? {
        guard index >= 0 && index < cocoLabels.count else { return nil }
        let label = cocoLabels[index]
        let emoji = emoji(forLabel: label, confidence: confidence)
        return (label, emoji)
    }

    static func emoji(forClassIndex index: Int) -> (label: String, emoji: String)? {
        guard index >= 0 && index < cocoLabels.count else { return nil }
        let label = cocoLabels[index]
        let emoji = cocoLabelToEmojiPair[label]?.primary ?? "❓"
        return (label, emoji)
=======
    static func emojiForType(_ type: DetectionType, confidence: Float) -> EmojiDisplay {
        return EmojiAssetService.shared.getEmojiDisplay(for: type, confidence: confidence)
>>>>>>> parent of b614d2fa (1.0)
    }

    // MARK: - ImageNet Label → Emoji Mapping (for per-object classification)

    /// Heart emojis used as fallback for classes with no emoji relation
    private static let heartEmojis: [String] = [
        "❤️", "🧡", "💛", "💚", "💙", "💜", "🖤", "🩵", "🩷", "🩶", "🤎", "🤍",
    ]

    /// Deterministic heart color based on class name (djb2 hash)
    private static func heartForClass(_ className: String) -> String {
        var hash: UInt64 = 5381
        for char in className.utf8 {
            hash = hash &* 33 &+ UInt64(char)
        }
        return heartEmojis[Int(hash % UInt64(heartEmojis.count))]
    }

    static func emojiForImageNetLabel(_ label: String) -> String? {
        let lower = label.lowercased()

        // Exact match first
        if let emoji = imageNetToEmoji[lower] { return emoji }

        // Partial match — check if any key is contained in the ImageNet label
        for (key, emoji) in imageNetToEmoji {
            if lower.contains(key) { return emoji }
        }

        // Try mapping back to COCO label
        if let cocoLabel = imageNetToCOCOLabel[lower] {
            return cocoLabelToEmojiPair[cocoLabel]?.primary
        }

        // Deterministic heart fallback for truly unmappable classes
        return heartForClass(lower)
    }

    /// Maps ImageNet class identifiers to COCO labels for fallback
    private static let imageNetToCOCOLabel: [String: String] = [
        // Cats
        "tabby": "cat", "tabby cat": "cat", "tiger cat": "cat", "persian cat": "cat",
        "siamese cat": "cat", "egyptian cat": "cat",
        // Dogs (common names)
        "golden retriever": "dog", "labrador retriever": "dog", "german shepherd": "dog",
        "poodle": "dog", "beagle": "dog", "boxer": "dog", "bulldog": "dog",
        "chihuahua": "dog", "dalmatian": "dog", "husky": "dog", "collie": "dog",
        "rottweiler": "dog", "pug": "dog", "corgi": "dog",
        // Vehicles
        "sports car": "car", "minivan": "car", "cab": "car", "convertible": "car",
        "limousine": "car", "jeep": "car", "beach wagon": "car",
        "pickup": "truck", "moving van": "truck", "trailer truck": "truck",
        "fire engine": "truck", "garbage truck": "truck",
        "mountain bike": "bicycle", "bicycle-built-for-two": "bicycle",
        "motor scooter": "motorcycle", "moped": "motorcycle",
        "airliner": "airplane", "warplane": "airplane",
        "speedboat": "boat", "gondola": "boat", "canoe": "boat", "catamaran": "boat",
        "school bus": "bus", "trolleybus": "bus",
        "passenger car": "train", "freight car": "train", "electric locomotive": "train",
        // Animals
        "indian elephant": "elephant", "african elephant": "elephant",
        "brown bear": "bear", "ice bear": "bear", "polar bear": "bear",
        "arabian camel": "horse", "sorrel": "horse",
        "ram": "sheep", "bighorn": "sheep",
        "ox": "cow",
        // Electronics
        "notebook": "laptop", "desktop computer": "laptop",
        "screen": "tv", "monitor": "tv", "television": "tv",
        "cellular telephone": "cell phone", "dial telephone": "cell phone",
        "computer keyboard": "keyboard", "remote control": "remote",
        // Furniture
        "folding chair": "chair", "rocking chair": "chair", "barber chair": "chair",
        "studio couch": "couch", "four-poster": "bed", "cradle": "bed",
        // Food
        "granny smith": "apple", "pineapple": "apple",
        "lemon": "orange", "cheeseburger": "sandwich", "hotdog": "hot dog",
        "pretzel": "donut", "bagel": "donut",
        "ice cream": "cake", "chocolate sauce": "cake",
        "espresso": "cup", "coffee mug": "cup",
        "wine bottle": "bottle", "water bottle": "bottle", "beer bottle": "bottle",
        "red wine": "wine glass", "goblet": "wine glass",
        // Misc
        "purse": "handbag", "bow tie": "tie", "neck brace": "tie",
        "teddy": "teddy bear", "toilet seat": "toilet",
        "washing machine": "sink",
    ]

    /// Complete ImageNet-1K → emoji mapping (all 1000 classes)
    private static let imageNetToEmoji: [String: String] = [
        // ===== FISH & MARINE (classes 0-6, 389-397) =====
        "tench": "🐟", "goldfish": "🐟",
        "great white shark": "🦈", "tiger shark": "🦈", "hammerhead": "🦈",
        "electric ray": "🐟", "stingray": "🐟",
        "barracouta": "🐟", "eel": "🐟", "coho": "🐟",
        "rock beauty": "🐟", "anemonefish": "🐟", "clownfish": "🐟",
        "sturgeon": "🐟", "gar": "🐟", "lionfish": "🐟", "puffer": "🐡",
        "pufferfish": "🐡",

        // ===== BIRDS (classes 7-24, 80-100, 127-146) =====
        "cock": "🐓", "rooster": "🐓", "hen": "🐔", "ostrich": "🐦",
        "brambling": "🐦", "goldfinch": "🐦", "house finch": "🐦",
        "junco": "🐦", "indigo bunting": "🐦", "robin": "🐦",
        "bulbul": "🐦", "jay": "🐦", "magpie": "🐦", "chickadee": "🐦",
        "water ouzel": "🐦", "dipper": "🐦",
        "kite": "🐦", "bald eagle": "🦅", "vulture": "🐦",
        "great grey owl": "🦉",
        "black grouse": "🐦", "ptarmigan": "🐦", "ruffed grouse": "🐦",
        "prairie chicken": "🐦", "peacock": "🦚", "quail": "🐦", "partridge": "🐦",
        "african grey": "🦜", "macaw": "🦜", "cockatoo": "🦜", "sulphur-crested cockatoo": "🦜",
        "lorikeet": "🦜", "coucal": "🐦", "bee eater": "🐦",
        "hornbill": "🐦", "hummingbird": "🐦", "jacamar": "🐦", "toucan": "🦜",
        "drake": "🦆", "red-breasted merganser": "🦆", "goose": "🪿",
        "black swan": "🦢",
        "white stork": "🐦", "black stork": "🐦", "spoonbill": "🐦",
        "flamingo": "🦩", "little blue heron": "🐦", "american egret": "🐦",
        "bittern": "🐦", "crane": "🐦", "limpkin": "🐦",
        "european gallinule": "🐦", "american coot": "🐦", "bustard": "🐦",
        "ruddy turnstone": "🐦", "red-backed sandpiper": "🐦", "dunlin": "🐦",
        "redshank": "🐦", "dowitcher": "🐦", "oystercatcher": "🐦",
        "pelican": "🐦", "king penguin": "🐧", "albatross": "🐦",

        // ===== AMPHIBIANS (classes 25-32) =====
        "fire salamander": "🦎", "spotted salamander": "🦎",
        "smooth newt": "🦎", "newt": "🦎", "axolotl": "🦎",
        "bullfrog": "🐸", "tree frog": "🐸", "tailed frog": "🐸",

        // ===== REPTILES — TURTLES (classes 33-37) =====
        "loggerhead": "🐢", "loggerhead turtle": "🐢", "leatherback turtle": "🐢",
        "mud turtle": "🐢", "terrapin": "🐢", "box turtle": "🐢",

        // ===== REPTILES — LIZARDS (classes 38-48) =====
        "banded gecko": "🦎", "common iguana": "🦎", "iguana": "🦎",
        "american chameleon": "🦎", "whiptail": "🦎", "agama": "🦎",
        "frilled lizard": "🦎", "alligator lizard": "🦎",
        "gila monster": "🦎", "green lizard": "🦎",
        "african chameleon": "🦎", "chameleon": "🦎", "komodo dragon": "🦎",

        // ===== REPTILES — CROCODILIANS (classes 49-50) =====
        "african crocodile": "🐊", "nile crocodile": "🐊",
        "american alligator": "🐊", "alligator": "🐊", "crocodile": "🐊",

        // ===== DINOSAUR (class 51) =====
        "triceratops": "🦕",

        // ===== REPTILES — SNAKES (classes 52-68) =====
        "thunder snake": "🐍", "ringneck snake": "🐍", "hognose snake": "🐍",
        "green snake": "🐍", "king snake": "🐍", "garter snake": "🐍",
        "water snake": "🐍", "vine snake": "🐍", "night snake": "🐍",
        "boa constrictor": "🐍", "rock python": "🐍", "indian cobra": "🐍",
        "green mamba": "🐍", "sea snake": "🐍", "horned viper": "🐍",
        "diamondback": "🐍", "diamondback rattlesnake": "🐍", "sidewinder": "🐍",
        "cobra": "🐍", "python": "🐍", "rattlesnake": "🐍", "snake": "🐍",

        // ===== ARACHNIDS (classes 69-78) =====
        "trilobite": "🪲", "harvestman": "🕷️", "daddy longlegs": "🕷️",
        "scorpion": "🦂",
        "black and gold garden spider": "🕷️", "barn spider": "🕷️",
        "garden spider": "🕷️", "black widow": "🕷️",
        "tarantula": "🕷️", "wolf spider": "🕷️", "spider": "🕷️",
        "tick": "🕷️", "centipede": "🐛",

        // ===== INSECTS — BEETLES (classes 300-307) =====
        "tiger beetle": "🪲", "ladybug": "🐞", "ladybird": "🐞",
        "ground beetle": "🪲", "long-horned beetle": "🪲",
        "leaf beetle": "🪲", "dung beetle": "🪲",
        "rhinoceros beetle": "🪲", "weevil": "🪲",

        // ===== INSECTS — OTHERS (classes 308-326) =====
        "fly": "🪰", "bee": "🐝", "ant": "🐜",
        "grasshopper": "🦗", "cricket": "🦗",
        "walking stick": "🪲", "cockroach": "🪳",
        "mantis": "🪲", "praying mantis": "🪲",
        "cicada": "🪲", "leafhopper": "🪲", "lacewing": "🪲",
        "dragonfly": "🪰", "damselfly": "🪰",
        "admiral": "🦋", "ringlet": "🦋", "monarch": "🦋",
        "cabbage butterfly": "🦋", "sulphur butterfly": "🦋",
        "lycaenid": "🦋", "butterfly": "🦋",

        // ===== MARINE INVERTEBRATES (classes 107-126, 327-329) =====
        "jellyfish": "🪼", "sea anemone": "🪸", "brain coral": "🪸",
        "coral reef": "🪸", "coral": "🪸",
        "flatworm": "🪱", "nematode": "🪱",
        "conch": "🐚", "snail": "🐌", "slug": "🐌",
        "sea slug": "🐌", "nudibranch": "🐌",
        "chiton": "🐚", "chambered nautilus": "🐚", "nautilus": "🐚",
        "dungeness crab": "🦀", "rock crab": "🦀", "fiddler crab": "🦀",
        "king crab": "🦀", "crab": "🦀",
        "american lobster": "🦞", "spiny lobster": "🦞", "lobster": "🦞",
        "crayfish": "🦞", "hermit crab": "🦀", "isopod": "🦐",
        "starfish": "⭐", "sea urchin": "🪸", "sea cucumber": "🪸",

        // ===== MARINE MAMMALS (classes 147-150) =====
        "grey whale": "🐋", "killer whale": "🐋", "whale": "🐋",
        "dugong": "🐋", "sea lion": "🦭",

        // ===== DOGS — ALL BREEDS (classes 151-268) =====
        "chihuahua": "🐕", "japanese spaniel": "🐕", "japanese chin": "🐕",
        "maltese dog": "🐕", "maltese": "🐕",
        "pekinese": "🐕", "pekingese": "🐕",
        "shih-tzu": "🐕", "blenheim spaniel": "🐕",
        "papillon": "🐕", "toy terrier": "🐕",
        "rhodesian ridgeback": "🐕", "afghan hound": "🐕",
        "basset": "🐕", "beagle": "🐕", "bloodhound": "🐕",
        "bluetick": "🐕", "black-and-tan coonhound": "🐕",
        "walker hound": "🐕", "english foxhound": "🐕", "redbone": "🐕",
        "borzoi": "🐕", "irish wolfhound": "🐕",
        "italian greyhound": "🐕", "whippet": "🐕", "greyhound": "🐕",
        "ibizan hound": "🐕", "norwegian elkhound": "🐕",
        "otterhound": "🐕", "saluki": "🐕",
        "scottish deerhound": "🐕", "weimaraner": "🐕",
        "staffordshire bullterrier": "🐕", "american staffordshire terrier": "🐕",
        "bedlington terrier": "🐕", "border terrier": "🐕",
        "kerry blue terrier": "🐕", "irish terrier": "🐕",
        "norfolk terrier": "🐕", "norwich terrier": "🐕",
        "yorkshire terrier": "🐕", "wire-haired fox terrier": "🐕",
        "lakeland terrier": "🐕", "sealyham terrier": "🐕",
        "airedale": "🐕", "cairn": "🐕", "australian terrier": "🐕",
        "dandie dinmont": "🐕", "boston bull": "🐕", "boston terrier": "🐕",
        "miniature schnauzer": "🐕", "giant schnauzer": "🐕",
        "standard schnauzer": "🐕", "scotch terrier": "🐕", "scottish terrier": "🐕",
        "tibetan terrier": "🐕", "silky terrier": "🐕",
        "soft-coated wheaten terrier": "🐕", "west highland white terrier": "🐕",
        "lhasa": "🐕", "lhasa apso": "🐕",
        "flat-coated retriever": "🐕", "curly-coated retriever": "🐕",
        "golden retriever": "🐕", "labrador retriever": "🐕",
        "chesapeake bay retriever": "🐕",
        "german short-haired pointer": "🐕", "vizsla": "🐕",
        "english setter": "🐕", "irish setter": "🐕", "gordon setter": "🐕",
        "brittany spaniel": "🐕", "clumber": "🐕", "clumber spaniel": "🐕",
        "english springer": "🐕", "welsh springer spaniel": "🐕",
        "cocker spaniel": "🐕", "sussex spaniel": "🐕",
        "irish water spaniel": "🐕",
        "kuvasz": "🐕", "schipperke": "🐕",
        "groenendael": "🐕", "malinois": "🐕", "briard": "🐕", "kelpie": "🐕",
        "komondor": "🐕", "old english sheepdog": "🐕",
        "shetland sheepdog": "🐕", "collie": "🐕", "border collie": "🐕",
        "bouvier des flandres": "🐕",
        "rottweiler": "🐕", "german shepherd": "🐕", "doberman": "🐕",
        "miniature pinscher": "🐕",
        "greater swiss mountain dog": "🐕", "bernese mountain dog": "🐕",
        "appenzeller": "🐕", "entlebucher": "🐕",
        "boxer": "🐕", "bull mastiff": "🐕", "tibetan mastiff": "🐕",
        "french bulldog": "🐕", "great dane": "🐕", "saint bernard": "🐕",
        "eskimo dog": "🐕", "malamute": "🐕", "siberian husky": "🐕",
        "dalmatian": "🐕", "affenpinscher": "🐕", "basenji": "🐕",
        "pug": "🐕", "leonberg": "🐕", "leonberger": "🐕",
        "newfoundland": "🐕", "great pyrenees": "🐕", "samoyed": "🐕",
        "pomeranian": "🐕", "chow": "🐕", "keeshond": "🐕",
        "brabancon griffon": "🐕",
        "pembroke": "🐕", "cardigan": "🐕",
        "toy poodle": "🐕", "miniature poodle": "🐕", "standard poodle": "🐕",
        "mexican hairless": "🐕",
        "retriever": "🐕", "terrier": "🐕", "spaniel": "🐕",
        "poodle": "🐕", "schnauzer": "🐕", "sheepdog": "🐕",
        "hound": "🐕", "setter": "🐕", "mastiff": "🐕",

        // ===== WILD CANIDS (classes 269-276) =====
        "timber wolf": "🐺", "white wolf": "🐺", "red wolf": "🐺", "wolf": "🐺",
        "coyote": "🐺", "dingo": "🐕", "dhole": "🐕",
        "african hunting dog": "🐕", "african wild dog": "🐕",
        "hyena": "🐕", "red fox": "🦊", "kit fox": "🦊",
        "arctic fox": "🦊", "grey fox": "🦊", "fox": "🦊",

        // ===== CATS (classes 281-293) =====
        "tabby": "🐈", "tiger cat": "🐈", "persian cat": "🐈",
        "siamese cat": "🐈", "egyptian cat": "🐈",
        "cougar": "🐆", "mountain lion": "🐆", "puma": "🐆",
        "lynx": "🐈", "leopard": "🐆", "snow leopard": "🐆",
        "jaguar": "🐆", "lion": "🦁", "tiger": "🐅", "cheetah": "🐆",

        // ===== BEARS (classes 294-297) =====
        "brown bear": "🐻", "american black bear": "🐻",
        "ice bear": "🐻‍❄️", "polar bear": "🐻‍❄️", "sloth bear": "🐻",
        "bear": "🐻",

        // ===== SMALL MAMMALS (classes 298-299, 330-363) =====
        "mongoose": "🦦", "meerkat": "🦦",
        "wood rabbit": "🐰", "cottontail": "🐰", "hare": "🐰",
        "angora": "🐰", "rabbit": "🐰",
        "hamster": "🐹", "porcupine": "🦔",
        "fox squirrel": "🐿️", "squirrel": "🐿️",
        "marmot": "🐿️", "beaver": "🦫", "guinea pig": "🐹",
        "sorrel": "🐴", "zebra": "🦓",
        "pig": "🐷", "wild boar": "🐗", "warthog": "🐗",
        "hippopotamus": "🦛", "hippo": "🦛",
        "ox": "🐂", "water buffalo": "🐃", "bison": "🦬",
        "ram": "🐏", "bighorn": "🐏", "ibex": "🐐",
        "hartebeest": "🦌", "impala": "🦌", "gazelle": "🦌",
        "arabian camel": "🐫", "llama": "🦙",
        "weasel": "🦦", "mink": "🦦", "polecat": "🦨",
        "black-footed ferret": "🦦", "ferret": "🦦",
        "otter": "🦦", "skunk": "🦨", "badger": "🦡",
        "armadillo": "🦔", "three-toed sloth": "🦥", "sloth": "🦥",

        // ===== PRIMATES (classes 365-384) =====
        "orangutan": "🦧", "gorilla": "🦍", "chimpanzee": "🐵",
        "gibbon": "🐵", "siamang": "🐵",
        "guenon": "🐵", "patas monkey": "🐵", "baboon": "🐵",
        "macaque": "🐵", "langur": "🐵", "colobus": "🐵",
        "proboscis monkey": "🐵", "marmoset": "🐵",
        "capuchin": "🐵", "howler monkey": "🐵", "titi": "🐵",
        "spider monkey": "🐵", "squirrel monkey": "🐵",
        "madagascar cat": "🐵", "ring-tailed lemur": "🐵",
        "indri": "🐵", "lemur": "🐵", "monkey": "🐵",

        // ===== OTHER MAMMALS (classes 101-106, 385-388) =====
        "tusker": "🐘", "echidna": "🦔", "platypus": "🦆",
        "wallaby": "🦘", "koala": "🐨", "wombat": "🐨",
        "indian elephant": "🐘", "african elephant": "🐘", "elephant": "🐘",
        "lesser panda": "🐼", "red panda": "🐼", "giant panda": "🐼", "panda": "🐼",

        // ===== FOOD — PRODUCE (classes 944-954) =====
        "mushroom": "🍄", "granny smith": "🍏",
        "strawberry": "🍓", "orange": "🍊", "lemon": "🍋",
        "fig": "🫐", "pineapple": "🍍", "banana": "🍌",
        "jackfruit": "🍈", "custard apple": "🍈", "pomegranate": "🍎",

        // ===== FOOD — PREPARED (classes 921-943, 955-966) =====
        "guacamole": "🥑", "consomme": "🍲", "hot pot": "🍲",
        "trifle": "🍰", "ice cream": "🍦", "ice lolly": "🍦", "popsicle": "🍦",
        "french loaf": "🥖", "baguette": "🥖", "bagel": "🥯",
        "pretzel": "🥨", "cheeseburger": "🍔", "hotdog": "🌭",
        "mashed potato": "🥔", "head cabbage": "🥬", "broccoli": "🥦",
        "cauliflower": "🥦", "zucchini": "🥒", "courgette": "🥒",
        "spaghetti squash": "🎃", "acorn squash": "🎃", "butternut squash": "🎃",
        "cucumber": "🥒", "artichoke": "🥬", "bell pepper": "🫑",
        "cardoon": "🥬", "hay": "🌾",
        "carbonara": "🍝", "chocolate sauce": "🍫", "dough": "🍞",
        "meat loaf": "🥩", "pizza": "🍕", "potpie": "🥧", "pot pie": "🥧",
        "burrito": "🌯", "red wine": "🍷",
        "espresso": "☕", "cup": "☕", "coffee": "☕", "eggnog": "🥛",

        // ===== NATURE & LANDSCAPES (classes 967-977) =====
        "alp": "🏔️", "bubble": "🫧", "cliff": "🏔️",
        "geyser": "♨️", "lakeside": "🏞️", "lakeshore": "🏞️",
        "promontory": "🏔️", "headland": "🏔️",
        "sandbar": "🏖️", "seashore": "🏖️", "coast": "🏖️",
        "valley": "🏞️", "volcano": "🌋",

        // ===== PLANTS & FUNGI (classes 981-995) =====
        "rapeseed": "🌻", "daisy": "🌼",
        "yellow lady's slipper": "🌺", "orchid": "🌺",
        "corn": "🌽", "acorn": "🌰", "hip": "🌹", "rose hip": "🌹",
        "buckeye": "🌰", "horse chestnut": "🌰",
        "coral fungus": "🍄", "agaric": "🍄", "gyromitra": "🍄",
        "stinkhorn": "🍄", "earthstar": "🍄",
        "hen-of-the-woods": "🍄", "bolete": "🍄",
        "ear": "🌽", "corn ear": "🌽",

        // ===== PEOPLE (classes 978-980) =====
        "ballplayer": "⚾", "groom": "🤵", "scuba diver": "🤿",

        // ===== MISC ITEMS (classes 996, 913-920) =====
        "toilet tissue": "🧻", "toilet paper": "🧻",
        "web site": "🌐", "comic book": "📖",
        "crossword puzzle": "📰", "street sign": "🪧",
        "traffic light": "🚦", "book jacket": "📕", "dust cover": "📕",
        "menu": "📋", "plate": "🍽️",

        // ===== VEHICLES & TRANSPORT =====
        "aircraft carrier": "🚢", "airliner": "✈️", "airship": "🎈",
        "ambulance": "🚑", "amphibian": "🚗",
        "beach wagon": "🚗", "station wagon": "🚗",
        "bobsled": "🛷", "bullet train": "🚄",
        "cab": "🚕", "taxi": "🚕",
        "canoe": "🛶", "car mirror": "🚗", "car wheel": "🚗",
        "catamaran": "⛵", "container ship": "🚢",
        "convertible": "🚗", "dogsled": "🛷",
        "electric locomotive": "🚂",
        "fire engine": "🚒", "fire truck": "🚒",
        "fireboat": "🚢", "forklift": "🚜",
        "freight car": "🚃", "garbage truck": "🚛",
        "go-kart": "🏎️", "golf cart": "🚗", "golfcart": "🚗",
        "gondola": "⛵", "horse cart": "🐴",
        "jeep": "🚙", "jinrikisha": "🛺", "rickshaw": "🛺",
        "lifeboat": "🚤", "limousine": "🚗",
        "liner": "🚢", "ocean liner": "🚢",
        "minibus": "🚐", "minivan": "🚐",
        "mobile home": "🚐", "model t": "🚗",
        "moped": "🛵", "motor scooter": "🛵", "vespa": "🛵",
        "mountain bike": "🚲", "bicycle-built-for-two": "🚲", "tandem": "🚲",
        "moving van": "🚛", "oxcart": "🐂",
        "passenger car": "🚃", "railroad car": "🚃",
        "pickup": "🛻", "pickup truck": "🛻",
        "pirate": "🏴‍☠️", "pirate ship": "⛵",
        "police van": "🚔", "racer": "🏎️", "race car": "🏎️",
        "recreational vehicle": "🚐", "rv": "🚐",
        "school bus": "🚌", "schooner": "⛵",
        "snowmobile": "🛷", "snowplow": "🚜",
        "space shuttle": "🚀", "speedboat": "🚤",
        "sports car": "🏎️", "steam locomotive": "🚂",
        "streetcar": "🚊", "trolley": "🚊",
        "submarine": "🚢", "tank": "🪖",
        "tow truck": "🚛", "tractor": "🚜",
        "trailer truck": "🚛", "tricycle": "🚲",
        "trimaran": "⛵", "trolleybus": "🚌",
        "unicycle": "🚲", "warplane": "✈️", "military aircraft": "✈️",
        "yawl": "⛵",

        // ===== MUSICAL INSTRUMENTS =====
        "accordion": "🪗", "acoustic guitar": "🎸", "electric guitar": "🎸",
        "guitar": "🎸", "banjo": "🪕", "bassoon": "🎵",
        "cello": "🎻", "cornet": "🎺", "drum": "🥁", "drumstick": "🥁",
        "flute": "🪈", "french horn": "📯",
        "gong": "🔔", "grand piano": "🎹", "piano": "🎹",
        "harmonica": "🪗", "harp": "🎵",
        "maraca": "🪇", "marimba": "🎵", "xylophone": "🎵",
        "microphone": "🎤", "oboe": "🎵", "ocarina": "🎵",
        "organ": "🎹", "panpipe": "🎵",
        "sax": "🎷", "saxophone": "🎷",
        "steel drum": "🥁", "trombone": "🎵",
        "trumpet": "🎺", "violin": "🎻",
        "upright": "🎹", "upright piano": "🎹",

        // ===== CLOTHING & ACCESSORIES =====
        "abaya": "👗", "academic gown": "👨‍🎓", "graduation cap": "🎓",
        "apron": "🧑‍🍳", "backpack": "🎒",
        "band aid": "🩹", "bathing cap": "🏊", "bath towel": "🛁",
        "bearskin": "🧢", "bib": "👶",
        "bikini": "👙", "bolo tie": "👔", "bonnet": "👒",
        "brassiere": "👙", "bra": "👙",
        "breastplate": "🛡️", "bulletproof vest": "🦺",
        "chain mail": "⛓️",
        "christmas stocking": "🧦",
        "cloak": "🧥", "clog": "👞", "cowboy boot": "👢",
        "cowboy hat": "🤠", "crash helmet": "⛑️",
        "diaper": "👶", "feather boa": "🪶",
        "football helmet": "🏈", "fur coat": "🧥",
        "gasmask": "😷", "gown": "👗",
        "hair slide": "💇", "hair clip": "💇", "hair spray": "💇",
        "handkerchief": "🤧",
        "holster": "🔫", "hoopskirt": "👗",
        "jean": "👖", "jeans": "👖",
        "jersey": "👕", "t-shirt": "👕", "tee shirt": "👕",
        "kimono": "👘", "knee pad": "🦵",
        "lab coat": "🥼", "lipstick": "💄",
        "loafer": "👞", "maillot": "👙",
        "mask": "🎭", "military uniform": "🪖",
        "miniskirt": "👗", "mitten": "🧤",
        "muzzle": "🐕", "necklace": "📿",
        "overskirt": "👗", "oxygen mask": "😷",
        "pajama": "🛌", "poncho": "🧥",
        "running shoe": "👟", "sandal": "👡",
        "sarong": "👗", "seat belt": "🚗",
        "shower cap": "🚿", "ski mask": "⛷️",
        "sleeping bag": "🛌", "snorkel": "🤿",
        "sock": "🧦", "sombrero": "👒",
        "stole": "🧣", "suit": "🤵",
        "sunglasses": "🕶️", "dark glasses": "🕶️",
        "sunscreen": "🧴", "sweatshirt": "👕",
        "swimming trunks": "🩳", "trench coat": "🧥",
        "vestment": "👗", "wig": "💇",
        "windsor tie": "👔", "wool": "🧶",

        // ===== HOUSEHOLD & FURNITURE =====
        "altar": "⛪", "analog clock": "🕰️",
        "apiary": "🐝", "beehive": "🐝",
        "ashcan": "🗑️", "trash can": "🗑️", "garbage can": "🗑️",
        "balance beam": "🤸", "balloon": "🎈",
        "bannister": "🏠", "handrail": "🏠",
        "barbell": "🏋️", "dumbbell": "🏋️",
        "barber chair": "💈", "barbershop": "💈",
        "barrel": "🛢️", "barrow": "🏗️", "wheelbarrow": "🏗️",
        "bassinet": "👶", "bathtub": "🛁",
        "beaker": "🧪", "binder": "📒",
        "bookcase": "📚", "bookshop": "📚",
        "bottlecap": "🍾", "broom": "🧹",
        "bucket": "🪣", "buckle": "🔗",
        "caldron": "🍲", "cauldron": "🍲",
        "candle": "🕯️", "can opener": "🥫",
        "carousel": "🎠", "carton": "📦",
        "cash machine": "🏧", "atm": "🏧",
        "cassette": "📼", "cassette player": "📼",
        "cd player": "💿",
        "chain": "⛓️", "chest": "📦",
        "chiffonier": "🗄️", "chime": "🔔", "wind chime": "🎐",
        "china cabinet": "🏠",
        "cocktail shaker": "🍸", "coffee maker": "☕",
        "coil": "🔩", "combination lock": "🔒",
        "confectionery": "🍬", "corkscrew": "🍷",
        "crate": "📦", "crib": "👶",
        "crock pot": "🍲", "slow cooker": "🍲",
        "curtain": "🪟", "dam": "🏗️",
        "desk": "🪑", "digital clock": "⏰", "digital watch": "⌚",
        "dining table": "🍽️", "dishrag": "🧽", "dishcloth": "🧽",
        "dishwasher": "🍽️", "dock": "⚓",
        "dome": "🏛️", "doormat": "🏠",
        "entertainment center": "📺",
        "espresso maker": "☕",
        "face powder": "💄",
        "file": "🗄️", "filing cabinet": "🗄️",
        "fire screen": "🔥",
        "flagpole": "🏳️", "folding chair": "🪑",
        "fountain pen": "🖋️",
        "four-poster": "🛏️",
        "frying pan": "🍳", "greenhouse": "🌿",
        "grille": "🚗", "radiator grille": "🚗",
        "grocery store": "🛒", "guillotine": "⚔️",
        "hamper": "🧺", "hand blower": "💨", "hair dryer": "💨",
        "hand-held computer": "📱", "pda": "📱",
        "hard disc": "💾", "harvester": "🚜", "combine": "🚜",
        "hatchet": "🪓", "home theater": "🎬",
        "honeycomb": "🍯", "hook": "🪝",
        "horizontal bar": "🤸",
        "hourglass": "⏳", "ipod": "🎵",
        "iron": "👔",
        "jack-o'-lantern": "🎃",
        "jigsaw puzzle": "🧩",
        "ladle": "🥄", "lampshade": "💡",
        "lawn mower": "🌿", "lens cap": "📷",
        "letter opener": "✉️",
        "lighter": "🔥", "lotion": "🧴",
        "loudspeaker": "🔊", "loupe": "🔍",
        "magnetic compass": "🧭", "compass": "🧭",
        "mailbag": "📬", "mailbox": "📬",
        "manhole cover": "⚙️", "matchstick": "🔥",
        "maypole": "🎪", "maze": "🌀", "labyrinth": "🌀",
        "measuring cup": "🥛", "medicine chest": "💊",
        "megalith": "🗿",
        "microwave": "📦", "milk can": "🥛",
        "missile": "🚀", "mixing bowl": "🥣",
        "modem": "📡", "mortar": "🏗️",
        "mortarboard": "🎓", "mosquito net": "🦟",
        "mountain tent": "⛺",
        "mousetrap": "🪤", "nail": "🔩",
        "odometer": "🚗", "oil filter": "🚗",
        "oscilloscope": "📊",
        "packet": "📦", "paddle": "🏓",
        "paddlewheel": "⚙️", "padlock": "🔒",
        "paintbrush": "🖌️", "paper towel": "🧻",
        "parachute": "🪂", "parallel bars": "🤸",
        "park bench": "🪑", "parking meter": "🅿️",
        "patio": "🏠", "pay-phone": "📞",
        "pedestal": "🏛️", "pencil box": "✏️",
        "pencil sharpener": "✏️", "perfume": "🧴",
        "petri dish": "🧫", "photocopier": "🖨️",
        "pick": "🎸", "plectrum": "🎸", "guitar pick": "🎸",
        "pickelhaube": "⛑️", "picket fence": "🏠",
        "piggy bank": "🐷", "pill bottle": "💊",
        "pillow": "🛏️", "ping-pong ball": "🏓",
        "pinwheel": "🎡", "pitcher": "🫗",
        "plane": "🪚", "carpenter's plane": "🪚",
        "planetarium": "🌌", "plastic bag": "🛍️",
        "plate rack": "🍽️", "plow": "🚜",
        "plunger": "🪠", "polaroid camera": "📸",
        "pole": "🏗️", "pool table": "🎱", "billiard table": "🎱",
        "pop bottle": "🍾", "soda bottle": "🍾",
        "pot": "🍲", "potter's wheel": "🏺",
        "power drill": "🔧", "prayer rug": "🧎",
        "printer": "🖨️", "prison": "🏢", "cell": "🏢",
        "projectile": "🚀", "projector": "📽️",
        "puck": "🏒", "hockey puck": "🏒",
        "punching bag": "🥊",
        "quill": "🪶", "quilt": "🛏️",
        "radio": "📻", "rain barrel": "🪣",
        "radiator": "🔥",
        "reel": "🎣", "reflex camera": "📷",
        "refrigerator": "🧊", "restaurant": "🍽️",
        "revolver": "🔫", "rifle": "🔫",
        "rocking chair": "🪑", "rotisserie": "🍗",
        "rubber eraser": "✏️", "rule": "📏", "ruler": "📏",
        "safe": "🔐", "safety pin": "🧷",
        "saltshaker": "🧂", "scale": "⚖️", "balance": "⚖️",
        "scoreboard": "📊", "screen": "🖥️", "crt": "🖥️",
        "screw": "🔩", "screwdriver": "🪛",
        "sewing machine": "🧵", "shield": "🛡️",
        "shoe shop": "👟", "shoji": "🏠",
        "shopping basket": "🛒", "shopping cart": "🛒",
        "shovel": "⛏️", "shower curtain": "🚿",
        "ski": "⛷️", "slide rule": "📏",
        "sliding door": "🚪", "slot": "🎰", "slot machine": "🎰",
        "soap dispenser": "🧴",
        "solar dish": "☀️",
        "soup bowl": "🍲",
        "space bar": "⌨️", "space heater": "🔥",
        "spatula": "🍳", "spider web": "🕸️",
        "spindle": "🧵",
        "spotlight": "🔦", "stage": "🎭",
        "steel arch bridge": "🌉",
        "stethoscope": "🩺",
        "stone wall": "🧱", "stopwatch": "⏱️",
        "stove": "🔥", "strainer": "🍳",
        "stretcher": "🏥",
        "studio couch": "🛋️", "day bed": "🛋️",
        "stupa": "🛕", "sundial": "☀️",
        "suspension bridge": "🌉",
        "swab": "🧹", "swing": "🛝",
        "switch": "💡", "syringe": "💉",
        "table lamp": "💡", "tape player": "📼",
        "teapot": "🫖", "teddy": "🧸", "teddy bear": "🧸",
        "television": "📺", "thatch": "🏠", "thatched roof": "🏠",
        "theater curtain": "🎭", "thimble": "🧵",
        "thresher": "🚜", "throne": "👑",
        "tile roof": "🏠", "toaster": "🍞",
        "tobacco shop": "🚬",
        "toilet seat": "🚽", "torch": "🔦",
        "totem pole": "🗿", "toyshop": "🧸",
        "tray": "🍽️", "tripod": "📷",
        "triumphal arch": "🏛️", "tub": "🛁",
        "turnstile": "🚪", "typewriter": "⌨️",
        "umbrella": "☂️",
        "vacuum": "🧹", "vase": "🏺",
        "vault": "🏦", "velvet": "🧵",
        "vending machine": "🏧", "viaduct": "🌉",
        "volleyball": "🏐",
        "waffle iron": "🧇", "wall clock": "🕰️",
        "wallet": "👛", "wardrobe": "🗄️",
        "washbasin": "🚰", "washer": "🧺", "washing machine": "🧺",
        "water bottle": "🧴", "water jug": "🫗",
        "water tower": "🏗️", "whiskey jug": "🥃",
        "whistle": "🎵", "window screen": "🪟",
        "window shade": "🪟",
        "wine bottle": "🍷", "wing": "✈️",
        "wok": "🍳", "wooden spoon": "🥄",
        "worm fence": "🏠", "wreck": "🚢",
        "yurt": "⛺",

        // ===== BUILDINGS & PLACES =====
        "bakery": "🍞", "barn": "🏠",
        "beacon": "🗼", "bell cote": "🔔", "bell tower": "🔔",
        "birdhouse": "🐦", "boathouse": "🏠",
        "butcher shop": "🥩", "castle": "🏰",
        "church": "⛪", "cinema": "🎬",
        "cliff dwelling": "🏠",
        "drilling platform": "🏗️", "oil rig": "🏗️",
        "fountain": "⛲",
        "library": "📚", "lighthouse": "🗼",
        "lumbermill": "🪵", "monastery": "🛕",
        "mosque": "🕌", "palace": "🏰",
        "pier": "⚓",

        // ===== SPORTS EQUIPMENT =====
        "baseball": "⚾", "basketball": "🏀",
        "croquet ball": "🏑",
        "golf ball": "⛳",
        "rugby ball": "🏈",
        "soccer ball": "⚽", "tennis ball": "🎾",

        // ===== TOOLS & EQUIPMENT =====
        "abacus": "🧮",
        "assault rifle": "🔫",
        "ballpoint": "🖊️", "barometer": "🌡️",
        "binoculars": "🔭",
        "bow": "🏹",
        "cannon": "💣",
        "carpenter's kit": "🧰", "tool kit": "🧰",
        "chain saw": "🪚", "chainsaw": "🪚",
        "cleaver": "🔪", "meat cleaver": "🔪",
        "computer keyboard": "⌨️",
        "crutch": "🦯", "cuirass": "🛡️",
        "disk brake": "🚗",
        "envelope": "✉️",
        "hammer": "🔨",
        "joystick": "🕹️",
        "key": "🔑", "lock": "🔒",
        "laptop": "💻", "notebook": "💻",
        "desktop computer": "🖥️",
        "cellular telephone": "📱", "cell phone": "📱",
        "dial telephone": "📞",
        "monitor": "🖥️",
        "mouse": "🖱️", "computer mouse": "🖱️",
        "remote control": "📱",
        "pencil": "✏️", "pen": "🖊️",
        "camera": "📷",
        "game controller": "🎮",
        "telescope": "🔭",
        "magnifying glass": "🔍",
        "flashlight": "🔦",
        "wrench": "🔧",
        "scissors": "✂️",

        // ===== DRINKS & CONTAINERS =====
        "beer bottle": "🍺", "beer glass": "🍺",
        "wine glass": "🍷", "goblet": "🍷",

        // ===== ABSTRACT / HARD TO MAP → hearts via fallback =====
        // These are intentionally omitted to fall through to heartForClass()
        // Examples: "chainlink fence", "half track", "knot", "coil",
        // "disk brake", "grille", "manhole cover", "nipple", etc.
    ]
}

enum EmojiDisplay {
    case animated(code: String)
    case staticEmoji(emoji: String)
}
