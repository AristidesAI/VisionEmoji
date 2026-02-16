//
//  EmojiOverlayService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI
import Combine
import CoreGraphics
import CoreImage

class EmojiOverlayService: ObservableObject {
    @Published var overlays: [EmojiOverlay] = []
    @Published var overlaySettings = OverlaySettings()
    
    func updateOverlays(with detectionResults: [DetectionResult], viewSize: CGSize) {
        let currentTime = Date()
        
        // Remove old overlays
        overlays.removeAll { overlay in
            currentTime.timeIntervalSince(overlay.trackingData.lastSeen) > 0.5
        }
        
        // Update or create overlays for new detections
        for result in detectionResults {
            let normalizedBoundingBox = normalizeBoundingBox(result.boundingBox, to: viewSize)
            
            if let existingIndex = overlays.firstIndex(where: { $0.detectionResult.id == result.id }) {
                // Update existing overlay
                updateOverlay(&overlays[existingIndex], with: result, boundingBox: normalizedBoundingBox)
            } else {
                // Create new overlay
                let newOverlay = EmojiOverlay(
                    detectionResult: result,
                    boundingBox: normalizedBoundingBox,
                    settings: overlaySettings
                )
                overlays.append(newOverlay)
            }
        }
        
        // Update tracking for all overlays
        for i in overlays.indices {
            updateTrackingData(&overlays[i])
        }
    }
    
    private func updateOverlay(_ overlay: inout EmojiOverlay, with result: DetectionResult, boundingBox: CGRect) {
        let newPosition = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        
        // Apply smoothing to position
        let smoothedX = overlay.position.x + (newPosition.x - overlay.position.x) * CGFloat(overlaySettings.smoothingFactor)
        let smoothedY = overlay.position.y + (newPosition.y - overlay.position.y) * CGFloat(overlaySettings.smoothingFactor)
        
        overlay.position = CGPoint(x: smoothedX, y: smoothedY)
        overlay.trackingData.boundingBox = boundingBox
        overlay.trackingData.lastSeen = Date()
        
        // Update animation data if emoji type changed
        if case .animated(let code) = result.emojiDisplay {
            if overlay.animationData?.emojiCode != code {
                overlay.animationData = AnimationData(emojiCode: code)
            }
        }
    }
    
    private func updateTrackingData(_ overlay: inout EmojiOverlay) {
        overlay.trackingData.velocity = calculateVelocity(overlay: overlay)
        overlay.trackingData.detectionCount += 1
    }
    
    private func calculateVelocity(overlay: EmojiOverlay) -> CGPoint {
        // Simple velocity calculation based on position changes
        return CGPoint(x: 0, y: 0) // Simplified for now
    }
    
    private func normalizeBoundingBox(_ boundingBox: CGRect, to viewSize: CGSize) -> CGRect {
        // Vision coordinates are normalized (0,0 is bottom-left)
        // SwiftUI coordinates are (0,0) is top-left
        let x = boundingBox.origin.x * viewSize.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * viewSize.height
        let width = boundingBox.width * viewSize.width
        let height = boundingBox.height * viewSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    func clearOverlays() {
        overlays.removeAll()
    }
}

struct TrackingData {
    var boundingBox: CGRect
    var lastSeen: Date
    var velocity: CGPoint = .zero
    var detectionCount: Int = 0
    
    init(boundingBox: CGRect) {
        self.boundingBox = boundingBox
        self.lastSeen = Date()
    }
}

struct OverlaySettings {
    var baseScale: CGFloat = 2.0
    var scaleMultiplier: CGFloat = 1.0
    var maxOpacity: Float = 0.8
    var smoothingFactor: Double = 0.7
    var showAnimations: Bool = true
    var enablePulse: Bool = true
}

struct EmojiOverlay: Identifiable {
    let id = UUID()
    var position: CGPoint
    let detectionResult: DetectionResult
    var trackingData: TrackingData
    var displaySettings: OverlaySettings
    var animationData: AnimationData?
    
    // Animation properties
    var scale: CGFloat = 1.0
    var opacity: Float = 1.0
    var rotation: Double = 0.0
    var animationDuration: Double = 0.2
    
