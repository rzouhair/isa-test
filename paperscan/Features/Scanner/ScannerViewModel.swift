import SwiftUI
import UIKit
import SwiftData

@MainActor @Observable
final class ScannerViewModel {
    let cameraService = CameraService()
    let scanStore = ScanStore.shared
    private let analytics: AnalyticsServiceProtocol = DIContainer.shared.analyticsService

    var showCaptureFlash = false
    var selectedZoom: CGFloat = 1.0
    var sheetDetent: PresentationDetent = .height(120)

    /// Viewfinder crop rect in screen coordinates (set by ScannerView)
    var cropRect: CGRect = .zero
    /// Screen size for crop ratio calculation
    var screenSize: CGSize = .zero
    /// Current zoom factor (1x, 2x, 3x)
    var zoomFactor: CGFloat = 1.0

    let zoomLevels: [CGFloat] = [1, 2, 3]

    func setup(modelContext: ModelContext) {
        scanStore.configure(modelContext: modelContext)
        cameraService.onPhotoCaptured = { [weak self] image in
            self?.handleCapture(image)
        }
        cameraService.start()
    }

    func teardown() {
        cameraService.stop()
    }

    func setZoom(_ factor: CGFloat) {
        selectedZoom = factor
        zoomFactor = factor
        cameraService.zoomFactor = factor
    }

    /// Fires haptic + flash instantly, inserts placeholder record, THEN waits for photo.
    func captureWithImmediateFeedback() {
        analytics.capture(.scanStarted, properties: ["source": "camera"])
        // Instant feedback — before AVFoundation even starts processing
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showCaptureFlash = true
        withAnimation(.easeOut(duration: 0.1)) { showCaptureFlash = false }

        // Insert placeholder so "Identifying…" row appears immediately
        let record = scanStore.insertPending()

        // Trigger AVFoundation capture — delegate will deliver the image async
        cameraService.capturePhoto()

        // When the photo arrives, process and update the placeholder
        pendingRecord = record
    }

    /// Holds the record waiting for a photo from AVFoundation
    private var pendingRecord: ScanRecord?

    /// Import from gallery — no crop, just optimize and submit.
    func importFromGallery(_ image: UIImage) {
        analytics.capture(.scanStarted, properties: ["source": "gallery"])
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let record = scanStore.insertPending()
        Task.detached(priority: .userInitiated) { [weak self] in
            let optimized = ScannerViewModel.optimizeImage(image)
            await self?.scanStore.fulfillPending(record, image: optimized)
        }
    }

    // MARK: - Private

    private func handleCapture(_ image: UIImage) {
        guard let record = pendingRecord else { return }
        pendingRecord = nil

        let cropSnapshot = cropRect
        let sizeSnapshot = screenSize
        Task.detached(priority: .userInitiated) { [weak self] in
            let cropped = ScannerViewModel.cropImage(image, cropRect: cropSnapshot, screenSize: sizeSnapshot) ?? image
            let optimized = ScannerViewModel.optimizeImage(cropped)
            await self?.scanStore.fulfillPending(record, image: optimized)
        }
    }

    /// Crop captured photo to the viewfinder guide area.
    /// Static + nonisolated so it can run safely on a background thread.
    nonisolated static func cropImage(_ image: UIImage, cropRect: CGRect, screenSize: CGSize) -> UIImage? {
        guard cropRect != .zero, screenSize != .zero else { return nil }

        // Normalize orientation: camera photos are typically .right (sensor landscape),
        // making raw cgImage dims mismatch portrait screen coordinates.
        let oriented: UIImage
        if image.imageOrientation == .up {
            oriented = image
        } else {
            let renderer = UIGraphicsImageRenderer(size: image.size)
            oriented = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: image.size)) }
        }

        guard let cgImage = oriented.cgImage else { return nil }

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)

        // resizeAspectFill mapping: image scaled to fill screen, centered, overflow clipped.
        let screenRatio = screenSize.width / screenSize.height
        let imageRatio = imgW / imgH

        let scale: CGFloat
        let offsetX: CGFloat
        let offsetY: CGFloat

        if imageRatio > screenRatio {
            scale = imgH / screenSize.height
            offsetX = (imgW - screenSize.width * scale) / 2
            offsetY = 0
        } else {
            scale = imgW / screenSize.width
            offsetX = 0
            offsetY = (imgH - screenSize.height * scale) / 2
        }

        let pixelRect = CGRect(
            x: cropRect.origin.x * scale + offsetX,
            y: cropRect.origin.y * scale + offsetY,
            width: cropRect.width * scale,
            height: cropRect.height * scale
        ).integral

        let clampedRect = pixelRect.intersection(CGRect(x: 0, y: 0, width: imgW, height: imgH))
        guard !clampedRect.isEmpty, let cropped = cgImage.cropping(to: clampedRect) else { return nil }
        return UIImage(cgImage: cropped)
    }

    /// Resize for LLM vision (768px long edge sweet spot for card detail vs token cost).
    nonisolated static func optimizeImage(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 768
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        guard ratio < 1.0 else { return image }
        let newSize = CGSize(width: (size.width * ratio).rounded(), height: (size.height * ratio).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
