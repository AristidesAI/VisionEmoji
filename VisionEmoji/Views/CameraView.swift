//
//  CameraView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Bindable var cameraService: CameraService

    func makeUIView(context: Context) -> CameraPreviewView {
        let previewView = CameraPreviewView()
        previewView.videoPreviewLayer.session = cameraService.session
        return previewView
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Update session if needed
        uiView.videoPreviewLayer.session = cameraService.session
    }
}

/// UIView that displays the camera preview
class CameraPreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPreviewLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPreviewLayer()
    }

    private func setupPreviewLayer() {
        videoPreviewLayer.videoGravity = .resizeAspectFill
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer.frame = bounds
    }
}

#Preview {
    CameraView(cameraService: CameraService())
}
