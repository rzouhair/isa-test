//
//  OnboardingWelcomeView.swift
//  paperscan
//
//  Created by user on 5/4/2025.
//

import SwiftUI
import Inject

struct OnboardingWelcomeView: View {
    @ObserveInjection var inject
    let onContinue: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            Asset.Colors.appPrimary.swiftUIColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and app name
                VStack(spacing: 24) {
                    Asset.Images.logo.swiftUIImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 100)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to\nPaperScan AI")
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text("Your Smart Banknote Assistant")
                            .font(.title3)
                            .opacity(0.9)
                    }
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
                
                // Feature highlights
                VStack(spacing: 16) {
                    featureRow(icon: "camera.viewfinder", text: "Instant banknote recognition in seconds")
                    featureRow(icon: "heart.fill", text: "Build and organize your personal collection")
                    featureRow(icon: "globe", text: "Support for 150+ currencies")
                    featureRow(icon: "lock.shield", text: "Secure and private scanning technology")
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                
                Spacer()
                
                // Continue button
                Button(action: onContinue) {
                    HStack {
                        Text("Get Started")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .foregroundColor(Asset.Colors.appPrimary.swiftUIColor)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                }
                .padding(.horizontal, 24)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
            .padding(.bottom, 48)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .enableInjection()
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .frame(width: 32)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
