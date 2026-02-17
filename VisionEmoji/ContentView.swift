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
    
    // Performance optimization: Pre-warm the settings view
    private var settingsView: some View {
        SettingsOverlayView(visionService: visionService, overlayService: emojiOverlayService)
    }
    
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
            
            // Camera Switcher Button (Bottom Left)
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        cycleCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.bottom, 60) // Adjusted to be above the tab bar but not too high
                    Spacer()
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
    
    private func cycleCamera() {
        if cameraService.cameraPosition == .back {
            cameraService.switchCamera(to: .builtInWideAngleCamera, position: .front)
        } else {
            cameraService.switchCamera(to: .builtInWideAngleCamera, position: .back)
        }
    }
}

struct SettingsOverlayView: View {
    @ObservedObject var visionService: VisionService
    @ObservedObject var overlayService: EmojiOverlayService
    
    var body: some View {
        NavigationView {
            Form {
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
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
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
                    
                    // Controls overlay
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
            .onChange(of: cameraService.isAuthorized) { _, isAuthorized in
                if isAuthorized {
                    setupServices()
                }
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
