//
//  CameraService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 16/2/2026.
//

import Foundation
import AVFoundation
import UIKit

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

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
        case .notDetermined:
            requestPermission()
        case .denied, .restricted:
            isAuthorized = false
        @unknown default:
            isAuthorized = false
        }
    }

    private func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
            }
        }
    }

    func configureSession(onFrameProcessed: @escaping (CVPixelBuffer) -> Void) {
        delegate.onFrameProcessed = onFrameProcessed

        let cameraIndex = currentCameraIndex
        let cameras = availableCameras

        sessionQueue.async { [weak self, session, videoOutput, delegate] in
            guard let self = self else { return }

            session.beginConfiguration()

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

            session.commitConfiguration()
        }
    }

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
                connection.videoOrientation = .portrait
            }
        }
    }
}

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
            self.onFrameProcessed?(pixelBuffer)
        }
    }
}
