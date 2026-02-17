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

    private var showBoxes: Bool {
        settings.displayMode == .debug || settings.showTrackingLayer
    }

    private var showEmoji: Bool {
        settings.displayMode == .emoji || settings.displayMode == .debug
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if showBoxes {
                Rectangle()
                    .stroke(Color(cgColor: overlay.detectionType.overlayColor), lineWidth: 2)
                    .frame(width: overlay.boundingBoxSize.width, height: overlay.boundingBoxSize.height)

                // Label + confidence badge
                HStack(spacing: 3) {
                    Text(overlay.label)
                        .font(.system(size: 11, weight: .bold))
                    Text(String(format: "%.0f%%", overlay.confidence * 100))
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(cgColor: overlay.detectionType.overlayColor).opacity(0.85))
                .cornerRadius(3)
                .offset(y: -20)

                // Classification annotation badge (if available)
                if let clsLabel = overlay.classificationLabel {
                    Text(clsLabel)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(2)
                        .offset(y: overlay.boundingBoxSize.height + 2)
                }
            }

            // Emoji centered in the bounding box
            if showEmoji {
                EmojiView(emoji: overlay.emoji, size: overlay.size)
                    .scaleEffect(isPulsing && settings.enablePulse ? 1.1 : 1.0)
                    .animation(
                        settings.enablePulse
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )
                    .frame(width: overlay.boundingBoxSize.width, height: overlay.boundingBoxSize.height)
            }
        }
        .opacity(overlay.opacity)
        .scaleEffect(overlay.scale)
        .position(
            x: overlay.position.x + overlay.boundingBoxSize.width / 2,
            y: overlay.position.y + overlay.boundingBoxSize.height / 2
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: overlay.position)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: overlay.boundingBoxSize)
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
            emoji: "🚗",
            position: CGPoint(x: 200, y: 300),
            size: CGSize(width: 100, height: 100),
            boundingBoxSize: CGSize(width: 140, height: 100),
            opacity: 1.0,
            scale: 1.0,
            detectionType: .object,
            lastUpdated: Date(),
            label: "car",
            confidence: 0.78
        ),
    ]

    EmojiOverlayView(overlays: sampleOverlays, settings: OverlaySettings())
        .background(Color.black)
}
