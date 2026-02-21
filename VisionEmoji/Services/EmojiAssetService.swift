//
//  EmojiAssetService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import Foundation
import UIKit

class EmojiAssetService {
    static let shared = EmojiAssetService()

    private let imageCache = NSCache<NSString, UIImage>()

    private init() {
        imageCache.countLimit = 200
    }

    /// Renders an emoji string to a UIImage at the given point size.
    func emojiImage(_ emoji: String, size: CGFloat) -> UIImage? {
        let key = "\(emoji)_\(Int(size))" as NSString
        if let cached = imageCache.object(forKey: key) {
            return cached
        }

        let fontSize = size * 0.85
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize)
        ]
        let string = emoji as NSString
        let textSize = string.size(withAttributes: attributes)

        let renderer = UIGraphicsImageRenderer(size: textSize)
        let image = renderer.image { _ in
            string.draw(at: .zero, withAttributes: attributes)
        }

        imageCache.setObject(image, forKey: key)
        return image
    }

    /// Preloads essential emojis used by COCO detection classes.
    func preloadEssentialEmojis() {
        let essentials = [
            "🧑", "🚲", "🚗", "🏍️", "✈️", "🚌", "🚂", "🚢",
            "🚦", "🛑", "🅿️", "🐦", "🐈", "🐕", "🐎", "🐑",
            "🐄", "🐘", "🐻", "🦓", "🦒", "🎒", "☂️", "👜",
            "👔", "🎿", "🏄", "⚾", "🪁", "🏏", "🛹", "🏂",
            "🎾", "🏐", "🏈", "⚽", "🍌", "🍎", "🥪", "🥕",
            "🌭", "🍕", "🍩", "🎂", "🪑", "🛋️", "🛏️", "🚽",
            "📺", "💻", "📱", "⌨️", "🖱️", "📡", "🕰️", "💡"
        ]

        DispatchQueue.global(qos: .utility).async { [weak self] in
            for emoji in essentials {
                _ = self?.emojiImage(emoji, size: 80)
            }
        }
    }
}
