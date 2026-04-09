//
//  OnboardingBulkScanView.swift
//  paperscan
//
//  Screen 3: Bulk Scan — emphasizes scanning multiple cards
//  quickly with animated card stack visualization.
//

import SwiftUI
import Inject

struct OnboardingBulkScanView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var scannedCount: Int = 0
    @State private var cardPositions: [Bool] = [false, false, false, false, false]
    @State private var showTotal = false

    private let cardNames = [
        ("Pikachu V", "$45.00"),
        ("Charizard EX", "$328.50"),
        ("Mewtwo GX", "$62.00"),
        ("Lugia V", "$38.00"),
        ("Umbreon VMAX", "$185.00"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("BULK SCANNING")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("Scan your entire\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("collection.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)

                Text("Scan cards one after another. Build your collection in minutes, not hours.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Animated card stack
                cardStackAnimation
                    .padding(.bottom, 20)

                // Counter display
                scanCounterCard
                    .padding(.bottom, 16)

                // Feature pills
                featurePills
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
            // Animate cards appearing one by one
            for i in 0..<cardPositions.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5 + 0.5) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        cardPositions[i] = true
                        scannedCount = i + 1
                    }
                }
            }
            // Show total
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showTotal = true
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Card Stack Animation

    private var cardStackAnimation: some View {
        ZStack {
            // Stacked cards coming in from right
            ZStack {
                ForEach(0..<cardPositions.count, id: \.self) { i in
                    miniScanCard(
                        name: cardNames[i].0,
                        price: cardNames[i].1,
                        index: i
                    )
                    .offset(
                        x: cardPositions[i] ? CGFloat(i) * 4 : 120,
                        y: cardPositions[i] ? CGFloat(i) * -8 : 0
                    )
                    .rotationEffect(.degrees(cardPositions[i] ? Double(i - 2) * 1.5 : 10))
                    .opacity(cardPositions[i] ? 1 : 0)
                    .zIndex(Double(i))
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)

            // Scan indicator overlay
            if scannedCount > 0 && scannedCount < 5 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        // Scanning pulse
                        ZStack {
                            Circle()
                                .fill(theme.accentBright.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .scaleEffect(scannedCount < 5 ? 1.3 : 1.0)
                                .opacity(scannedCount < 5 ? 0 : 1)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: scannedCount)

                            Image(systemName: "viewfinder")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(theme.accentBright)
                        }
                    }
                }
                .frame(height: 180)
                .padding(.trailing, 20)
            }
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

    private func miniScanCard(name: String, price: String, index: Int) -> some View {
        VStack(spacing: 6) {
            // Card art placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                theme.accent.opacity(0.3 + Double(index) * 0.05),
                                theme.onboardingCardBg
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 48)

                Image(systemName: "sparkle")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.2))
            }

            Text(name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(price)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(theme.accentWarm)
        }
        .padding(8)
        .frame(width: 90)
        .background(theme.onboardingCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(theme.accentBright.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }

    // MARK: - Scan Counter

    private var scanCounterCard: some View {
        HStack(spacing: 16) {
            // Counter circle
            ZStack {
                Circle()
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 2)
                    .frame(width: 56, height: 56)

                // Progress ring
                Circle()
                    .trim(from: 0, to: CGFloat(scannedCount) / CGFloat(cardPositions.count))
                    .stroke(
                        LinearGradient(
                            colors: [theme.ctaFill, theme.accentBright],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Text("\(scannedCount)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Cards scanned")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                if showTotal {
                    HStack(spacing: 4) {
                        Text("Total value:")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text("$658.50")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accentWarm)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text("Scanning...")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()
        }
        .padding(16)
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

    // MARK: - Feature Pills

    private var featurePills: some View {
        HStack(spacing: 10) {
            featurePill(icon: "bolt.fill", text: "Fast capture")
            featurePill(icon: "square.stack.3d.up.fill", text: "Auto-queue")
            featurePill(icon: "tray.full.fill", text: "Batch results")
        }
        .frame(maxWidth: .infinity)
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: isAnimating)
    }

    private func featurePill(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(theme.accentBright)

            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.05))
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingBulkScanView()
    }
}
