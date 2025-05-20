//
//  BanknoteDetectionView.swift
//  paperscan
//
//  Created by user on 27/3/2025.
//

import SwiftUI
import Inject
import SwiftData

struct BanknoteDetectionView: View {
    @ObserveInjection var inject
    var images: [UIImage]
    @Environment(AIService.self) private var aiService
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
    
    var fallbackImage = UIImage.testImage(color: .green, size: CGSize(width: 200, height: 200))
    
    var body: some View {
        VStack(spacing: 0) {
            // Image Gallery
            VStack {
                // CHANGE: Safely unwrap vm and its images
                BanknoteCardView(
                    frontImage: (vm?.images.count ?? 0) >= 1 ? vm?.images[0] ?? fallbackImage : fallbackImage,
                    backImage: (vm?.images.count ?? 0) >= 2 ? vm?.images[1] ?? fallbackImage : nil
                )
            }
            .padding(.top, 40)
            .padding(.horizontal)
            
            Spacer()
            
            // Animated Progress Messages
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding(.bottom, 20)
                
                if let vm = vm {
                    Text(vm.progressMessages[vm.currentMessageIndex] ?? "Processing...")
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
            
            // Subtle Status Footer
            Text("Please keep this app open during this process")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground).ignoresSafeArea())
        .onAppear {
            vm = ViewModel(context: context, router: router, images: images)
            
            Task {
                await vm?.detectBanknotes()
            }
        }
        .alert("An error occurred", isPresented: isErrorShown) {
            Button("OK", role: .cancel) {
                router.dismissFullscreenCover()
                router.navigateToRoot()
                router.navigate(to: .home, replace: true)
            }
        } message: {
            Text("An unexpected error occurred while processing your banknotes. Please try again.")
        }
    }
}

#Preview {
    BanknoteDetectionView(
        images: [
            UIImage.testImage(color: .green, size: CGSize(width: 200, height: 200)),
            UIImage.testImage(color: .appPrimary, size: CGSize(width: 200, height: 200)),
        ]
    )
}

struct BanknoteCardView: View {
    @ObserveInjection var inject
    let frontImage: UIImage
    let backImage: UIImage?
    let flipDuration: Double = 0.8
    @State private var isFlipped = false
    @State private var flipProgress: CGFloat = 0
    
    var body: some View {
        ZStack {
            if backImage != nil {
              // Back Card (initially hidden)
              CardSide(image: backImage!, isFront: false)
                  .opacity(flipProgress < 0.5 ? 0 : 1)
                  .scaleEffect(x: flipProgress < 0.5 ? -1 : 1, y: 1)
                  .rotation3DEffect(
                      .degrees(flipProgress < 0.5 ? 90 : 0),
                      axis: (x: 0, y: 1, z: 0)
                  )
            }
            
            // Front Card
            CardSide(image: frontImage, isFront: true)
                .opacity(flipProgress < 0.5 ? 1 : 0)
                .rotation3DEffect(
                    .degrees(flipProgress < 0.5 ? 0 : -90),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(width: 400, height: 350)
        .onAppear {
            if frontImage != nil && backImage != nil {
                startAutoFlip()
            }
        }
        .onTapGesture {
            if frontImage != nil && backImage != nil {
                manualFlip()
            }
        }
    }
    
    private func startAutoFlip() {
        Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
            withAnimation(.timingCurve(0.4, 0.8, 0.2, 1, duration: flipDuration)) {
                isFlipped.toggle()
                flipProgress = isFlipped ? 1 : 0
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

struct CardSide: View {
    @ObserveInjection var inject
    let image: UIImage
    let isFront: Bool
    
    var body: some View {
        ZStack {
            // Banknote Image
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipped()
                .padding(20)
            
            // Corner indicator
            VStack {
                HStack {
                    Text(isFront ? "FRONT" : "BACK")
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
