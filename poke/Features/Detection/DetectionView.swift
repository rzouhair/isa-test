//
//  DetectionView.swift
//  poke
//

import SwiftUI
import Inject
import SwiftData

struct DetectionView: View {
    @ObserveInjection var inject
    var images: [UIImage]
    @Environment(\.modelContext) private var context: ModelContext
    @Environment(Router.self) private var router: Router
    @State private var vm: ViewModel?

    var isErrorShown: Binding<Bool> {
        Binding(
            get: { vm?.isErrorModalPresented ?? false },
            set: { vm?.isErrorModalPresented = $0 }
        )
    }

    init(images: [UIImage] = []) {
        self.images = images
    }

    var body: some View {
        VStack(spacing: 0) {
            // Image preview
            VStack {
                ImageCardView(
                    frontImage: images.first ?? UIImage(),
                    backImage: images.count >= 2 ? images[1] : nil
                )
            }
            .padding(.top, 40)
            .padding(.horizontal)

            Spacer()

            // Animated progress messages
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.bottom, 20)

                if let vm = vm {
                    Text(vm.progressMessages[vm.currentMessageIndex])
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                        .id(vm.currentMessageIndex)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 40)
            .onReceive(vm?.timer ?? Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    if let vm = vm {
                        vm.currentMessageIndex = (vm.currentMessageIndex + 1) % vm.progressMessages.count
                    }
                }
            }

            Spacer()

            Text("Please keep this app open during this process")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .task {
            if vm == nil {
                vm = ViewModel(context: context, router: router, images: images)
                await vm?.detect()
            }
        }
        .alert("An error occurred", isPresented: isErrorShown) {
            Button("OK", role: .cancel) {
                router.dismissFullscreenCover()
                router.navigateToRoot()
            }
        } message: {
            Text("An unexpected error occurred while processing. Please try again.")
        }
    }
}

// MARK: - Image Card

struct ImageCardView: View {
    let frontImage: UIImage
    let backImage: UIImage?
    let flipDuration: Double = 0.8
    @State private var isFlipped = false
    @State private var flipProgress: CGFloat = 0

    var body: some View {
        ZStack {
            if let backImage {
                CardSideView(image: backImage, label: "BACK")
                    .opacity(flipProgress < 0.5 ? 0 : 1)
                    .scaleEffect(x: flipProgress < 0.5 ? -1 : 1, y: 1)
                    .rotation3DEffect(
                        .degrees(flipProgress < 0.5 ? 90 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
            }

            CardSideView(image: frontImage, label: "FRONT")
                .opacity(flipProgress < 0.5 ? 1 : 0)
                .rotation3DEffect(
                    .degrees(flipProgress < 0.5 ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: 400, height: 350)
        .task {
            guard backImage != nil else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6))
                if Task.isCancelled { return }
                withAnimation(.timingCurve(0.4, 0.8, 0.2, 1, duration: flipDuration)) {
                    isFlipped.toggle()
                    flipProgress = isFlipped ? 1 : 0
                }
            }
        }
        .onTapGesture {
            if backImage != nil {
                manualFlip()
            }
        }
    }

    private func manualFlip() {
        withAnimation(.timingCurve(0.4, 0.8, 0.2, 1, duration: flipDuration)) {
            isFlipped.toggle()
            flipProgress = isFlipped ? 1 : 0
        }
    }
}

struct CardSideView: View {
    let image: UIImage
    let label: String

    var body: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipped()
                .padding(20)

            VStack {
                HStack {
                    Text(label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(4)
                    Spacer()
                }
                Spacer()
            }
            .padding(8)
        }
        .frame(maxHeight: 350)
    }
}

#Preview {
    DetectionView(
        images: [
            UIImage.testImage(color: .green, size: CGSize(width: 200, height: 200)),
            UIImage.testImage(color: .blue, size: CGSize(width: 200, height: 200)),
        ]
    )
}
