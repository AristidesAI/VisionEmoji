//
//  EmojiAssetService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import Foundation
import SwiftUI
import Combine
import ImageIO

class EmojiAssetService: ObservableObject {
    static let shared = EmojiAssetService()
    
    // Comprehensive emoji codes for VisionEmoji app - covering all categories
    private let faceEmojiCodes = ["1f600", "1f603", "1f604", "1f60a", "1f60d", "1f60e", "1f618", "1f642", "1f601", "1f62d", "1f609", "1f617", "1f61a", "1f970", "1f929", "1f973"]
    private let handGestureEmojiCodes = ["1f44b", "1f44d", "1f44f", "270a", "270c", "1f91d", "1f64f", "270b", "1f44e", "270d", "1f448", "1f449", "1f446", "1f447", "1f595", "1f596"]
    private let buildingEmojiCodes = ["1f3e0", "1f3e2", "1f3fc", "1fd9", "1f3e1", "1f3ed", "1f3ec", "1f3db", "1f3ef", "1f3f0", "26ea", "1f54c", "1f54d", "1f54b"]
    private let carEmojiCodes = ["1f697", "1f695", "1f699", "1f68c", "1f68e", "1f693", "1f691", "1f692", "1f690", "1f694", "1f698", "1f696", "1f6a1", "1f6a0"]
    private let objectEmojiCodes = ["1f4f1", "1f5a5", "1f4bb", "2328", "1f3a4", "1f4fa", "1f50d", "1f514", "1f511", "1f5dd", "1f50c", "1f50b", "1f4a1", "1f4b0"]
    private let flowerEmojiCodes = ["1f338", "1f33a", "1f33b", "1f37c", "1f390", "1f3f5", "1f31a", "1f38d", "1f339", "1f940", "1f342", "1f331", "1f343", "1f340", "1fabe", "2744"]
    private let animalEmojiCodes = ["1f415", "1f416", "1f429", "1f43b", "1f436", "1f431", "1f42d", "1f439", "1f42e", "1f984", "1f98e", "1f409", "1f996", "1f995", "1f422", "1f40a"]
    private let foodEmojiCodes = ["1f354", "1f35f", "1f355", "1f32d", "1f2e1", "1f2e2", "1f2e3", "1f2e4", "1f2e5", "1f2e6", "1f2e7", "1f2e8", "1f2e9", "1f2ea", "1f2eb", "1f2ec"]
    private let fruitEmojiCodes = ["1f34e", "1f34f", "1f34a", "1f34b", "1f34c", "1f34d", "1f347", "1f353", "1f348", "1f349", "1f346", "1f345", "1f95d", "1f951", "1f952", "1f965"]
    private let vehicleEmojiCodes = ["1f68f", "1f68e", "1f68c", "1f699", "1f697", "1f695", "1f693", "1f691", "1f692", "1f6b2", "1f6b4", "1f6b6", "1f6a1", "1f6a0", "26f5", "1f6f6"]
    private let sportEmojiCodes = ["26bd", "26be", "1f3c0", "1f3c8", "1f3be", "1f3d0", "1f3c8", "1f3ca", "1f3cb", "1f3cc", "1f3c4", "1f3c5", "1f3c6", "1f3c7", "1f3c9", "1f3cf"]
    private let musicEmojiCodes = ["1f3b5", "1f3b6", "1f3b7", "1f3b8", "1f3b9", "1f3ba", "1f3bb", "1f3bc", "1f3a4", "1f3a7", "1f3a8", "1f3a9", "1f3b2", "1f3b1", "1f3b0", "1f941"]
    private let technologyEmojiCodes = ["1f4bb", "1f5a5", "1f5a8", "1f5b1", "1f5b2", "1f579", "1f57a", "2328", "1f511", "1f512", "1f50f", "1f510", "1f5dc", "1f5dd", "1f5de", "1f5df"]
    private let clothingEmojiCodes = ["1f453", "1f454", "1f455", "1f456", "1f457", "1f458", "1f459", "1f45a", "1f45b", "1f45c", "1f45d", "1f45e", "1f45f", "1f460", "1f461", "1f462"]
    private let natureEmojiCodes = ["1f304", "1f305", "1f306", "1f307", "1f308", "1f309", "1f30a", "1f30b", "1f30c", "1f30d", "1f30e", "1f30f", "1f310", "1f311", "1f312", "1f313"]
    private let toolEmojiCodes = ["1f527", "1f528", "1f529", "1f52a", "1f52b", "1f6aa", "1f6b0", "2692", "2694", "2699", "26a0", "26a1", "2696", "2697", "26b0", "26b1"]
    
