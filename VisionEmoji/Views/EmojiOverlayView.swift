//
//  EmojiOverlayView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import SwiftUI

struct EmojiOverlayView: View {
    let overlays: [EmojiOverlay]
    let settings: OverlaySettings

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(overlays) { overlay in
                    EmojiOverlayItem(overlay: overlay, settings: settings)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct EmojiOverlayItem: View {
    let overlay: EmojiOverlay
    let settings: OverlaySettings

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            if settings.showTrackingLayer {
                Rectangle()
                    .stroke(Color(cgColor: overlay.detectionType.overlayColor), lineWidth: 2)
                    .frame(width: overlay.size.width, height: overlay.size.height)
            }

            EmojiView(emoji: overlay.emoji, size: overlay.size)
                .scaleEffect(isPulsing && settings.enablePulse ? 1.1 : 1.0)
                .animation(
                    settings.enablePulse
                        ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                        : .default,
                    value: isPulsing
                )
        }
        .opacity(overlay.opacity)
        .scaleEffect(overlay.scale)
        .position(
            x: overlay.position.x + overlay.size.width / 2,
            y: overlay.position.y + overlay.size.height / 2
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: overlay.position)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: overlay.size)
        .animation(.easeOut(duration: 0.3), value: overlay.opacity)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: overlay.scale)
        .onAppear {
            if settings.enablePulse {
                isPulsing = true
            }
        }
    }
}

#Preview {
    let sampleOverlays = [
        EmojiOverlay(
            id: UUID(),
            emoji: "😄",
            position: CGPoint(x: 100, y: 100),
            size: CGSize(width: 80, height: 80),
            opacity: 1.0,
            scale: 1.0,
            detectionType: .face,
            lastUpdated: Date()
        ),
        EmojiOverlay(
            id: UUID(),
            emoji: "🚗",
            position: CGPoint(x: 200, y: 300),
            size: CGSize(width: 100, height: 100),
            opacity: 1.0,
            scale: 1.0,
            detectionType: .object,
            lastUpdated: Date()
        ),
    ]

    EmojiOverlayView(overlays: sampleOverlays, settings: OverlaySettings())
        .background(Color.black)
}
