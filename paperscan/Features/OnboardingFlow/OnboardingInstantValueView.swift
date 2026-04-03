//
//  OnboardingValueView.swift
//  paperscan
//
//  Screen 1: Features / Value proposition with 3 feature cards
//  and a result preview including animated rarity bar.
//

import SwiftUI
import Inject

struct OnboardingValueView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var rarityLoaded = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("WHAT YOU GET")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(KashColors.green300)
                    .tracking(2)
                    .padding(.bottom, 12)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                (Text("More than just\na ")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("scanner.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(KashColors.green300))
                .padding(.bottom, 8)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                Text("Kash combines AI identification with real sales data and rarity databases.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                // Value cards
                VStack(spacing: 12) {
                    valueCard(
                        icon: "🔍",
                        iconStyle: .green,
                        title: "Instant ID",
                        subtitle: "Identify any banknote from 150+ countries in seconds",
                        delay: 0.22
                    )

                    valueCard(
                        icon: "💰",
                        iconStyle: .gold,
                        title: "Real market value",
                        subtitle: "Prices sourced from recent auction sales, not guesswork",
                        delay: 0.30
                    )

                    valueCard(
                        icon: "📦",
                        iconStyle: .teal,
                        title: "Your collection",
                        subtitle: "Track every note, and its total estimated value by grade",
                        delay: 0.38
                    )
                }
                .padding(.bottom, 24)

                // Result preview
                resultPreview
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.2)) {
                    rarityLoaded = true
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Value Card

    enum IconStyle {
        case green, gold, teal

        var background: Color {
            switch self {
            case .green: return KashColors.green500.opacity(0.25)
            case .gold:  return KashColors.gold.opacity(0.2)
            case .teal:  return Color(hex: "#2a7a6e").opacity(0.25)
            }
        }

        var border: Color {
            switch self {
            case .green: return KashColors.green300.opacity(0.2)
            case .gold:  return KashColors.gold.opacity(0.25)
            case .teal:  return Color(hex: "#2a7a6e").opacity(0.3)
            }
        }
    }

    private func valueCard(icon: String, iconStyle: IconStyle, title: String, subtitle: String, delay: Double) -> some View {
        HStack(spacing: 16) {
            Text(icon)
                .font(.system(size: 22))
                .frame(width: 48, height: 48)
                .background(iconStyle.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(iconStyle.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(delay), value: isAnimating)
    }

    // MARK: - Result Preview

    private var resultPreview: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Ten Pounds Sterling, 2015")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("$127–$261")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(KashColors.gold)
            }

            HStack {
                Text("Grade")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("XF / VF")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Rarity
            VStack(spacing: 6) {
                HStack {
                    Text("Rarity")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Common →")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Uncommon")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(KashColors.green300)
                    }
                }

                // Rarity bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [KashColors.green400, KashColors.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: rarityLoaded ? geo.size.width * 0.72 : 0, height: 6)
                            .animation(.easeOut(duration: 1.2).delay(0.3), value: rarityLoaded)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(18)
        .background(KashColors.green800)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.44), value: isAnimating)
    }
}

#Preview {
    ZStack {
        KashColors.green900.ignoresSafeArea()
        OnboardingValueView()
    }
}
