//
//  EmojiAssetService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import Foundation
import UIKit

@MainActor
class EmojiAssetService {
    static let shared = EmojiAssetService()

    private var emojiImageCache: [String: UIImage] = [:]

    private init() {}

    /// Render an Apple emoji string into a UIImage at the given size
    func emojiImage(for emoji: String, size: CGSize) -> UIImage {
        let cacheKey = "\(emoji)_\(Int(size.width))"

        if let cached = emojiImageCache[cacheKey] {
            return cached
        }

        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { _ in
            let fontSize = size.height * 0.85
            let font = UIFont.systemFont(ofSize: fontSize)
            let attributes: [NSAttributedString.Key: Any] = [.font: font]
            let textSize = (emoji as NSString).size(withAttributes: attributes)
            let rect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            (emoji as NSString).draw(in: rect, withAttributes: attributes)
        }

        emojiImageCache[cacheKey] = image
        return image
    }

    func clearCache() {
        emojiImageCache.removeAll()
    }
}
