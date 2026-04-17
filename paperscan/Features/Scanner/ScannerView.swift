import SwiftUI
import Inject
import SwiftData
import PhotosUI

struct ScannerView: View {
    @ObserveInjection var inject
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router

    @State private var viewModel = ScannerViewModel()
    @State private var showSheet = true
    @State private var selectedPhotos: [PhotosPickerItem] = []

    var body: some View {
        ZStack {
            // Camera feed
            ScannerCameraPreview(session: viewModel.cameraService.captureSession)
                .ignoresSafeArea()
                .onTapGesture {
                    guard !viewModel.scanStore.isAtCapacity else {
                        showCapacityAlert = true
                        return
                    }
                    viewModel.captureWithImmediateFeedback()
                }

            // Capture flash overlay
            if viewModel.showCaptureFlash {
                Color.white
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Viewfinder guides
            viewfinderGuides
                .allowsHitTesting(false)

            // Top bar
            topBar

            // Zoom controls
            VStack {
                Spacer()
                zoomPills
                    .padding(.bottom, 130) // above sheet peek
            }

            // Permission denied overlay
            if viewModel.cameraService.permissionDenied {
                permissionDeniedView
            }
        }
        .sheet(isPresented: $showSheet) {
            RecentScansSheet(scanStore: viewModel.scanStore)
            .presentationDetents([.height(120), .medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
            .interactiveDismissDisabled()
        }
        .alert("Session Full", isPresented: $showCapacityAlert) {
            Button("OK") {}
        } message: {
            Text("Add or clear cards before scanning more.")
        }
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }
        .onDisappear {
            viewModel.teardown()
        }
        .onChange(of: selectedPhotos) { _, items in
            guard !items.isEmpty else { return }
            let captured = items
            selectedPhotos = []
            Task {
                for item in captured {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.importFromGallery(image)
                        try? await Task.sleep(for: .milliseconds(200))
                    }
                }
            }
        }
        .statusBarHidden()
        .enableInjection()
    }

    @State private var showCapacityAlert = false

    // MARK: - Top Bar

    private var topBar: some View {
        VStack {
            HStack {
                // Close button
                Button {
                    showSheet = false
                    viewModel.teardown()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        router.dismissFullscreenCover()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Gallery import
                PhotosPicker(selection: $selectedPhotos, matching: .images) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                // Flash toggle
                Button {
                    viewModel.cameraService.toggleFlash()
                } label: {
                    Image(systemName: viewModel.cameraService.isFlashOn ? "bolt.fill" : "bolt.slash")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .background(
                LinearGradient(colors: [.black.opacity(0.5), .clear], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            )

            Spacer()
        }
    }

    // MARK: - Viewfinder Guides + Dark Overlay

    private var viewfinderGuides: some View {
        // Use ignoresSafeArea so coordinates match the camera preview exactly
        GeometryReader { geo in
            let w: CGFloat = geo.size.width * 0.78
            let h: CGFloat = w * 1.4 // card aspect ratio ~1:1.4
            let x = (geo.size.width - w) / 2
            let y = (geo.size.height - h) / 2 // centered vertically
            let cardRect = CGRect(x: x, y: y, width: w, height: h)

            ZStack {
                // Blurred overlay with cutout
                darkOverlay(fullSize: geo.size, cutout: cardRect)

                // Corner brackets — offset by half frame so vertex sits on border
                cornerBracket(rotation: 0)
                    .position(x: cardRect.minX + 12, y: cardRect.minY + 12)
                cornerBracket(rotation: 90)
                    .position(x: cardRect.maxX - 12, y: cardRect.minY + 12)
                cornerBracket(rotation: 180)
                    .position(x: cardRect.maxX - 12, y: cardRect.maxY - 12)
                cornerBracket(rotation: 270)
                    .position(x: cardRect.minX + 12, y: cardRect.maxY - 12)

                // Tap hint — always visible, centered in crop area
                Text("Tap Anywhere to Scan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.5))
                    .clipShape(Capsule())
                    .position(x: cardRect.midX, y: cardRect.midY)
            }
            .onAppear {
                viewModel.screenSize = geo.size
                viewModel.cropRect = cardRect
            }
            .onChange(of: geo.size) { _, newSize in
                viewModel.screenSize = newSize
                let newW = newSize.width * 0.78
                let newH = newW * 1.4
                let newX = (newSize.width - newW) / 2
                let newY = (newSize.height - newH) / 2 // centered
                viewModel.cropRect = CGRect(x: newX, y: newY, width: newW, height: newH)
            }
        }
        .ignoresSafeArea()
    }

    /// Solid dark overlay with a transparent cutout for the card area.
    private func darkOverlay(fullSize: CGSize, cutout: CGRect) -> some View {
        Rectangle()
            .fill(.black.opacity(0.55))
            .mask(
                Canvas { context, size in
                    context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
                    context.blendMode = .destinationOut
                    context.fill(Path(cutout), with: .color(.white))
                }
                .compositingGroup()
            )
    }

    private func cornerBracket(rotation: Double) -> some View {
        Canvas { context, _ in
            let len: CGFloat = 26
            var path = Path()
            path.move(to: CGPoint(x: 0, y: len))
            path.addLine(to: .zero)
            path.addLine(to: CGPoint(x: len, y: 0))
            context.stroke(
                path,
                with: .color(theme.scannerBracket),
                style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: 26, height: 26)
        .rotationEffect(.degrees(rotation))
    }

    // MARK: - Zoom Pills

    private var zoomPills: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.zoomLevels, id: \.self) { level in
                Button {
                    viewModel.setZoom(level)
                } label: {
                    Text("\(Int(level))×")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 30)
                        .background(
                            viewModel.selectedZoom == level
                                ? Color.white.opacity(0.3)
                                : Color.black.opacity(0.4)
                        )
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Permission Denied

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)
            Text("Camera access is required.")
                .font(.headline)
                .foregroundColor(.white)
            Text("Grant camera access in Settings to scan cards.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
        .ignoresSafeArea()
    }
}
