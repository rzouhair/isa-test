import SwiftUI
import Inject

/// Animated hero screen — graduation cap rotates in + glow pulses,
/// headline types in, sub-badges stagger.
struct OnboardingHeroView: View {
    @ObserveInjection var inject

    @State private var capScale: CGFloat = 0.4
    @State private var capRotation: Double = -18
    @State private var capOpacity: Double = 0
    @State private var glowScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var badgesVisible: Bool = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                pulsingGlow
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 110, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accentBright, theme.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(capScale)
                    .rotationEffect(.degrees(capRotation))
                    .opacity(capOpacity)
                    .shadow(color: theme.accent.opacity(0.4), radius: 24, y: 8)
            }
            .frame(height: 200)

            VStack(spacing: 10) {
                Text("Pass your ISA exam")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)

                Text("on the first try.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(theme.accentBright)
                    .opacity(titleOpacity)
            }

            Text("750 practice questions, 250 atomic flashcards, full mock exam — across all 10 ISA domains.")
                .font(.system(size: 16))
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .opacity(subtitleOpacity)

            HStack(spacing: 10) {
                badge(icon: "leaf.fill", label: "Tree Biology")
                badge(icon: "scissors", label: "Pruning")
                badge(icon: "shield.fill", label: "Risk & Safety")
            }
            .opacity(badgesVisible ? 1 : 0)
            .offset(y: badgesVisible ? 0 : 12)

            Spacer()
        }
        .onAppear { animateIn() }
        .enableInjection()
    }

    private var pulsingGlow: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let breathing = 0.9 + 0.15 * sin(t * 1.2)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accent.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 150
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(glowScale * breathing)
                .blur(radius: 20)
        }
    }

    private func badge(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(theme.accentBright)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            capScale = 1
            capRotation = 0
            capOpacity = 1
            glowScale = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.35)) {
            titleOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            subtitleOpacity = 1
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.8)) {
            badgesVisible = true
        }
    }
}
