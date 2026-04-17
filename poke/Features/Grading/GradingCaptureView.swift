import SwiftUI
import Inject

struct GradingCaptureView: View {
    @ObserveInjection var inject
    @Bindable var viewModel: GradingViewModel
    @Environment(Router.self) private var router

    var body: some View {
        ZStack {
            // Camera feed
            ScannerCameraPreview(session: viewModel.cameraService.captureSession)
                .ignoresSafeArea()
                .onTapGesture {
                    if viewModel.phase == .capturing {
                        viewModel.capture()
                    }
                }

            // Capture flash
            if viewModel.showCaptureFlash {
                Color.white
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Viewfinder overlay
            if viewModel.phase == .capturing {
                viewfinderOverlay
                    .allowsHitTesting(false)
            }

            // Review overlay
            if viewModel.phase == .reviewing,
               let image = viewModel.capturedImages[viewModel.currentStep] {
                reviewOverlay(image: image)
            }

            // Top bar
            topBar

            // Bottom controls
            VStack {
                Spacer()
                bottomControls
            }

            // Permission denied
            if viewModel.cameraService.permissionDenied {
                permissionDeniedView
            }
        }
        .enableInjection()
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                // Close
                Button {
                    viewModel.teardown()
                    router.dismissFullscreenCover()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }

                Spacer()

                // Step counter
                Text("\(viewModel.currentStepIndex + 1) of \(viewModel.allSteps.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

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

            // Progress dots
            progressDots
                .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.allSteps) { step in
                let isCurrent = step == viewModel.currentStep
                let isCaptured = viewModel.capturedImages[step] != nil

                Capsule()
                    .fill(dotColor(isCurrent: isCurrent, isCaptured: isCaptured))
                    .frame(width: isCurrent ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: isCurrent)
            }
        }
    }

    private func dotColor(isCurrent: Bool, isCaptured: Bool) -> Color {
        if isCurrent { return theme.accent }
        if isCaptured { return theme.accent.opacity(0.5) }
        return .white.opacity(0.3)
    }

    // MARK: - Viewfinder Overlay

    private var viewfinderOverlay: some View {
        GeometryReader { geo in
            let cutout = viewModel.currentStep.viewfinderStyle.cutoutRect(in: geo.size)

            ZStack {
                // Blurred dark overlay with cutout
                darkOverlay(fullSize: geo.size, cutout: cutout)

                // Corner brackets
                cornerBracket(rotation: 0)
                    .position(x: cutout.minX + 12, y: cutout.minY + 12)
                cornerBracket(rotation: 90)
                    .position(x: cutout.maxX - 12, y: cutout.minY + 12)
                cornerBracket(rotation: 180)
                    .position(x: cutout.maxX - 12, y: cutout.maxY - 12)
                cornerBracket(rotation: 270)
                    .position(x: cutout.minX + 12, y: cutout.maxY - 12)

                // Angled guide lines
                if viewModel.currentStep.viewfinderStyle == .angledCard {
                    angledGuideLines(in: cutout)
                }

                // Step instruction — centered in the cutout like "Tap Anywhere to Scan"
                VStack(spacing: 6) {
                    Text(viewModel.currentStep.instruction)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)

                    if !viewModel.currentStep.isRequired {
                        Text("Optional")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: cutout.width - 24)
                .position(x: cutout.midX, y: cutout.midY)
            }
            .onAppear {
                viewModel.screenSize = geo.size
                viewModel.cropRect = cutout
            }
            .onChange(of: geo.size) { _, newSize in
                viewModel.screenSize = newSize
                viewModel.cropRect = viewModel.currentStep.viewfinderStyle.cutoutRect(in: newSize)
            }
            .onChange(of: viewModel.currentStepIndex) { _, _ in
                viewModel.cropRect = viewModel.currentStep.viewfinderStyle.cutoutRect(in: geo.size)
            }
        }
        .ignoresSafeArea()
    }

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

    private func angledGuideLines(in rect: CGRect) -> some View {
        Canvas { context, _ in
            // Draw diagonal tilt indicator lines
            var path = Path()
            let inset: CGFloat = 20
            // Left tilt line
            path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY - inset))
            path.addLine(to: CGPoint(x: rect.minX + inset + 15, y: rect.minY + inset))
            // Right tilt line
            path.move(to: CGPoint(x: rect.maxX - inset, y: rect.maxY - inset))
            path.addLine(to: CGPoint(x: rect.maxX - inset - 15, y: rect.minY + inset))

            context.stroke(
                path,
                with: .color(.white.opacity(0.3)),
                style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Review Overlay

    private func reviewOverlay(image: UIImage) -> some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Captured image preview
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 32)
                    .shadow(radius: 20)

                Text(viewModel.currentStep.title)
                    .font(.headline)
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.retake()
                        }
                    } label: {
                        Label("Retake", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                    }

                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            viewModel.nextStep()
                        }
                    } label: {
                        Label(
                            viewModel.isLastStep ? "Submit" : "Next",
                            systemImage: viewModel.isLastStep ? "checkmark" : "arrow.right"
                        )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(theme.accent)
                            .clipShape(Capsule())
                    }
                }

                Spacer()
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
            if viewModel.phase == .capturing {
                // Zoom pills
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

                HStack(spacing: 20) {
                    // Back button
                    if viewModel.currentStepIndex > 0 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.previousStep()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                    } else {
                        Spacer().frame(width: 44)
                    }

                    Spacer()

                    // Skip button (optional steps)
                    if !viewModel.currentStep.isRequired {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                viewModel.skipStep()
                            }
                        } label: {
                            Text("Skip")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.white.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.white.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }

                    // Submit early (after required steps done)
                    if viewModel.requiredStepsDone && !viewModel.currentStep.isRequired {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.submitEarly()
                            }
                        } label: {
                            Text("Submit")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(theme.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 40)
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
            Text("Grant camera access in Settings to grade cards.")
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
