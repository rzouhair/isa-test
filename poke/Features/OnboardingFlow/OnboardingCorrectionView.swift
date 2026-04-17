//
//  OnboardingCorrectionView.swift
//  poke
//
//  Screen 2: High Accuracy + Correction — emphasizes AI accuracy
//  and the ability for users to correct/refine detection results.
//

import SwiftUI
import Inject

struct OnboardingCorrectionView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var showCorrection = false
    @State private var accuracyProgress: CGFloat = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var cardFlip: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("HIGH ACCURACY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("AI-powered with\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("your control.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)

                Text("Our AI identifies cards with high precision. Not quite right? Easily correct and refine results.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Animated detection card
                detectionAnimation
                    .padding(.bottom, 20)

                // Accuracy meter
                accuracyMeter
                    .padding(.bottom, 16)

                // Correction feature card
                correctionFeatureCard
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
            // Animate accuracy bar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.5)) {
                    accuracyProgress = 0.90
                }
            }
            // Show checkmark
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    checkmarkScale = 1.0
                }
            }
            // Show correction after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showCorrection = true
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Detection Animation

    private var detectionAnimation: some View {
        ZStack {
            // Two cards — detected and correction
            HStack(spacing: 16) {
                // Original scan result
                VStack(spacing: 8) {
                    // Mini card
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.onboardingCardBg)
                            .frame(width: 90, height: 126)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(theme.accentBright.opacity(0.3), lineWidth: 1)
                            )

                        VStack(spacing: 4) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(theme.accentBright)

                            Text("Pikachu V")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)

                            Text("$45.00")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(theme.accentWarm)
                        }

                        // Animated scan line
                        ScanLineView()
                            .frame(width: 90, height: 126)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .opacity(showCorrection ? 0 : 1)
                    }

                    Text("Detected")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)
                .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: isAnimating)

                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.accentBright.opacity(showCorrection ? 1 : 0.3))

                // Corrected result
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.onboardingCardBg)
                            .frame(width: 90, height: 126)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(showCorrection ? theme.accentBright.opacity(0.6) : Color.white.opacity(0.1), lineWidth: showCorrection ? 2 : 1)
                            )

                        VStack(spacing: 4) {
                            if showCorrection {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(theme.accentBright)
                                    .transition(.scale.combined(with: .opacity))

                                Text("Pikachu VMAX")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .transition(.opacity)

                                Text("$89.00")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(theme.accentWarm)
                                    .transition(.opacity)
                            } else {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.2))

                                Text("Tap to correct")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }

                    Text(showCorrection ? "Corrected" : "Your edit")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(showCorrection ? theme.accentBright : .white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.1), value: isAnimating)
    }

    // MARK: - Accuracy Meter

    private var accuracyMeter: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Detection Accuracy")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 4) {
                    Text("90%+")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentBright)

                    if checkmarkScale > 0 {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 16))
                            .foregroundColor(theme.accentWarm)
                            .scaleEffect(checkmarkScale)
                    }
                }
            }

            // Animated progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    // Fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [theme.ctaFill, theme.accentBright],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * accuracyProgress, height: 8)

                    // Glow at tip
                    if accuracyProgress > 0.5 {
                        Circle()
                            .fill(theme.accentBright)
                            .frame(width: 12, height: 12)
                            .shadow(color: theme.accentBright.opacity(0.6), radius: 6)
                            .offset(x: geo.size.width * accuracyProgress - 6)
                    }
                }
            }
            .frame(height: 12)

            // Sub labels
            HStack {
                Text("Powered by AI vision")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text("+ Your corrections")
                    .font(.system(size: 11))
                    .foregroundColor(theme.accentBright.opacity(0.7))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }

    // MARK: - Correction Feature Card

    private var correctionFeatureCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentWarm.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "pencil.and.list.clipboard")
                    .font(.system(size: 20))
                    .foregroundColor(theme.accentWarm)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Easy correction")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Wrong card detected? Pick the right one from suggestions or search manually.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: isAnimating)
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingCorrectionView()
    }
}
