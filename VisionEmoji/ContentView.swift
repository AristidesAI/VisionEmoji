//
//  ContentView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI
import Combine
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var visionService = VisionService()
    @StateObject private var emojiOverlayService = EmojiOverlayService()
    
    @State private var selectedTab = 0
    @State private var showSettingsMenu = false
<<<<<<< HEAD
    @State private var isLoading = true

=======
    
    // Performance optimization: Pre-warm the settings view
    private var settingsView: some View {
        SettingsOverlayView(visionService: visionService, overlayService: emojiOverlayService)
    }
    
>>>>>>> parent of b614d2fa (1.0)
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Camera Tab
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
                
                // Settings Tab (Trigger for Overlay)
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
                    selectedTab = 0 // Keep on camera tab
                }
            }
<<<<<<< HEAD

            // Reprocess Button
=======
            
            // Camera Switcher Button (Bottom Left)
>>>>>>> parent of b614d2fa (1.0)
            VStack {
                Spacer()
                HStack {
                    Button(action: {
<<<<<<< HEAD
                        visionService.unloadAndReload()
                        emojiOverlayService.resetOverlays()
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                            Text("Reload")
                                .font(.system(size: 8, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
=======
                        cycleCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
>>>>>>> parent of b614d2fa (1.0)
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 60) // Adjusted to be above the tab bar but not too high
                    Spacer()
                }
            }

            // Loading overlay
            if isLoading {
                Color.black
                    .ignoresSafeArea()
                    .overlay {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.5)
                    }
                    .transition(.opacity)
                    .zIndex(100)
            }
        }
        .onChange(of: visionService.fps) { _, newFPS in
            if newFPS > 0 && isLoading {
                withAnimation(.easeOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
        .sheet(isPresented: $showSettingsMenu) {
            settingsView
                .presentationDetents([.medium, .large])
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
        }
        .onAppear {
            // Preload essential emojis when app launches
            EmojiAssetService.shared.preloadEssentialEmojis()
        }
    }
<<<<<<< HEAD
=======
    
    private func cycleCamera() {
        if cameraService.cameraPosition == .back {
            cameraService.switchCamera(to: .builtInWideAngleCamera, position: .front)
        } else {
            cameraService.switchCamera(to: .builtInWideAngleCamera, position: .back)
        }
    }
>>>>>>> parent of b614d2fa (1.0)
}

struct SettingsOverlayView: View {
    @ObservedObject var visionService: VisionService
    @ObservedObject var overlayService: EmojiOverlayService
    
    var body: some View {
        NavigationView {
            Form {
<<<<<<< HEAD
                Section("Classification") {
                    taskRow("Per-Object Classification", isOn: $visionService.isClassificationEnabled,
                            ms: visionService.classifyProcessingTime)

                    if visionService.isClassificationEnabled {
                        sliderRow("Cls Confidence", value: $visionService.classificationConfidenceThreshold,
                                  range: 0.1...0.9, step: 0.05,
                                  format: "%.0f%%", multiplier: 100)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Label Priority")
                                Spacer()
                                Text(labelPriorityDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: $visionService.labelPriority, in: 0.0...1.0, step: 0.1)
                        }
                    }
                }

                Section("Detection") {
                    sliderRow("Confidence", value: $visionService.confidenceThreshold,
                              range: 0.1...0.9, step: 0.05,
                              format: "%.0f%%", multiplier: 100)

                    sliderRow("Max Detections",
                              intValue: $visionService.maxDetections,
                              range: 10...100, step: 10)
                }

                Section("Display") {
                    Toggle("Emoji", isOn: Binding(
                        get: { overlayService.overlaySettings.displayMode == .emoji },
                        set: { newValue in
                            if newValue {
                                overlayService.overlaySettings.displayMode = .emoji
                            } else {
                                overlayService.overlaySettings.displayMode = .debug
                            }
                        }
                    ))

                    Toggle("Debug", isOn: Binding(
                        get: { overlayService.overlaySettings.displayMode == .debug },
                        set: { newValue in
                            if newValue {
                                overlayService.overlaySettings.displayMode = .debug
                            } else {
                                overlayService.overlaySettings.displayMode = .emoji
                            }
                        }
                    ))

                    sliderRow("Emoji Scale", value: $overlayService.overlaySettings.emojiScale,
                              range: 0.3...1.0, step: 0.05,
                              format: "%.0f%%", multiplier: 100)

                    sliderRow("Y Offset", value: $overlayService.overlaySettings.overlayYOffset,
                              range: -100.0...100.0, step: 5.0, format: "%.0f pt")

                    Toggle("Kalman Smoothing", isOn: $overlayService.overlaySettings.enableKalmanFilter)

                    if overlayService.overlaySettings.enableKalmanFilter {
                        sliderRow("Process Noise", value: $overlayService.overlaySettings.kalmanProcessNoise,
                                  range: 0.001...0.1, step: 0.001, format: "%.3f")

                        sliderRow("Measurement Noise", value: $overlayService.overlaySettings.kalmanMeasurementNoise,
                                  range: 0.001...0.1, step: 0.001, format: "%.3f")
                    } else {
                        sliderRow("Smoothing", value: $overlayService.overlaySettings.smoothingFactor,
                                  range: 0.1...0.95, step: 0.05, format: "%.2f")
                    }
                }

                Section("Processing") {
                    sliderRow("Target FPS",
                              intValue: $visionService.targetFPS,
                              range: 5...60, step: 5)
                }

                Section {
                    metricRow("FPS", value: String(format: "%.0f", visionService.fps),
                              color: visionService.fps >= 25 ? .green : visionService.fps >= 15 ? .orange : .red)
                    metricRow("Detection", value: String(format: "%.0f ms", visionService.objectProcessingTime))
                    if visionService.isClassificationEnabled {
                        metricRow("Classification", value: String(format: "%.0f ms", visionService.classifyProcessingTime))
                        metricRow("Cls Cached", value: "\(visionService.classificationsCached)")
=======
                Section("Detection Types") {
                    Toggle("Faces", isOn: $visionService.isFaceDetectionEnabled)
                    Toggle("Hands", isOn: $visionService.isHandGestureDetectionEnabled)
                    Toggle("Buildings", isOn: $visionService.isBuildingDetectionEnabled)
                    Toggle("Cars", isOn: $visionService.isCarDetectionEnabled)
                    Toggle("Objects", isOn: $visionService.isObjectDetectionEnabled)
                }
                
                Section("Visuals") {
                    Toggle("Animated Emojis", isOn: $overlayService.overlaySettings.showAnimations)
                    Toggle("Show Vision Tracking Layer", isOn: $overlayService.overlaySettings.showTrackingLayer)
                }
                
                Section("Performance") {
                    Slider(value: $overlayService.overlaySettings.smoothingFactor, in: 0...1) {
                        Text("Smoothing")
                    } minimumValueLabel: {
                        Text("Off")
                    } maximumValueLabel: {
                        Text("High")
>>>>>>> parent of b614d2fa (1.0)
                    }
                    metricRow("Tracked", value: "\(visionService.detectionResults.count)")
                } header: {
                    Text("Performance")
                } footer: {
                    Text("Made by Aristides Lintzeris & YOLO26")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
<<<<<<< HEAD

    private var labelPriorityDescription: String {
        let val = visionService.labelPriority
        if val < 0.3 { return "YOLO" }
        if val > 0.7 { return "ImageNet" }
        return String(format: "%.1f", val)
    }

    private func taskRow(_ title: String, isOn: Binding<Bool>, ms: Double?) -> some View {
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
        .contentShape(Rectangle())
        .onTapGesture {
            isOn.wrappedValue.toggle()
        }
    }

    private func metricRow(_ label: String, value: String, color: Color = .secondary) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(color)
                .monospacedDigit()
        }
    }

    private func sliderRow(_ title: String, value: Binding<Double>,
                           range: ClosedRange<Double>, step: Double,
                           format: String, multiplier: Double = 1) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue * multiplier))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func sliderRow(_ title: String, value: Binding<Float>,
                           range: ClosedRange<Float>, step: Float,
                           format: String, multiplier: Float = 1) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: format, value.wrappedValue * multiplier))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func sliderRow(_ title: String, intValue: Binding<Int>,
                           range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                Spacer()
                Text("\(intValue.wrappedValue)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: Binding(
                get: { Double(intValue.wrappedValue) },
                set: { intValue.wrappedValue = Int($0) }
            ), in: range, step: step)
        }
    }
