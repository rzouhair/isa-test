//
//  OnboardingExportImportView.swift
//  poke
//
//  Screen 4: Export & Import — emphasizes the ability to
//  export and import card collections with animated visuals.
//

import SwiftUI
import Inject

struct OnboardingExportImportView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var exportPhase: Int = 0 // 0: idle, 1: exporting, 2: done
    @State private var importCards: [Bool] = [false, false, false]
    @State private var showShareSheet = false
    @State private var fileOffset: CGFloat = 40

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("YOUR DATA, YOUR WAY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("Export & import\nyour ")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("collection.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)

                Text("Back up your cards, share with friends, or move to a new device. Your data is always portable.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Export animation
                exportAnimation
                    .padding(.bottom, 20)

                // Import animation
                importAnimation
                    .padding(.bottom, 20)

                // Feature cards
                featureRow(
                    icon: "square.and.arrow.up",
                    iconBg: theme.accentBright,
                    title: "Export collection",
                    subtitle: "Save your entire collection as a file. Share it or keep it as a backup."
                )
                .padding(.bottom, 12)

                featureRow(
                    icon: "square.and.arrow.down",
                    iconBg: theme.accentWarm,
                    title: "Import collection",
                    subtitle: "Restore from a backup or import cards from a shared file."
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
            // Export animation sequence
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    exportPhase = 1
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    exportPhase = 2
                }
            }
            // Import animation sequence
            for i in 0..<importCards.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5 + Double(i) * 0.35) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        importCards[i] = true
                    }
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Export Animation

    private var exportAnimation: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Export")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if exportPhase == 2 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.accentBright)
                        Text("Ready to share")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.accentBright)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            HStack(spacing: 16) {
                // Card stack (source)
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.onboardingCardBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(theme.accentBright.opacity(0.2), lineWidth: 1)
                            )
                            .frame(width: 44, height: 60)
                            .offset(x: CGFloat(i) * 3, y: CGFloat(i) * -4)
                    }

                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 16))
                        .foregroundColor(theme.accentBright.opacity(0.6))
                        .offset(x: 3, y: -4)
                }
                .frame(width: 56, height: 68)

                // Arrow with animation
                ZStack {
                    // Arrow trail dots
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(theme.accentBright.opacity(exportPhase >= 1 ? 0.6 - Double(i) * 0.2 : 0.1))
                                .frame(width: 4, height: 4)
                        }
                    }

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accentBright.opacity(exportPhase >= 1 ? 1 : 0.3))
                        .offset(x: 20)
                }

                // File output
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.onboardingCardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    exportPhase == 2 ? theme.accentBright.opacity(0.5) : Color.white.opacity(0.1),
                                    lineWidth: exportPhase == 2 ? 2 : 1
                                )
                        )
                        .frame(width: 52, height: 64)

                    VStack(spacing: 4) {
                        Image(systemName: exportPhase == 2 ? "doc.fill" : "doc")
                            .font(.system(size: 20))
                            .foregroundColor(exportPhase == 2 ? theme.accentBright : .white.opacity(0.3))

                        Text(".json")
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .scaleEffect(exportPhase == 2 ? 1.0 : 0.9)
                .opacity(exportPhase >= 1 ? 1 : 0.5)
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

    // MARK: - Import Animation

    private let importCardNames = [
        ("Pikachu V", "$45.00"),
        ("Mewtwo GX", "$62.00"),
        ("Lugia V", "$38.00"),
    ]

    private var importAnimation: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Import")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if importCards.allSatisfy({ $0 }) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.accentBright)
                        Text("3 cards imported")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.accentBright)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Cards flying in
            HStack(spacing: 10) {
                ForEach(0..<importCardNames.count, id: \.self) { i in
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(theme.onboardingCardBg)
                                .frame(width: 70, height: 42)

                            Image(systemName: "sparkle")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.2))
                        }

                        Text(importCardNames[i].0)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(importCardNames[i].1)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accentWarm)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(
                                importCards[i] ? theme.accentBright.opacity(0.3) : Color.white.opacity(0.06),
                                lineWidth: 1
                            )
                    )
                    .opacity(importCards[i] ? 1 : 0.3)
                    .offset(y: importCards[i] ? 0 : 20)
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, iconBg: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(iconBg.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconBg)
            }

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
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3), value: isAnimating)
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingExportImportView()
    }
}
