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
                Spacer()
                
                // Logo and app name
                VStack(spacing: 24) {
                    Asset.Images.logo.swiftUIImage
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 80)
                        .opacity(isAnimating ? 1 : 0)
                        .scaleEffect(isAnimating ? 1 : 0.8)
                    
                    VStack(spacing: 8) {
                        Text("Welcome to\n \(Constants.appName)")
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Your Smart Scanning Assistant")
                            .font(.system(size: 16, weight: .regular))
                            .opacity(0.9)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .foregroundColor(.white)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
                
                // Feature highlights
                VStack(spacing: 16) {
                    featureRow(icon: "camera.viewfinder", text: "Instant scanning and recognition")
                    featureRow(icon: "sparkles", text: "AI-powered analysis and insights")
                    featureRow(icon: "doc.text.magnifyingglass", text: "Detailed results at your fingertips")
                    featureRow(icon: "lock.shield", text: "Secure and private scanning")
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

                Spacer()
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
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
