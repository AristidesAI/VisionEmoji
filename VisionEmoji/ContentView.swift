//
//  ContentView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var cameraService = CameraService()
    @StateObject private var visionService = VisionService()
    @StateObject private var emojiOverlayService = EmojiOverlayService()

    @State private var selectedTab = 0
    @State private var showSettingsMenu = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                CameraTabView(
                    cameraService: cameraService,
                    visionService: visionService,
                    overlayService: emojiOverlayService
                )
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Camera")
                }
                .tag(0)

                Color.clear
                    .tabItem {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .tag(1)
            }
            .accentColor(.blue)
            .onChange(of: selectedTab) { _, newValue in
                if newValue == 1 {
                    showSettingsMenu = true
                    selectedTab = 0
                }
            }

            // Camera Switcher Button
            VStack {
                Spacer()
                HStack {
                    Button(action: { cycleCamera() }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 60)
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showSettingsMenu) {
            SettingsOverlayView(visionService: visionService, overlayService: emojiOverlayService)
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
    }

    private func cycleCamera() {
        if cameraService.cameraPosition == .back {
            cameraService.switchCamera(to: .builtInWideAngleCamera, position: .front)
        } else {
            cameraService.switchCamera(to: .builtInWideAngleCamera, position: .back)
        }
    }
}

// MARK: - Settings Overlay

struct SettingsOverlayView: View {
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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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

// MARK: - Camera Tab

struct CameraTabView: View {
    @Bindable var cameraService: CameraService
    @ObservedObject var visionService: VisionService
    @ObservedObject var overlayService: EmojiOverlayService

    @State private var viewSize = CGSize.zero
    @State private var showingPermissionAlert = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if cameraService.isAuthorized {
                    CameraView(cameraService: cameraService)
                        .ignoresSafeArea()

                    EmojiOverlayView(
                        overlays: overlayService.overlays,
                        settings: overlayService.overlaySettings
                    )
                    .ignoresSafeArea()

                    VStack {
                        Spacer()
                        controlsView
                    }
                } else {
                    PermissionRequestView {
                        cameraService.checkPermissions()
                    }
                }
            }
            .onAppear {
                viewSize = geometry.size
                if cameraService.isAuthorized {
                    setupServices()
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                viewSize = newSize
            }
            .onChange(of: cameraService.isAuthorized) { _, isAuthorized in
                if isAuthorized { setupServices() }
            }
            .onChange(of: cameraService.cameraPosition) { _, position in
                visionService.updateCameraPosition(isFront: position == .front)
            }
            .onChange(of: visionService.detectionResults) { _, results in
                overlayService.updateOverlays(with: results, viewSize: viewSize)
            }
            .alert("Camera Access Required", isPresented: $showingPermissionAlert) {
                Button("Settings", action: openSettings)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Camera access is required for VisionEmoji to detect and overlay emojis on real-time objects.")
            }
        }
    }

    private var controlsView: some View {
        HStack(spacing: 20) {
            Spacer()

            HStack(spacing: 8) {
                Image(systemName: visionService.isProcessing ? "eye.circle.fill" : "eye.slash.circle.fill")
                    .foregroundColor(visionService.isProcessing ? .green : .red)
                Text(visionService.isProcessing ? "\(visionService.detectionResults.count) tracked" : "Idle")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
        .padding()
    }

    private func setupServices() {
        cameraService.configureSession { [weak visionService] pixelBuffer in
            visionService?.processFrame(pixelBuffer)
        }
        cameraService.startSession()
    }

    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    ContentView()
}