=======
>>>>>>> parent of b614d2fa (1.0)
}

struct CameraTabView: View {
    @ObservedObject var cameraService: CameraService
    @ObservedObject var visionService: VisionService
    @ObservedObject var overlayService: EmojiOverlayService
    
    @State private var viewSize = CGSize.zero
    @State private var showingPermissionAlert = false
    
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if cameraService.isAuthorized {
                    // Camera preview
                    CameraView(cameraService: cameraService)
                        .ignoresSafeArea()
                    
                    // Emoji overlays
                    EmojiOverlayView(
                        overlays: overlayService.overlays,
                        settings: overlayService.overlaySettings
                    )
                    .ignoresSafeArea()
<<<<<<< HEAD
                    .allowsHitTesting(false)

=======
                    
                    // Controls overlay
>>>>>>> parent of b614d2fa (1.0)
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
                let insets = geometry.safeAreaInsets
                viewSize = CGSize(
                    width: geometry.size.width,
                    height: geometry.size.height + insets.top + insets.bottom
                )
                if cameraService.isAuthorized {
                    setupServices()
                }
            }
<<<<<<< HEAD
            .onChange(of: geometry.size) { _, _ in
                let insets = geometry.safeAreaInsets
                viewSize = CGSize(
                    width: geometry.size.width,
                    height: geometry.size.height + insets.top + insets.bottom
                )
            }
            .onChange(of: cameraService.isAuthorized) { _, isAuthorized in
                if isAuthorized { setupServices() }
            }
            .onChange(of: visionService.detectionResults) { _, results in
                overlayService.updateOverlays(with: results, viewSize: viewSize)
=======
            .onChange(of: cameraService.isAuthorized) { _, isAuthorized in
                if isAuthorized {
                    setupServices()
                }
>>>>>>> parent of b614d2fa (1.0)
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
            
            // Detection status indicator
            HStack(spacing: 8) {
                Image(systemName: visionService.isProcessing ? "eye.circle.fill" : "eye.slash.circle.fill")
                    .foregroundColor(visionService.isProcessing ? .green : .red)
                Text(visionService.isProcessing ? "Active" : "Idle")
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
        // Configure and start camera session
        cameraService.configureSession()
        cameraService.startSession()
        
        // Setup camera frame processing
        cameraService.onFrameProcessed = { [weak visionService] pixelBuffer in
            visionService?.processFrame(pixelBuffer)
        }
        
        // Link camera position to vision service for optimization
        cameraService.$cameraPosition
            .sink { [weak visionService] position in
                visionService?.updateCameraPosition(isFront: position == .front)
            }
            .store(in: &cancellables)
        
        // Setup vision results processing
        visionService.$detectionResults
            .receive(on: DispatchQueue.main)
            .sink { [weak overlayService] results in
                overlayService?.updateOverlays(with: results, viewSize: viewSize)
            }
            .store(in: &cancellables)
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
