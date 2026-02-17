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

            let emojiSize = calculateEmojiSize(for: convertedRect.size)

            if let previousOverlay = previousOverlays[result.id] {
                let smoothedPosition = overlaySettings.enableKalmanFilter
                    ? applyKalmanFilter(previous: previousOverlay.position, new: convertedRect.origin)
                    : applySimpleSmoothing(previous: previousOverlay.position, new: convertedRect.origin)

                let smoothedSize = overlaySettings.enableKalmanFilter
                    ? applyKalmanFilter(previous: previousOverlay.size, new: emojiSize)
                    : applySimpleSmoothing(previous: previousOverlay.size, new: emojiSize)

                let smoothedBBoxSize = overlaySettings.enableKalmanFilter
                    ? applyKalmanFilter(previous: previousOverlay.boundingBoxSize, new: convertedRect.size)
                    : applySimpleSmoothing(previous: previousOverlay.boundingBoxSize, new: convertedRect.size)

                let updatedOverlay = EmojiOverlay(
                    id: result.id,
                    emoji: result.emoji,
                    position: smoothedPosition,
                    size: smoothedSize,
                    boundingBoxSize: smoothedBBoxSize,
                    opacity: 1.0,
                    scale: 1.0,
                    detectionType: result.type,
                    lastUpdated: now,
                    label: result.label,
                    confidence: result.confidence,
                    classificationLabel: result.classificationLabel
                )

                newOverlays.append(updatedOverlay)
                previousOverlays[result.id] = updatedOverlay

            } else {
                var newOverlay = EmojiOverlay(
                    id: result.id,
                    emoji: result.emoji,
                    position: convertedRect.origin,
                    size: emojiSize,
                    boundingBoxSize: convertedRect.size,
                    opacity: 0.0,
                    scale: 0.5,
                    detectionType: result.type,
                    lastUpdated: now,
                    label: result.label,
                    confidence: result.confidence,
                    classificationLabel: result.classificationLabel
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

    func resetOverlays() {
        overlays = []
        previousOverlays.removeAll()
    }

    // MARK: - Coordinate Conversion

    private let cameraAspectRatio: CGFloat = 1080.0 / 1920.0

    private func convertVisionToViewCoordinates(visionRect: CGRect, viewSize: CGSize) -> CGRect {
        let viewAspect = viewSize.width / viewSize.height

        var scaleX: CGFloat
        var scaleY: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0

        if cameraAspectRatio < viewAspect {
            let scaledHeight = viewSize.width / cameraAspectRatio
            scaleX = viewSize.width
            scaleY = scaledHeight
            offsetY = (viewSize.height - scaledHeight) / 2
        } else {
            let scaledWidth = viewSize.height * cameraAspectRatio
            scaleX = scaledWidth
            scaleY = viewSize.height
            offsetX = (viewSize.width - scaledWidth) / 2
        }

        let x = visionRect.origin.x * scaleX + offsetX
        let y = (1 - visionRect.origin.y - visionRect.height) * scaleY + offsetY + overlaySettings.overlayYOffset
        let width = visionRect.width * scaleX
        let height = visionRect.height * scaleY

        return CGRect(x: x, y: y, width: width, height: height)
    }

    private func calculateEmojiSize(for boundingBoxSize: CGSize) -> CGSize {
        let dimension = min(boundingBoxSize.width, boundingBoxSize.height)
        let scaled = dimension * overlaySettings.emojiScale
        let finalSize = max(scaled, 30)
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
        let gain = overlaySettings.kalmanProcessNoise / (overlaySettings.kalmanProcessNoise + overlaySettings.kalmanMeasurementNoise)
        return CGPoint(x: previous.x + gain * (new.x - previous.x), y: previous.y + gain * (new.y - previous.y))
    }

    private func applyKalmanFilter(previous: CGSize, new: CGSize) -> CGSize {
        let gain = overlaySettings.kalmanProcessNoise / (overlaySettings.kalmanProcessNoise + overlaySettings.kalmanMeasurementNoise)
        return CGSize(width: previous.width + gain * (new.width - previous.width), height: previous.height + gain * (new.height - previous.height))
    }
}

// MARK: - EmojiOverlay

struct EmojiOverlay: Identifiable {
    let id: UUID
    let emoji: String
    var position: CGPoint
    var size: CGSize
    var boundingBoxSize: CGSize
    var opacity: Double
    var scale: Double
    let detectionType: DetectionType
    var lastUpdated: Date
    let label: String
    let confidence: Float
    var classificationLabel: String?
}

// MARK: - OverlaySettings

struct OverlaySettings {
    var smoothingFactor: Double = 0.7
    var enableKalmanFilter = true
    var kalmanProcessNoise: Double = 0.01
    var kalmanMeasurementNoise: Double = 0.01
    var enablePulse = false
    var showTrackingLayer = false
    var displayMode: DisplayMode = .debug
    var emojiScale: Double = 0.5
    var overlayYOffset: Double = 0
}