    // Fallback static emojis for when animated ones aren't available
    private let faceEmojis: [String] = ["😊", "😎", "🤗", "😮", "🙂", "😄", "🤩", "😋", "😢", "😭", "😉", "😕", "😚", "🥰", "🤯", "🥵"]
    private let handGestureEmojis: [String] = ["👋", "👍", "✌️", "🤟", "👌", "🙏", "👏", "✋", "👎", "🖕", "👈", "👉", "👆", "👇", "🖖", "🤘"]
    private let buildingEmojis: [String] = ["🏢", "🏠", "🏛️", "🏗️", "🏘️", "🏚️", "🏭", "🏰", "🏪", "🏫", "⛪", "🕌", "🛕", "🛤️"]
    private let carEmojis: [String] = ["🚗", "🚙", "🚕", "🏎️", "🚓", "🚑", "🚒", "🚐", "🚚", "🚛", "🚜", "🏍️", "🚲", "🛴", "🚁", "🛸"]
    private let objectEmojis: [String] = ["📱", "💻", "⌚", "🎮", "📷", "🎧", "🔍", "🔔", "🔑", "🗝️", "🔐", "🔒", "💡", "💰", "📌", "📍"]
    private let flowerEmojis: [String] = ["🌸", "🌺", "🌻", "🌷", "🌹", "🏵️", "🌼", "🌿", "🥀", "🌵", "🌲", "🌱", "🌾", "🍀", "❄️", "🌳"]
    private let animalEmojis: [String] = ["🐕", "🐖", "🐱", "🐻", "🐶", "🐰", "🐭", "🐹", "🐄", "🦏", "🦒", "🦕", "🦖", "🐢", "🦎", "🐍"]
    private let foodEmojis: [String] = ["🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🌯", "🥙", "🧆", "🥚", "🍳", "🥘", "🍲", "🥣", "🍗", "🍖"]
    private let fruitEmojis: [String] = ["🍎", "🍏", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🫐", "🍈", "🥒", "🍅", "🥑", "🥝", "🥥", "🥭"]
    private let vehicleEmojis: [String] = ["🚕", "🚙", "🚌", "🚎", "🏎️", "🚓", "🚑", "🚒", "🚐", "🚚", "🚛", "🚜", "🏍️", "🛵", "🚲", "⛵"]
    private let sportEmojis: [String] = ["⚽", "⚾", "🏀", "🏈", "🎾", "🎱", "🏓", "🏸", "🥊", "🥋", "🥅", "⛳", "🏹", "🎣", "🤿", "🥌"]
    private let musicEmojis: [String] = ["🎵", "🎶", "🎼", "🎧", "🎤", "🎸", "🥁", "🎹", "🎺", "🎷", "🪘", "🪗", "🎻", "🪕", "🪇", "🎙️"]
    private let technologyEmojis: [String] = ["💻", "🖥️", "⌨️", "🖱️", "🖨️", "📠", "📞", "☎️", "📱", "📲", "⌚", "🔋", "🔌", "💾", "💿", "📀"]
    private let clothingEmojis: [String] = ["👓", "🕶️", "🥽", "👔", "👕", "👖", "🧣", "🧤", "🧥", "🧦", "👗", "👘", "🥻", "🩱", "🩲", "🩳"]
    private let natureEmojis: [String] = ["🌅", "🌄", "🌠", "🌇", "🌆", "🌃", "🌉", "🌌", "🌠", "⭐", "🌟", "✨", "💫", "☄️", "🪐", "🌎"]
    private let toolEmojis: [String] = ["🔧", "🔨", "⚒️", "🛠️", "⛏️", "🗡️", "⚔️", "💣", "🪓", "🔱", "⚙️", "🧲", "🔩", "⚓", "🪝", "🦯"]
    
    private init() {}
    
    func getEmojiImage(for code: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: "AnimatedEmojis/\(code)", withExtension: "gif"),
              let data = try? Data(contentsOf: url) else {
            print("Failed to load GIF for code: \(code)")
            return nil
        }
        
        return UIImage(data: data)
    }
    
