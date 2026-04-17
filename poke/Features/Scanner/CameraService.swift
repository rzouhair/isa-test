import AVFoundation
import SwiftUI
import UIKit

/// Manages AVCaptureSession lifecycle for the scanner camera.
@MainActor @Observable
final class CameraService {
    private(set) var captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let captureDelegate = ScannerPhotoCaptureDelegate()

    var isFlashOn = false
    var isSessionRunning = false
    var permissionDenied = false

    /// Zoom level: 1x, 2x, 3x
    var zoomFactor: CGFloat = 1.0 {
        didSet { applyZoom() }
    }

    var onPhotoCaptured: ((UIImage) -> Void)?

    private var previewLayer: AVCaptureVideoPreviewLayer?

    func start() {
        checkPermission { [weak self] granted in
            guard let self, granted else { return }
            self.configureSession()
            Task.detached { [captureSession = self.captureSession] in
                captureSession.startRunning()
                await MainActor.run { self.isSessionRunning = true }
            }
        }
    }

    func stop() {
        guard captureSession.isRunning else { return }
        Task.detached { [captureSession = self.captureSession] in
            captureSession.stopRunning()
            await MainActor.run { self.isSessionRunning = false }
        }
    }

    func capturePhoto() {
        guard captureSession.isRunning else { return }
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(.on) {
            settings.flashMode = isFlashOn ? .on : .off
        }
        photoOutput.capturePhoto(with: settings, delegate: captureDelegate)
    }

    func toggleFlash() {
        isFlashOn.toggle()
        // For torch (continuous light) mode
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isFlashOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            print("Torch toggle failed: \(error)")
        }
    }

    // MARK: - Private

    private func configureSession() {
        guard captureSession.inputs.isEmpty else { return }
        captureSession.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input)
        else { return }

        captureSession.addInput(input)

        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.addOutput(photoOutput)
        
        // Lock to portrait for consistent preview and capture orientation
        if let captureConnection = photoOutput.connection(with: .video),
           captureConnection.isVideoOrientationSupported {
            captureConnection.videoOrientation = .portrait
        }

        captureDelegate.onCapture = { [weak self] image in
            Task { @MainActor in
                self?.onPhotoCaptured?(image)
            }
        }
    }

    private func applyZoom() {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        let clamped = min(max(zoomFactor, 1.0), device.activeFormat.videoMaxZoomFactor)
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = clamped
            device.unlockForConfiguration()
        } catch {
            print("Zoom failed: \(error)")
        }
    }

    private func checkPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionDenied = false
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.permissionDenied = !granted
                    completion(granted)
                }
            }
        default:
            permissionDenied = true
            completion(false)
        }
    }
}

// MARK: - UIViewRepresentable Camera Preview

struct ScannerCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewContainerView {
        let view = PreviewContainerView()
        view.previewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.previewLayer.session = session
    }

    /// Custom UIView that keeps the AVCaptureVideoPreviewLayer sized to bounds.
    class PreviewContainerView: UIView {
        let previewLayer = AVCaptureVideoPreviewLayer()

        override init(frame: CGRect) {
            super.init(frame: frame)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.connection?.videoOrientation = .portrait
            layer.addSublayer(previewLayer)
        }

        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = bounds
        }
    }
}

// MARK: - Photo Capture Delegate

private class ScannerPhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage) -> Void)?

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else { return }
        onCapture?(image)
    }
}
