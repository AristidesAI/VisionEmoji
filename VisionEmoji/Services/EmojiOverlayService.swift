//
//  EmojiOverlayService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import Foundation
import CoreGraphics
import SwiftUI
import Combine

@MainActor
class EmojiOverlayService: ObservableObject {
    @Published var overlays: [EmojiOverlay] = []
    @Published var overlaySettings = OverlaySettings()

    private var previousOverlays: [UUID: EmojiOverlay] = [:]

    func updateOverlays(with results: [DetectionResult], viewSize: CGSize) {
        var newOverlays: [EmojiOverlay] = []
        let now = Date()

        for result in results {
            let convertedRect = convertVisionToViewCoordinates(
                visionRect: result.boundingBox,
                viewSize: viewSize
            )

            // Emoji size matches the bounding box (locked to object size)
            let emojiSize = calculateEmojiSize(for: convertedRect.size)

            if let previousOverlay = previousOverlays[result.id] {
                let smoothedPosition = overlaySettings.enableKalmanFilter
                    ? applyKalmanFilter(previous: previousOverlay.position, new: convertedRect.origin)
                    : applySimpleSmoothing(previous: previousOverlay.position, new: convertedRect.origin)

                let smoothedSize = overlaySettings.enableKalmanFilter
                    ? applyKalmanFilter(previous: previousOverlay.size, new: emojiSize)
                    : applySimpleSmoothing(previous: previousOverlay.size, new: emojiSize)

                let updatedOverlay = EmojiOverlay(
                    id: result.id,
                    emoji: result.emoji,
                    position: smoothedPosition,
                    size: smoothedSize,
                    opacity: 1.0,
                    scale: 1.0,
                    detectionType: result.type,
                    lastUpdated: now
                )

                newOverlays.append(updatedOverlay)
                previousOverlays[result.id] = updatedOverlay

            } else {
                var newOverlay = EmojiOverlay(
                    id: result.id,
                    emoji: result.emoji,
                    position: convertedRect.origin,
                    size: emojiSize,
                    opacity: 0.0,
                    scale: 0.5,
                    detectionType: result.type,
                    lastUpdated: now
                )

                newOverlay.opacity = 1.0
                newOverlay.scale = 1.0

                newOverlays.append(newOverlay)
                previousOverlays[result.id] = newOverlay
            }
        }

        // Fade out old overlays
        let currentIDs = Set(results.map { $0.id })
        for (id, overlay) in previousOverlays where !currentIDs.contains(id) {
            if now.timeIntervalSince(overlay.lastUpdated) < 0.5 {
                var fadingOverlay = overlay
                fadingOverlay.opacity = 0.0
                fadingOverlay.scale = 0.5
                newOverlays.append(fadingOverlay)

                Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)
                    previousOverlays.removeValue(forKey: id)
                }
            } else {
                previousOverlays.removeValue(forKey: id)
            }
        }

        self.overlays = newOverlays
    }

    // MARK: - Coordinate Conversion

    private func convertVisionToViewCoordinates(visionRect: CGRect, viewSize: CGSize) -> CGRect {
        let x = visionRect.origin.x * viewSize.width
        let y = (1 - visionRect.origin.y - visionRect.height) * viewSize.height
        let width = visionRect.width * viewSize.width
        let height = visionRect.height * viewSize.height
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func calculateEmojiSize(for boundingBoxSize: CGSize) -> CGSize {
        // Lock emoji size to the bounding box – use the smaller dimension so the emoji fits inside
        let size = min(boundingBoxSize.width, boundingBoxSize.height)
        let minSize: CGFloat = 40
        let finalSize = max(size, minSize)
        return CGSize(width: finalSize, height: finalSize)
    }

    // MARK: - Smoothing

    private func applySimpleSmoothing(previous: CGPoint, new: CGPoint) -> CGPoint {
        let f = overlaySettings.smoothingFactor
        return CGPoint(x: previous.x * f + new.x * (1 - f), y: previous.y * f + new.y * (1 - f))
    }

    private func applySimpleSmoothing(previous: CGSize, new: CGSize) -> CGSize {
        let f = overlaySettings.smoothingFactor
        return CGSize(width: previous.width * f + new.width * (1 - f), height: previous.height * f + new.height * (1 - f))
    }

    private func applyKalmanFilter(previous: CGPoint, new: CGPoint) -> CGPoint {
        let gain = overlaySettings.kalmanProcessNoise / (overlaySettings.kalmanProcessNoise + 0.01)
        return CGPoint(x: previous.x + gain * (new.x - previous.x), y: previous.y + gain * (new.y - previous.y))
    }

    private func applyKalmanFilter(previous: CGSize, new: CGSize) -> CGSize {
        let gain = overlaySettings.kalmanProcessNoise / (overlaySettings.kalmanProcessNoise + 0.01)
        return CGSize(width: previous.width + gain * (new.width - previous.width), height: previous.height + gain * (new.height - previous.height))
    }
}

// MARK: - EmojiOverlay

struct EmojiOverlay: Identifiable {
    let id: UUID
    let emoji: String
    var position: CGPoint
    var size: CGSize
    var opacity: Double
    var scale: Double
    let detectionType: DetectionType
    var lastUpdated: Date
}

// MARK: - OverlaySettings

struct OverlaySettings {
    var smoothingFactor: Double = 0.7
    var enableKalmanFilter = true
    var kalmanProcessNoise: Double = 0.01
    var enablePulse = false
    var showTrackingLayer = false
}
