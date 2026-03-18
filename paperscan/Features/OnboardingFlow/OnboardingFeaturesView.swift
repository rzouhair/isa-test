//
//  OnboardingFeaturesView.swift
//  paperscan
//
//  Created by user on 5/4/2025.
//

import SwiftUI
import Inject

struct OnboardingFeaturesView: View {
    @ObserveInjection var inject
    let onSkip: () -> Void
    let onFinish: () -> Void
    
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    private let features = [
        FeatureSlide(
            title: "Instant Recognition",
            description: "Capture and identify items in seconds with our advanced AI technology.",
            imageName: "note",
            iconName: "camera.viewfinder"
        ),
        FeatureSlide(
            title: "AI-Powered Analysis",
            description: "Our AI instantly analyzes your scans and provides accurate information.",
            imageName: "magic",
            iconName: "sparkles"
        ),
        FeatureSlide(
            title: "Unlock Full Potential",
            description: "Upgrade to Pro for unlimited scans and detailed information at your fingertips.",
            imageName: "lock",
            iconName: "lock.open.fill"
        ),
        FeatureSlide(
            title: "Privacy First",
            description: "We never store your images. Camera access is only used for scanning.",
            imageName: "shield",
            iconName: "shield.fill"
        )
    ]
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Stories-style progress indicator
                HStack(spacing: 4) {
                    ForEach(0..<features.count, id: \.self) { index in
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background bar
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                
                                // Progress bar
                                Rectangle()
                                    .fill(Asset.Colors.appPrimary.swiftUIColor)
                                    .frame(width: currentPage > index ?
                                        geometry.size.width :
                                        (currentPage == index ? geometry.size.width : 0))
                            }
                        }
                        .frame(height: 4)
                        .animation(.linear(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                
                // Header with Skip button
                HStack {
                    Spacer()
                    Button(action: onSkip) {
                        Text("Skip")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                }
                .padding()
                
                // Carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<features.count, id: \.self) { index in
                        FeatureSlideView(slide: features[index])
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                Spacer()
                
                // Progress indicators and buttons
                VStack(spacing: 24) {
                    // Next/Finish button
                    Button(action: {
                        if currentPage == features.count - 1 {
                            onFinish()
                        } else {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                    }) {
                        HStack {
                            Text(currentPage == features.count - 1 ? "Get Started" : "Next")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Asset.Colors.appPrimary.swiftUIColor)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 48)
            }
        }
    }
}

struct FeatureSlide: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let iconName: String
}

struct FeatureSlideView: View {
    @ObserveInjection var inject
    let slide: FeatureSlide
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            // Image
            Image(slide.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            
            // Icon and Text
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Asset.Colors.appPrimary.swiftUIColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: slide.iconName)
                        .font(.system(size: 30))
                        .foregroundColor(Asset.Colors.appPrimary.swiftUIColor)
                }
                
                VStack(spacing: 8) {
                    Text(slide.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                    
                    Text(slide.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: .infinity)
            .opacity(isAnimating ? 1 : 0)
            .offset(y: isAnimating ? 0 : 20)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    OnboardingFeaturesView(onSkip: {}, onFinish: {})
}
