//
//  OnboardingHeroView.swift
//  paperscan
//
//  Screen 0: Hero splash with floating banknote, scan ring animation,
//  and a notification teaser that slides in after 1 second.
//

import SwiftUI
import Inject

// MARK: - Hero Splash Screen

struct OnboardingHeroView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var showNotification = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var noteOffset: CGFloat = 0
    @State private var noteRotation: Double = -1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background glow
                backgroundGlow(in: geo)

                VStack(spacing: 0) {
                    Spacer()

                    // Floating banknote with scan ring
                    banknoteView
                        .padding(.bottom, 32)

                    // Hero content
                    heroContent
                        .padding(.bottom, 24)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Notification overlay - positioned within safe area
                notificationOverlay
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
                // Float animation
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    noteOffset = -10
                    noteRotation = 0.5
                }
                // Pulse animation
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    pulseScale = 1.08
                }
                // Show notification after 1s
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showNotification = true
                    }
                }
                // Hide notification after 4s
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showNotification = false
                    }
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Background Glow

    private func backgroundGlow(in geo: GeometryProxy) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [KashColors.green500.opacity(0.35), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: min(geo.size.width, geo.size.height) * 0.6
                )
            )
            .frame(width: min(geo.size.width, geo.size.height) * 1.2, height: min(geo.size.width, geo.size.height) * 1.2)
            .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
            .scaleEffect(pulseScale)
    }

    // MARK: - Banknote

    private var banknoteView: some View {
        ZStack {
            // Scan ring
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [KashColors.green400, KashColors.gold, KashColors.green400],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 256, height: 136)
                .opacity(isAnimating ? 1 : 0)
                .modifier(ScanRingPulse())

            // Banknote card
            ZStack {
                // Watermark
                Text("KASH")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.12))
                    .tracking(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 8)
                    .padding(.trailing, 18)

                HStack {
                    // Left: denomination
                    VStack(alignment: .leading, spacing: 4) {
                        Text("£10")
                            .font(.system(size: 36, weight: .black, design: .serif))
                            .foregroundColor(.white)

                        Text("STERLING · 2015")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .tracking(1.5)
                    }

                    Spacer()

                    // Right: portrait oval
                    ZStack {
                        Ellipse()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 2)
                            .background(Ellipse().fill(Color.white.opacity(0.07)))
                            .frame(width: 56, height: 70)

                        Text("👑")
                            .font(.system(size: 28))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)

                // Serial number
                Text("N#207333")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(.bottom, 10)
                    .padding(.trailing, 14)
            }
            .frame(width: 240, height: 120)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "#2d6a3f"),
                        Color(hex: "#1a4a2e"),
                        Color(hex: "#0f3020")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.5), radius: 30, y: 20)

            // Scan line — clipped to banknote bounds
            ScanLineView()
                .frame(width: 240, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .offset(y: noteOffset)
        .rotationEffect(.degrees(noteRotation))
        .opacity(isAnimating ? 1 : 0)
        .scaleEffect(isAnimating ? 1 : 0.8)
    }

    // MARK: - Hero Content

    private var heroContent: some View {
        VStack(spacing: 16) {
            // Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(KashColors.green300)
                    .frame(width: 6, height: 6)
                    .modifier(BlinkingDot())

                Text("Instant identification")
                    .font(.system(size: 12))
                    .foregroundColor(KashColors.green100)
                    .tracking(0.5)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.06))
            .overlay(
                Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(Capsule())

            // Title
            (Text("Know what your\nbanknote is ")
                .font(.system(size: 34))
                .foregroundStyle(.white)
            + Text("worth.")
                .font(.system(size: 34, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(KashColors.gold))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)

            // Subtitle
            Text("Scan any paper money and get its real market value, rarity rating, and details — in seconds.")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(.white.opacity(0.55))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 24)
        }
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
    }

    // MARK: - Notification Overlay

    private var notificationOverlay: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("💵")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text("Kash identified your note")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)

                (Text("Two Dollars, 1953 · ")
                    .foregroundColor(Color(hex: "#555555"))
                + Text("Rarity 85")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#1a4a2e"))
                + Text(" · Worth up to $261")
                    .foregroundColor(Color(hex: "#555555")))
                    .font(.system(size: 12))
                    .lineLimit(2)
            }

            Spacer()

            Text("now")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "#999999"))
        }
        .padding(14)
        .background(Color.white.opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
        .offset(y: showNotification ? 0 : -80)
        .opacity(showNotification ? 1 : 0)
    }
}

// MARK: - Scan Ring Pulse Modifier

struct ScanRingPulse: ViewModifier {
    @State private var animate = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(animate ? 1.04 : 1.0)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                    animate = true
                }
            }
    }
}

// MARK: - Scan Line

struct ScanLineView: View {
    @State private var offset: CGFloat = -78

    var body: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, KashColors.green300, KashColors.goldLight, KashColors.green300, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 2)
                .offset(y: offset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                        offset = geo.size.height - 2
                    }
                }
        }
    }
}

// MARK: - Blinking Dot

struct BlinkingDot: ViewModifier {
    @State private var opacity: Double = 1

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    opacity = 0.3
                }
            }
    }
}

#Preview {
    ZStack {
        KashColors.green900.ignoresSafeArea()
        OnboardingHeroView()
    }
}
