//
//  CameraService.swift
//  VisionEmoji
//
//  Created by aristides lintzeris on 17/2/2026.
//

import Foundation
import AVFoundation
import UIKit
import Combine

@Observable
@MainActor
final class CameraService {
    // MARK: - Properties
    var isAuthorized = false
    var cameraPosition: AVCaptureDevice.Position = .back

    // MARK: - Private Properties
    nonisolated(unsafe) private(set) var session = AVCaptureSession()
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    nonisolated(unsafe) private let sessionQueue = DispatchQueue(label: "com.visionemoji.camera.session")
    nonisolated(unsafe) private let videoOutputQueue = DispatchQueue(label: "com.visionemoji.camera.video", qos: .userInteractive)
    nonisolated(unsafe) private let delegate: CameraDelegate

    // MARK: - Initialization

    init() {
        self.delegate = CameraDelegate()
        checkPermissions()
    }

    // MARK: - Public Methods

    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isAuthorized = true

        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor [weak self] in
                    self?.isAuthorized = granted
                    self?.sessionQueue.resume()
                }
            }

        case .denied, .restricted:
            self.isAuthorized = false

        @unknown default:
            self.isAuthorized = false
        }
    }

    func configureSession(onFrameProcessed: @escaping (CVPixelBuffer) -> Void) {
        delegate.onFrameProcessed = onFrameProcessed

        let position = cameraPosition

        sessionQueue.async { [weak self, session, videoOutput, delegate] in
            guard let self = self else { return }

            session.beginConfiguration()

            // Configure session preset for performance
            if session.canSetSessionPreset(.high) {
                session.sessionPreset = .high
            }

            // Add video input
            Self.setupVideoInput(session: session, position: position)

            // Configure video output
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

    func switchCamera(to deviceType: AVCaptureDevice.DeviceType, position: AVCaptureDevice.Position) {
        sessionQueue.async { [weak self, session] in
            guard let self = self else { return }

            session.beginConfiguration()

            // Remove existing inputs
            for input in session.inputs {
                session.removeInput(input)
            }

            // Add new input
            Self.setupVideoInput(session: session, position: position)

            session.commitConfiguration()

            Task { @MainActor in
                self.cameraPosition = position
            }
        }
    }

    // MARK: - Private Methods

    private static func setupVideoInput(session: AVCaptureSession, position: AVCaptureDevice.Position) {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("Failed to get camera device for position: \(position)")
            return
        }

        do {
            // Configure device for performance
            try device.lockForConfiguration()

            // Set frame rate to 30 FPS for performance
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
        // Configure video output
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]

        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(delegate, queue: queue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Set video orientation
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

        // Pass frame to VisionService
        Task { @MainActor in
            await self.onFrameProcessed?(pixelBuffer)
        }
    }
}
