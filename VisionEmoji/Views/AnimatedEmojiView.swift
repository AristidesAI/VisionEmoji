//
//  AnimatedEmojiView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI

struct AnimatedEmojiView: View {
    let emojiCode: String
    let size: CGFloat
    let opacity: Float
    let rotation: Double
    let scale: CGFloat
    
    @State private var animatedImage: UIImage?
    
    init(emojiCode: String, size: CGFloat, opacity: Float, rotation: Double, scale: CGFloat) {
        self.emojiCode = emojiCode
        self.size = size
        self.opacity = opacity
        self.rotation = rotation
        self.scale = scale
    }
    
    var body: some View {
        Group {
            if let image = animatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .opacity(Double(opacity))
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
            } else {
                // Fallback to loading indicator or placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size, height: size)
                    .opacity(Double(opacity))
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
            }
        }
        .onAppear {
            loadAnimatedImage()
        }
    }
    
    private func loadAnimatedImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let image = EmojiAssetService.shared.getEmojiImage(for: emojiCode)
            
            DispatchQueue.main.async {
                self.animatedImage = image
            }
        }
    }
}

// MARK: - Helper Extensions
extension Double {
    static func radians(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }
}

// MARK: - Preview
struct AnimatedEmojiView_Previews: PreviewProvider {
    static var previews: some View {
        AnimatedEmojiView(
            emojiCode: "1f600",
            size: 60,
            opacity: 1.0,
            rotation: 0,
            scale: 1.0
        )
        .frame(width: 100, height: 100)
        .background(Color.gray.opacity(0.3))
    }
}
