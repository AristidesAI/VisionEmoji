//
//  SettingsView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var visionService: VisionService
    @ObservedObject var overlayService: EmojiOverlayService

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Model", selection: $visionService.selectedModel) {
                        ForEach(YOLOModel.allCases) { model in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.rawValue)
                                Text(model.subtitle)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .tag(model)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("YOLO Model")
                }

                Section("Detection") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Confidence")
                            Spacer()
                            Text(String(format: "%.0f%%", visionService.confidenceThreshold * 100))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit()
                        }
                        Slider(value: $visionService.confidenceThreshold, in: 0.1...0.9, step: 0.05)
                    }

                    detectionRow("😊 Faces", isOn: $visionService.isFaceDetectionEnabled,
                                 ms: visionService.faceProcessingTime)
                    detectionRow("👋 Hands", isOn: $visionService.isHandDetectionEnabled,
                                 ms: visionService.handProcessingTime)
                    detectionRow("🧍 Body", isOn: $visionService.isBodyDetectionEnabled,
                                 ms: visionService.bodyProcessingTime)
                }

                Section("Display") {
                    Picker("Display Mode", selection: $overlayService.overlaySettings.displayMode) {
                        ForEach(DisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Kalman Smoothing", isOn: $overlayService.overlaySettings.enableKalmanFilter)
                }

                Section("Performance") {
                    HStack {
                        Text("FPS")
                        Spacer()
                        Text(String(format: "%.0f", visionService.fps))
                            .foregroundColor(visionService.fps >= 25 ? .green : visionService.fps >= 15 ? .orange : .red)
                            .monospacedDigit()
                    }
                    HStack {
                        Text("YOLO Inference")
                        Spacer()
                        Text(String(format: "%.0f ms", visionService.objectProcessingTime))
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                    HStack {
                        Text("Tracked Objects")
                        Spacer()
                        Text("\(visionService.detectionResults.count)")
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }

                Section("About") {
                    HStack {
                        Text("VisionEmoji")
                            .font(.headline)
                        Spacer()
                        Text("v1.0")
                            .foregroundColor(.secondary)
                    }
                    Text("Real-time emoji overlays using Apple Vision + YOLO")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Made by Aristides Lintzeris")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func detectionRow(_ title: String, isOn: Binding<Bool>, ms: Double?) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let ms = ms, isOn.wrappedValue, ms > 0 {
                Text(String(format: "%.0fms", ms))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }
}

#Preview {
    SettingsView(visionService: VisionService(), overlayService: EmojiOverlayService())
}
