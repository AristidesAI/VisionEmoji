//
//  CameraService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import Foundation
import AVFoundation
import UIKit
import Combine

class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isRunning = false
    @Published var captureSession: AVCaptureSession?
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var error: CameraError?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    @Published var currentCamera: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
    @Published var cameraPosition: AVCaptureDevice.Position = .back
    
    private var videoInput: AVCaptureDeviceInput?
    
    // Frame processing callback
    var onFrameProcessed: ((CVPixelBuffer) -> Void)?
    
    enum CameraError: LocalizedError {
        case notAuthorized
        case configurationFailed
        case sessionRuntimeError
        
        var errorDescription: String? {
            switch self {
            case .notAuthorized:
                return "Camera access not authorized"
            case .configurationFailed:
                return "Failed to configure camera session"
            case .sessionRuntimeError:
                return "Camera session runtime error"
            }
        }
    }
    
    override init() {
        super.init()
        checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            isAuthorized = false
            error = .notAuthorized
        @unknown default:
            isAuthorized = false
            error = .notAuthorized
        }
    }
    
    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if !granted {
                    self?.error = .notAuthorized
                }
            }
        }
    }
    
    func configureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession == nil {
                self.captureSession = AVCaptureSession()
            }
            
            guard let session = self.captureSession else { return }
            session.beginConfiguration()
            
            // Remove existing input if any
            if let videoInput = self.videoInput {
                session.removeInput(videoInput)
            }
            
            // Set session preset
            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            }
            
            // Add video input based on current settings
            let device = AVCaptureDevice.default(self.currentCamera, for: .video, position: self.cameraPosition) ?? 
                         AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            
            guard let videoDevice = device,
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  session.canAddInput(videoInput) else {
                DispatchQueue.main.async {
                    self.error = .configurationFailed
                }
                return
            }
            
            session.addInput(videoInput)
            self.videoInput = videoInput
            
            // Add video output if not already added
            if session.outputs.isEmpty {
                self.videoOutput.setSampleBufferDelegate(self, queue: self.videoOutputQueue)
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
                ]
                
                if session.canAddOutput(self.videoOutput) {
                    session.addOutput(self.videoOutput)
                }
            }
            
            session.commitConfiguration()
            
            DispatchQueue.main.async {
                // Create preview layer if not already created
                if self.previewLayer == nil {
                    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer.videoGravity = .resizeAspectFill
                    self.previewLayer = previewLayer
                }
            }
        }
    }
    
    func switchCamera(to deviceType: AVCaptureDevice.DeviceType, position: AVCaptureDevice.Position) {
        self.currentCamera = deviceType
        self.cameraPosition = position
        configureSession()
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let session = self.captureSession else { return }
            
            if !session.isRunning {
                session.startRunning()
                DispatchQueue.main.async {
                    self.isRunning = true
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let session = self.captureSession else { return }
            
            if session.isRunning {
                session.stopRunning()
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }
    
    func updatePreviewLayerOrientation(_ orientation: UIDeviceOrientation) {
        guard let previewLayer = previewLayer,
              let connection = previewLayer.connection else { return }
        
        if connection.isVideoOrientationSupported {
            switch orientation {
            case .portrait:
                connection.videoOrientation = .portrait
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                connection.videoOrientation = .landscapeLeft
            case .landscapeRight:
                connection.videoOrientation = .landscapeRight
            default:
                connection.videoOrientation = .portrait
            }
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process frame on main thread for Vision framework
        DispatchQueue.main.async { [weak self] in
            self?.onFrameProcessed?(pixelBuffer)
        }
    }
}
