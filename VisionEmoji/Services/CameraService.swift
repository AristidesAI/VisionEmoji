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

<<<<<<< HEAD
@Observable
@MainActor
final class CameraService {
    // MARK: - Properties
    var isAuthorized = false
    var cameraPosition: AVCaptureDevice.Position = .back
    var availableCameras: [CameraDescriptor] = []
    var currentCameraIndex: Int = 0

    // MARK: - Private Properties
    nonisolated(unsafe) private(set) var session = AVCaptureSession()
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private let sessionQueue = DispatchQueue(label: "com.visionemoji.camera.session")
    nonisolated(unsafe) private let videoOutputQueue = DispatchQueue(label: "com.visionemoji.camera.video", qos: .userInteractive)
    nonisolated(unsafe) private let delegate: CameraDelegate
    nonisolated(unsafe) private var currentDevice: AVCaptureDevice?

    // MARK: - Initialization

    init() {
        self.delegate = CameraDelegate()
        discoverCameras()
        checkPermissions()
    }

    // MARK: - Camera Discovery

    private func discoverCameras() {
        let discovery = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
            mediaType: .video,
            position: .unspecified
        )

        var cameras: [CameraDescriptor] = []

        // Front cameras first
        for device in discovery.devices where device.position == .front {
            cameras.append(CameraDescriptor(
                id: device.uniqueID,
                deviceType: device.deviceType,
                position: device.position
            ))
        }

        // Back cameras: ultrawide (preferred) → wide → telephoto
        let backOrder: [AVCaptureDevice.DeviceType] = [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera]
        for targetType in backOrder {
            for device in discovery.devices where device.position == .back && device.deviceType == targetType {
                cameras.append(CameraDescriptor(
                    id: device.uniqueID,
                    deviceType: device.deviceType,
                    position: device.position
                ))
            }
        }

        availableCameras = cameras

        // Default to ultrawide camera, fallback to wide
        if let ultrawideIndex = cameras.firstIndex(where: { $0.position == .back && $0.deviceType == .builtInUltraWideCamera }) {
            currentCameraIndex = ultrawideIndex
        } else if let backWideIndex = cameras.firstIndex(where: { $0.position == .back && $0.deviceType == .builtInWideAngleCamera }) {
            currentCameraIndex = backWideIndex
        }
    }

    // MARK: - Public Methods

=======
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
    
>>>>>>> parent of b614d2fa (1.0)
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
<<<<<<< HEAD

    func configureSession(onFrameProcessed: @escaping (CVPixelBuffer) -> Void) {
        delegate.onFrameProcessed = onFrameProcessed

        let cameraIndex = currentCameraIndex
        let cameras = availableCameras

        sessionQueue.async { [weak self, session, videoOutput, delegate] in
=======
    
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
>>>>>>> parent of b614d2fa (1.0)
            guard let self = self else { return }
            
            if self.captureSession == nil {
                self.captureSession = AVCaptureSession()
            }
            
            guard let session = self.captureSession else { return }
            session.beginConfiguration()
<<<<<<< HEAD

            if session.canSetSessionPreset(.inputPriority) {
                session.sessionPreset = .inputPriority
            }

            // Use discovered camera (ultrawide preferred)
            if cameraIndex < cameras.count {
                let cam = cameras[cameraIndex]
                Self.setupVideoInput(session: session, deviceType: cam.deviceType, position: cam.position, service: self)
            } else {
                Self.setupVideoInput(session: session, deviceType: .builtInUltraWideCamera, position: .back, service: self)
            }

            Self.setupVideoOutput(session: session, videoOutput: videoOutput, delegate: delegate, queue: self.videoOutputQueue)

=======
            
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
            
>>>>>>> parent of b614d2fa (1.0)
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
<<<<<<< HEAD

    func startSession() {
        sessionQueue.async { [session] in
            guard !session.isRunning else { return }
            session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async { [session] in
            guard session.isRunning else { return }
            session.stopRunning()
        }
    }

    // MARK: - Private Methods

    private static func setupVideoInput(
        session: AVCaptureSession,
        deviceType: AVCaptureDevice.DeviceType,
        position: AVCaptureDevice.Position,
        service: CameraService
    ) {
        guard let device = AVCaptureDevice.default(deviceType, for: .video, position: position) else {
            // Fallback to any wide camera at this position
            guard let fallback = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
                print("Failed to get camera device for \(deviceType) at position: \(position)")
                return
            }
            setupDevice(fallback, session: session, service: service)
            return
        }
        setupDevice(device, session: session, service: service)
    }

    private static func setupDevice(_ device: AVCaptureDevice, session: AVCaptureSession, service: CameraService) {
        do {
            try device.lockForConfiguration()

            if let format = device.formats.first(where: { format in
                let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                return dimensions.width == 1920 && dimensions.height == 1080
            }) {
                device.activeFormat = format
                let targetFrameRate = 30
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(targetFrameRate))
            }

            device.unlockForConfiguration()

            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            service.currentDevice = device

        } catch {
            print("Error configuring camera: \(error.localizedDescription)")
        }
    }

    private static func setupVideoOutput(
        session: AVCaptureSession,
        videoOutput: AVCaptureVideoDataOutput,
        delegate: AVCaptureVideoDataOutputSampleBufferDelegate,
        queue: DispatchQueue
    ) {
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
=======
    
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
>>>>>>> parent of b614d2fa (1.0)
                connection.videoOrientation = .portrait
            }
        }
    }
}

<<<<<<< HEAD
// MARK: - CameraDelegate

private final class CameraDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    var onFrameProcessed: ((CVPixelBuffer) -> Void)?

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        Task { @MainActor in
            await self.onFrameProcessed?(pixelBuffer)
=======
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process frame on main thread for Vision framework
        DispatchQueue.main.async { [weak self] in
            self?.onFrameProcessed?(pixelBuffer)
>>>>>>> parent of b614d2fa (1.0)
        }
    }
}
