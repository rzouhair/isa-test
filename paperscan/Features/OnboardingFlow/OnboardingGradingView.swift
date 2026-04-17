import SwiftUI
import Inject

struct OnboardingGradingView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var revealScore = false
    @State private var barWidths: [CGFloat] = [0, 0, 0, 0]
    @State private var showGrade = false
    @State private var flipCard = false
    @State private var showSteps = false

    private let categories = [
        ("Centering", 8.5, "checkmark.circle"),
        ("Corners", 7.0, "square.on.square"),
        ("Edges", 9.0, "rectangle.split.3x1"),
        ("Surface", 6.5, "sparkle.magnifyingglass"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("AI GRADING")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("Know the grade\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("before you send it.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)

                Text("Take a few photos. Get an estimated PSA & BGS grade with detailed sub-scores.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Card + grade reveal animation
                gradeRevealAnimation
                    .padding(.bottom, 20)

                // Sub-score bars
                subScoreBars
                    .padding(.bottom, 16)

                // Photo step indicators
                photoSteps
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
            // Flip card
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    flipCard = true
                }
            }
            // Reveal scores one by one
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.3) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        barWidths[i] = CGFloat(categories[i].1) / 10.0
                        revealScore = true
                    }
                }
            }
            // Show grade
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                    showGrade = true
                }
            }
            // Show steps
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showSteps = true
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Grade Reveal Animation

    private var gradeRevealAnimation: some View {
        HStack(spacing: 16) {
            // Card mock
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [theme.accent.opacity(0.4), theme.onboardingCardBg],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(theme.accentBright.opacity(0.2), lineWidth: 1)
                    )

                // Scan lines
                if !flipCard {
                    VStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(theme.accentBright.opacity(0.15))
                                .frame(width: 60, height: 2)
                        }
                    }
                }

                // Grade badge overlay
                if flipCard {
                    VStack(spacing: 4) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 20))
                            .foregroundColor(theme.accentBright.opacity(0.4))

                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 28))
                            .foregroundColor(theme.accentBright)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .rotation3DEffect(.degrees(flipCard ? 0 : -15), axis: (x: 0, y: 1, z: 0))
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)

            // Grade result
            VStack(alignment: .leading, spacing: 8) {
                if showGrade {
                    Text("PSA")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1.5)

                    Text("8 – 9")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))

                    HStack(spacing: 4) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 10))
                            .foregroundColor(theme.accentWarm)
                        Text("High confidence")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.accentWarm)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Placeholder shimmer
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.06))
                            .frame(width: 40, height: 12)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.08))
                            .frame(width: 80, height: 32)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white.opacity(0.04))
                            .frame(width: 100, height: 12)
                    }
                }
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

    // MARK: - Sub-Score Bars

    private var subScoreBars: some View {
        VStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { i in
                let cat = categories[i]
                HStack(spacing: 10) {
                    Image(systemName: cat.2)
                        .font(.system(size: 11))
                        .foregroundColor(theme.accentBright.opacity(0.6))
                        .frame(width: 16)

                    Text(cat.0)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 65, alignment: .leading)

                    // Bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white.opacity(0.06))

                            RoundedRectangle(cornerRadius: 3)
                                .fill(barColor(cat.1))
                                .frame(width: geo.size.width * barWidths[i])
                        }
                    }
                    .frame(height: 6)

                    Text(barWidths[i] > 0 ? String(format: "%.1f", cat.1) : "–")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(barWidths[i] > 0 ? barColor(cat.1) : .white.opacity(0.2))
                        .frame(width: 28, alignment: .trailing)
                        .contentTransition(.numericText())
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: isAnimating)
    }

    private func barColor(_ score: Double) -> Color {
        if score >= 8.0 { return Color(hex: "4ADE80") } // green
        if score >= 6.0 { return theme.accentWarm }      // warm/orange
        return Color(hex: "F87171")                       // red
    }

    // MARK: - Photo Steps

    private var photoSteps: some View {
        HStack(spacing: 8) {
            stepPill(icon: "rectangle.portrait", text: "Front")
            stepPill(icon: "rectangle.portrait.fill", text: "Back")
            stepPill(icon: "rectangle.portrait.rotate", text: "Angled")
            stepPill(icon: "viewfinder", text: "Corners")
        }
        .frame(maxWidth: .infinity)
        .opacity(showSteps ? 1 : 0)
        .offset(y: showSteps ? 0 : 15)
    }

    private func stepPill(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.accentBright)

            Text(text)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.04))
        .overlay(
            Capsule().strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingGradingView()
    }
}