    func getEmojiCodeForType(_ type: DetectionType, confidence: Float) -> String? {
        let codes: [String]
        
        switch type {
        case .face:
            codes = faceEmojiCodes
        case .handGesture:
            codes = handGestureEmojiCodes
        case .building:
            codes = buildingEmojiCodes
        case .car:
            codes = carEmojiCodes
        case .object:
            codes = objectEmojiCodes
        case .flower:
            codes = flowerEmojiCodes
        case .animal:
            codes = animalEmojiCodes
        case .food:
            codes = foodEmojiCodes
        case .fruit:
            codes = fruitEmojiCodes
        case .vehicle:
            codes = vehicleEmojiCodes
        case .sport:
            codes = sportEmojiCodes
        case .music:
            codes = musicEmojiCodes
        case .technology:
            codes = technologyEmojiCodes
        case .clothing:
            codes = clothingEmojiCodes
        case .nature:
            codes = natureEmojiCodes
        case .tool:
            codes = toolEmojiCodes
        }
        
        // Select emoji code based on confidence (higher confidence = better emojis)
        let index = min(Int(Float(codes.count) * confidence), codes.count - 1)
        let selectedCode = codes[index]
        
        // Check if the animated emoji is available
        return getEmojiImage(for: selectedCode) != nil ? selectedCode : nil
    }
    
    func getFallbackEmojiForType(_ type: DetectionType, confidence: Float) -> String {
        let emojis: [String]
        
        switch type {
        case .face:
            emojis = faceEmojis
        case .handGesture:
            emojis = handGestureEmojis
        case .building:
            emojis = buildingEmojis
        case .car:
            emojis = carEmojis
        case .object:
            emojis = objectEmojis
        case .flower:
            emojis = flowerEmojis
        case .animal:
            emojis = animalEmojis
        case .food:
            emojis = foodEmojis
        case .fruit:
            emojis = fruitEmojis
        case .vehicle:
            emojis = vehicleEmojis
        case .sport:
            emojis = sportEmojis
        case .music:
            emojis = musicEmojis
        case .technology:
            emojis = technologyEmojis
        case .clothing:
            emojis = clothingEmojis
        case .nature:
            emojis = natureEmojis
        case .tool:
            emojis = toolEmojis
        }
        
        // Select emoji based on confidence (higher confidence = more positive emojis)
        let index = min(Int(Float(emojis.count) * confidence), emojis.count - 1)
        return emojis[index]
    }
    
    func getEmojiDisplay(for type: DetectionType, confidence: Float) -> EmojiDisplay {
        // Try to get animated emoji first
        if let emojiCode = getEmojiCodeForType(type, confidence: confidence) {
            return .animated(code: emojiCode)
        }
        
        // Fall back to static emoji
        let staticEmoji = getFallbackEmojiForType(type, confidence: confidence)
        return .staticEmoji(emoji: staticEmoji)
    }
    
    func preloadEssentialEmojis() {
        let allCodes = faceEmojiCodes + handGestureEmojiCodes + buildingEmojiCodes + carEmojiCodes + objectEmojiCodes + 
                      flowerEmojiCodes + animalEmojiCodes + foodEmojiCodes + fruitEmojiCodes + vehicleEmojiCodes +
                      sportEmojiCodes + musicEmojiCodes + technologyEmojiCodes + clothingEmojiCodes + 
                      natureEmojiCodes + toolEmojiCodes
        
        DispatchQueue.global(qos: .utility).async {
            for code in allCodes {
                _ = self.getEmojiImage(for: code)
            }
        }
    }
}
