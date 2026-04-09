//
//  AppPreviewCardsView.swift
//  paperscan
//

import SwiftUI
import Inject

struct AppPreviewCardsView: View {
    @ObserveInjection var inject
    @State private var scanOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Back card - Scan result
            backCard
                .frame(width: 200, height: 260)
                .rotationEffect(.degrees(6))
                .offset(x: 60, y: 20)
                .shadow(color: Color.black.opacity(0.25), radius: 16, y: 8)

            // Front card - Scanner UI
            frontCard
                .frame(width: 190, height: 280)
                .rotationEffect(.degrees(-4))
                .offset(x: -40, y: 16)
                .shadow(color: Color.black.opacity(0.3), radius: 16, y: 8)
        }
        .enableInjection()
    }

    // MARK: - Back Card (Scan Result — dark themed)

    private var backCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scan result")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(theme.accentBright.opacity(0.6))
                .padding(.bottom, 2)

            Text("Charizard EX")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)

            Text("Scarlet & Violet · 006/198")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 4) {
                Text("Market value")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text("$328.50")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(theme.accentWarm)
            }
            .padding(.top, 4)

            // Rarity bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [theme.ctaFill, theme.accentWarm],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.85, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.top, 4)

            // Rarity pills
            HStack(spacing: 6) {
                ForEach(["Ultra Rare", "Holo"], id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.accentBright)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.accentBright.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(16)
        .background(theme.onboardingCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Front Card (Scanner UI — TCG card style)

    private var frontCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Viewfinder area — dark with card shape
            GeometryReader { geo in
                ZStack {
                    // TCG card placeholder (portrait)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(theme.accentBright.opacity(0.2), lineWidth: 1)
                        )
                        .frame(width: geo.size.width * 0.4, height: geo.size.height * 0.7)

                    // Card art hint
                    Image(systemName: "sparkle")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accentBright.opacity(0.3))

                    // Scan line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    theme.accentBright,
                                    theme.accentWarmLight,
                                    theme.accentBright,
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                        .offset(y: scanOffset - geo.size.height / 2)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: false)
                            ) {
                                scanOffset = geo.size.height
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 130)
            .background(theme.onboardingBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Value row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Identified")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Charizard EX")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("$328.50")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.accentWarm)
            }

            // Rarity bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 5)

                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.accent)
                    .frame(width: 90, height: 5)
            }

            // Icon row
            HStack(spacing: 12) {
                ForEach(["doc.text.magnifyingglass", "chart.line.uptrend.xyaxis", "tag"], id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
            }

            Spacer()
        }
        .padding(14)
        .background(theme.onboardingCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    AppPreviewCardsView()
        .frame(height: 340)
        .padding()
        .background(theme.onboardingBg)
}
