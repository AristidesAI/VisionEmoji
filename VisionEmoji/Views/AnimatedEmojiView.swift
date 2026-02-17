//
//  AnimatedEmojiView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import SwiftUI

/// Displays an Apple emoji as a SwiftUI Text view
struct EmojiView: View {
    let emoji: String
    let size: CGSize

    var body: some View {
        Text(emoji)
            .font(.system(size: size.height * 0.8))
            .frame(width: size.width, height: size.height)
    }
}

#Preview {
    VStack(spacing: 20) {
        EmojiView(emoji: "😄", size: CGSize(width: 100, height: 100))
        EmojiView(emoji: "🚗", size: CGSize(width: 100, height: 100))
        EmojiView(emoji: "🐶", size: CGSize(width: 80, height: 80))
        EmojiView(emoji: "🏢", size: CGSize(width: 60, height: 60))
    }
}
