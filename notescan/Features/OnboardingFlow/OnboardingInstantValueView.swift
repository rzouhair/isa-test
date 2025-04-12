//
//  OnboardingInstantValueView.swift
//  notescan
//
//  Created by user on 5/4/2025.
//

import SwiftUI

struct OnboardingInstantValueView: View {
    let onTryNowTapped: () -> Void
    let onLearnMoreTapped: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Text("Instantly identify any banknote")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text("Just point your camera. We'll handle the rest.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
            
            // Illustration
            Asset.Images.onboarding1.swiftUIImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 280, maxHeight: 280)
                .padding()
                .opacity(isAnimating ? 1 : 0)
                .scaleEffect(isAnimating ? 1 : 0.8)
            
            Spacer()
            
            // CTAs
            VStack(spacing: 16) {
                Button(action: onTryNowTapped) {
                    HStack(spacing: 12) {
                        Text("See how it works")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Asset.Colors.appPrimary.swiftUIColor)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 48)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
    }
}

struct OnboardingInstantValueView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingInstantValueView(
            onTryNowTapped: {},
            onLearnMoreTapped: {}
        )
    }
}