    init(detectionResult: DetectionResult, boundingBox: CGRect, settings: OverlaySettings) {
        self.detectionResult = detectionResult
        self.position = CGPoint(x: boundingBox.midX, y: boundingBox.midY)
        self.trackingData = TrackingData(boundingBox: boundingBox)
        self.displaySettings = settings
        
        // Initialize animation data for animated emojis
        if case .animated(let code) = detectionResult.emojiDisplay {
            self.animationData = AnimationData(emojiCode: code)
        }
    }
}

struct AnimationData {
    let emojiCode: String
    var isPlaying = true
    
    init(emojiCode: String) {
        self.emojiCode = emojiCode
    }
}

struct EmojiOverlayView: View {
    let overlays: [EmojiOverlay]
    let settings: OverlaySettings
    
    init(overlays: [EmojiOverlay], settings: OverlaySettings = OverlaySettings()) {
        self.overlays = overlays
        self.settings = settings
    }
    
    var body: some View {
        ZStack {
            ForEach(overlays) { overlay in
                overlayView(for: overlay)
            }
        }
    }
    
    @ViewBuilder
    private func overlayView(for overlay: EmojiOverlay) -> some View {
        let size = calculateSize(for: overlay)
        let opacity = calculateOpacity(for: overlay.detectionResult.confidence)
        let rotation = calculateRotation(for: overlay.detectionResult, trackingData: overlay.trackingData)
        let scale = calculateScale(for: overlay.detectionResult)
        
        Group {
            switch overlay.detectionResult.emojiDisplay {
            case .animated(let code):
                AnimatedEmojiView(
                    emojiCode: code,
                    size: size,
                    opacity: opacity,
                    rotation: rotation,
                    scale: scale
                )
            case .staticEmoji(let emoji):
                Text(emoji)
                    .font(.system(size: size))
                    .opacity(opacity)
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
            }
        }
        .opacity(overlay.opacity)
        .rotationEffect(.degrees(overlay.rotation))
        .position(overlay.position)
        .animation(.easeInOut(duration: overlay.animationDuration), value: overlay.position)
        .animation(.easeInOut(duration: overlay.animationDuration), value: overlay.scale)
        .modifier(
            settings.enablePulse && overlay.detectionResult.type == .face ?
            PulseModifier(intensity: overlay.detectionResult.confidence) : EmptyModifier()
        )
    }
    
    private func calculateSize(for overlay: EmojiOverlay) -> CGFloat {
        let baseSize: CGFloat = 40
        let scaleFactor = overlay.displaySettings.baseScale * overlay.displaySettings.scaleMultiplier
        return baseSize * scaleFactor * overlay.scale
    }
    
    private func calculateScale(for result: DetectionResult) -> CGFloat {
        let baseScale: CGFloat = 1.0
        let confidenceMultiplier = CGFloat(result.confidence)
        let typeMultiplier: CGFloat
        
        switch result.type {
        case .face:
            typeMultiplier = 1.2
        case .handGesture:
            typeMultiplier = 1.0
        case .building, .car:
            typeMultiplier = 1.5
        case .object:
            typeMultiplier = 0.8
        case .flower:
            typeMultiplier = 1.1
        case .animal:
            typeMultiplier = 1.3
        case .food:
            typeMultiplier = 1.0
        case .fruit:
            typeMultiplier = 0.9
        case .vehicle:
            typeMultiplier = 1.4
        case .sport:
            typeMultiplier = 1.2
        case .music:
            typeMultiplier = 1.1
        case .technology:
            typeMultiplier = 1.0
        case .clothing:
            typeMultiplier = 0.9
        case .nature:
            typeMultiplier = 1.6
        case .tool:
            typeMultiplier = 1.1
        }
        
        return baseScale * confidenceMultiplier * typeMultiplier
    }
    
    private func calculateOpacity(for confidence: Float) -> Float {
        return confidence * 0.8 + 0.2 // Minimum opacity of 0.2
    }
    
    private func calculateRotation(for result: DetectionResult, trackingData: TrackingData) -> Double {
        // Add slight rotation based on velocity for dynamic effect
        let velocityMagnitude = sqrt(trackingData.velocity.x * trackingData.velocity.x + trackingData.velocity.y * trackingData.velocity.y)
        return Double(velocityMagnitude * 10) // Scale factor for rotation effect
    }
}

struct PulseModifier: ViewModifier {
    let intensity: Float
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(Color.white.opacity(0.3 * Double(intensity)))
                    .scaleEffect(1.2)
                    .blur(radius: 5)
            )
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: intensity
            )
    }
}

// MARK: - View Extensions
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
