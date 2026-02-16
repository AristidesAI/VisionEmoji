//
//  ContentView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var visionService = VisionService()
    @StateObject private var emojiOverlayService = EmojiOverlayService()
    
    @State private var selectedTab = 0
    
    var body: some View {
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
            
            // Settings Tab
            SettingsView(visionService: visionService)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(1)
        }
        .accentColor(.blue)
        .onAppear {
            // Preload essential emojis when app launches
            EmojiAssetService.shared.preloadEssentialEmojis()
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
            .onChange(of: cameraService.isAuthorized) { isAuthorized in
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
            // Clear overlays button
            Button(action: {
                overlayService.clearOverlays()
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Detection status indicator
            Image(systemName: visionService.isProcessing ? "eye.circle.fill" : "eye.slash.circle.fill")
                .font(.title2)
                .foregroundColor(visionService.isProcessing ? .green : .red)
                .background(Color.black.opacity(0.5))
                .clipShape(Circle())
        }
        .padding()
        .background(
            // Glass effect for iOS 26+ with fallback
            Group {
                if #available(iOS 26.0, *) {
                    GlassEffectContainer {
                        HStack(spacing: 20) {
                            Button(action: {
                                overlayService.clearOverlays()
                            }) {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Image(systemName: visionService.isProcessing ? "eye.circle.fill" : "eye.slash.circle.fill")
                                .font(.title2)
                                .foregroundColor(visionService.isProcessing ? .green : .red)
                        }
                        .padding()
                    }
                } else {
                    // Fallback for earlier iOS versions
                    HStack(spacing: 20) {
                        Button(action: {
                            overlayService.clearOverlays()
                        }) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.glass)
                        
                        Spacer()
                        
                        Image(systemName: visionService.isProcessing ? "eye.circle.fill" : "eye.slash.circle.fill")
                            .font(.title2)
                            .foregroundColor(visionService.isProcessing ? .green : .red)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(15)
                }
            }
        )
    }
    
    private func setupServices() {
        // Setup camera frame processing
        cameraService.onFrameProcessed = { pixelBuffer in
            visionService.processFrame(pixelBuffer)
        }
        
        // Setup vision results processing
        visionService.$detectionResults
            .receive(on: DispatchQueue.main)
            .sink { results in
                overlayService.updateOverlays(with: results, viewSize: viewSize)
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
