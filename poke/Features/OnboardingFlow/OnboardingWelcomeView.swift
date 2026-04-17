//
//  OnboardingHeroView.swift
//  poke
//
//  Screen 0: Hero splash with floating TCG card, scan ring animation,
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
    @State private var cardOffset: CGFloat = 0
    @State private var cardRotation: Double = -1

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background glow
                backgroundGlow(in: geo)

                VStack(spacing: 0) {
                    Spacer()

                    // Floating TCG card with scan ring
                    cardView
                        .padding(.bottom, 32)

                    // Hero content
                    heroContent
                        .padding(.bottom, 24)

                    Spacer()
                }
                .frame(maxWidth: .infinity)

                // Notification overlay
                notificationOverlay
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isAnimating = true
                }
                withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                    cardOffset = -10
                    cardRotation = 0.5
                }
                withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                    pulseScale = 1.08
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showNotification = true
                    }
                }
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
                    colors: [theme.accent.opacity(0.35), Color.clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: min(geo.size.width, geo.size.height) * 0.6
                )
            )
            .frame(width: min(geo.size.width, geo.size.height) * 1.2, height: min(geo.size.width, geo.size.height) * 1.2)
            .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
            .scaleEffect(pulseScale)
    }

    // MARK: - TCG Card

    private var cardView: some View {
        ZStack {
            // Scan ring — card portrait ratio
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    LinearGradient(
                        colors: [theme.ctaFill, theme.accentWarm, theme.ctaFill],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 170, height: 236)
                .opacity(isAnimating ? 1 : 0)
                .modifier(ScanRingPulse())

            // TCG Card
            ZStack {
                // Card art area (top portion)
                VStack(spacing: 0) {
                    // Card art placeholder
                    ZStack {
                        LinearGradient(
                            colors: [theme.accent.opacity(0.4), theme.accentBright.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        // Card art icon
                        Image(systemName: "flame.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white.opacity(0.3))

                        // Holo shimmer overlay
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.08), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                    .frame(height: 110)

                    // Card info area (bottom portion)
                    VStack(spacing: 6) {
                        // Card name
                        Text("Charizard EX")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        // Set info
                        Text("Scarlet & Violet · 006/198")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .tracking(0.5)

                        // Price tag
                        HStack(spacing: 4) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 10))
                                .foregroundColor(theme.accentWarm)
                            Text("$328.50")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundColor(theme.accentWarm)
                        }
                        .padding(.top, 4)

                        // Rarity indicator
                        HStack(spacing: 4) {
                            ForEach(0..<4, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(i < 3 ? theme.accentWarm : .white.opacity(0.15))
                            }
                            Text("Ultra Rare")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 155, height: 220)
            .background(
                LinearGradient(
                    colors: [
                        theme.onboardingCardBg,
                        theme.onboardingBg
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            colors: [theme.accentBright.opacity(0.3), theme.accentWarm.opacity(0.2), theme.accentBright.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: theme.accent.opacity(0.4), radius: 30, y: 20)

            // Scan line — clipped to card bounds
            ScanLineView()
                .frame(width: 155, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .offset(y: cardOffset)
        .rotationEffect(.degrees(cardRotation))
        .opacity(isAnimating ? 1 : 0)
        .scaleEffect(isAnimating ? 1 : 0.8)
    }

    // MARK: - Hero Content

    private var heroContent: some View {
        VStack(spacing: 16) {
            // Badge
            HStack(spacing: 8) {
                Circle()
                    .fill(theme.accentBright)
                    .frame(width: 6, height: 6)
                    .modifier(BlinkingDot())

                Text("Instant card identification")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentMuted)
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
            (Text("Know What Your\nCards Are Really ")
                .font(.system(size: 34))
                .foregroundStyle(.white)
            + Text("Worth.")
                .font(.system(size: 34, weight: .regular, design: .serif))
                .italic()
                .foregroundColor(theme.accentWarm))
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)

            // Subtitle
            Text("Scan any collectible card and get its real market value, price trends, and details — in seconds.")
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
            Text("🃏")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 2) {
                Text("Poke identified your card")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.black)

                (Text("Charizard EX · ")
                    .foregroundColor(Color(hex: "#555555"))
                + Text("Ultra Rare")
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#1a4a2e"))
                + Text(" · $328.50")
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
                        colors: [.clear, theme.accentBright, theme.accentWarmLight, theme.accentBright, .clear],
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
        theme.onboardingBg.ignoresSafeArea()
        OnboardingHeroView()
    }
}
