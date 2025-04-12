//
//  OnboardingFeaturesView.swift
//  notescan
//
//  Created by user on 5/4/2025.
//

import SwiftUI

struct OnboardingFeaturesView: View {
    let onSkip: () -> Void
    let onFinish: () -> Void
    
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    private let features = [
        FeatureSlide(
            title: "How It Works",
            description: "Capture a photo of any banknote.",
            imageName: "onboarding1",
            iconName: "camera.viewfinder"
        ),
        FeatureSlide(
            title: "Our AI at Work",
            description: "Our technology analyzes the image instantly.",
            imageName: "onboarding2",
            iconName: "sparkles"
        ),
        FeatureSlide(
            title: "Instant Identification",
            description: "Get accurate information at your fingertips.",
            imageName: "onboarding3",
            iconName: "doc.text.magnifyingglass"
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
    let slide: FeatureSlide
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Image
            Asset.Images.onboarding1.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 280)
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
                    
                    Text(slide.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
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
