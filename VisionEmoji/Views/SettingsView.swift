//
//  SettingsView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var visionService: VisionService
    @StateObject private var overlayService = EmojiOverlayService()
    
    var body: some View {
        NavigationView {
            if #available(iOS 26, *) {
                glassSettingsContent
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
            } else {
                fallbackSettingsContent
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.large)
            }
        }
    }
    
    @available(iOS 26, *)
    private var glassSettingsContent: some View {
        ScrollView {
            GlassEffectContainer(spacing: 20) {
                VStack(spacing: 24) {
                    // Detection Settings Section
                    detectionSection
                    
                    // Overlay Settings Section
                    overlaySection
                    
                    // Performance Settings Section
                    performanceSection
                    
                    // About Section
                    aboutSection
                }
                .padding()
            }
            .padding()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    private var fallbackSettingsContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Detection Settings Section
                detectionSectionFallback
                
                // Overlay Settings Section
                overlaySectionFallback
                
                // Performance Settings Section
                performanceSectionFallback
                
                // About Section
                aboutSectionFallback
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // MARK: - Detection Settings
    @available(iOS 26, *)
    private var detectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detection Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                detectionToggle("Face Detection", isOn: $visionService.isFaceDetectionEnabled, emoji: "😊")
                detectionToggle("Hand Gestures", isOn: $visionService.isHandGestureDetectionEnabled, emoji: "👋")
                detectionToggle("Buildings", isOn: $visionService.isBuildingDetectionEnabled, emoji: "🏢")
                detectionToggle("Cars", isOn: $visionService.isCarDetectionEnabled, emoji: "🚗")
                detectionToggle("Objects", isOn: $visionService.isObjectDetectionEnabled, emoji: "📱")
            }
        }
    }
    
    private var detectionSectionFallback: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detection Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                detectionToggleFallback("Face Detection", isOn: $visionService.isFaceDetectionEnabled, emoji: "😊")
                detectionToggleFallback("Hand Gestures", isOn: $visionService.isHandGestureDetectionEnabled, emoji: "👋")
                detectionToggleFallback("Buildings", isOn: $visionService.isBuildingDetectionEnabled, emoji: "🏢")
                detectionToggleFallback("Cars", isOn: $visionService.isCarDetectionEnabled, emoji: "🚗")
                detectionToggleFallback("Objects", isOn: $visionService.isObjectDetectionEnabled, emoji: "📱")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    @available(iOS 26, *)
    private func detectionToggle(_ title: String, isOn: Binding<Bool>, emoji: String) -> some View {
        HStack {
            Text(emoji)
                .font(.title2)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }
    
    private func detectionToggleFallback(_ title: String, isOn: Binding<Bool>, emoji: String) -> some View {
        HStack {
            Text(emoji)
                .font(.title2)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }
    
    // MARK: - Overlay Settings
    @available(iOS 26, *)
    private var overlaySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overlay Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                sliderControl("Size", value: Binding(
                    get: { Double(overlayService.overlaySettings.scaleMultiplier) },
                    set: { overlayService.overlaySettings.scaleMultiplier = CGFloat($0) }
                ), range: 0.5...2.0)
                sliderControl("Opacity", value: Binding(
                    get: { Double(overlayService.overlaySettings.maxOpacity) },
                    set: { overlayService.overlaySettings.maxOpacity = Float($0) }
                ), range: 0.2...1.0)
                sliderControl("Smoothing", value: $overlayService.overlaySettings.smoothingFactor, range: 0.0...1.0)
                
                toggleControl("Animations", isOn: $overlayService.overlaySettings.showAnimations)
                toggleControl("Pulse Effect", isOn: $overlayService.overlaySettings.enablePulse)
            }
        }
    }
    
    private var overlaySectionFallback: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overlay Settings")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                sliderControlFallback("Size", value: Binding(
                    get: { Double(overlayService.overlaySettings.scaleMultiplier) },
                    set: { overlayService.overlaySettings.scaleMultiplier = CGFloat($0) }
                ), range: 0.5...2.0)
                sliderControlFallback("Opacity", value: Binding(
                    get: { Double(overlayService.overlaySettings.maxOpacity) },
                    set: { overlayService.overlaySettings.maxOpacity = Float($0) }
                ), range: 0.2...1.0)
                sliderControlFallback("Smoothing", value: $overlayService.overlaySettings.smoothingFactor, range: 0.0...1.0)
                
                toggleControlFallback("Animations", isOn: $overlayService.overlaySettings.showAnimations)
                toggleControlFallback("Pulse Effect", isOn: $overlayService.overlaySettings.enablePulse)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    @available(iOS 26, *)
    private func sliderControl(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(.white)
                .font(.subheadline)
            
            HStack {
                Slider(value: value, in: range)
                    .accentColor(.blue)
                
                Text(String(format: "%.1f", value.wrappedValue))
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(width: 30)
            }
        }
    }
    
    private func sliderControlFallback(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundColor(.primary)
                .font(.subheadline)
            
            HStack {
                Slider(value: value, in: range)
                    .accentColor(.blue)
                
                Text(String(format: "%.1f", value.wrappedValue))
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .frame(width: 30)
            }
        }
    }
    
    @available(iOS 26, *)
    private func toggleControl(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }
    
    private func toggleControlFallback(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
    }
    
    // MARK: - Performance Settings
    @available(iOS 26, *)
    private var performanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                performanceRow("Frame Rate", value: "30 FPS")
                performanceRow("Processing", value: visionService.isProcessing ? "Active" : "Idle")
                performanceRow("Detections", "\(visionService.detectionResults.count)")
            }
        }
    }
    
    private var performanceSectionFallback: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                performanceRowFallback("Frame Rate", value: "30 FPS")
                performanceRowFallback("Processing", value: visionService.isProcessing ? "Active" : "Idle")
                performanceRowFallback("Detections", "\(visionService.detectionResults.count)")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    @available(iOS 26, *)
    private func performanceRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    private func performanceRowFallback(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - About Section
    @available(iOS 26, *)
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("VisionEmoji")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Real-time emoji overlays using Vision framework")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var aboutSectionFallback: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("VisionEmoji")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Real-time emoji overlays using Vision framework")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SettingsView(visionService: VisionService())
}
