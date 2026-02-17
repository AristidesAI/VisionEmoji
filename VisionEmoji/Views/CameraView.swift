//
//  CameraView.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @ObservedObject var cameraService: CameraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        // Find current window scene for frame
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            view.frame = windowScene.screen.bounds
        }
        
        if let previewLayer = cameraService.previewLayer {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraService.previewLayer {
            if previewLayer.superlayer == nil {
                previewLayer.frame = uiView.bounds
                uiView.layer.addSublayer(previewLayer)
            }
            
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
}

#Preview {
    CameraView(cameraService: CameraService())
}
