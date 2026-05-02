import SwiftUI
import Inject

struct OnboardingRateUsView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var starScales: [CGFloat] = Array(repeating: 0, count: 5)
    @State private var bubbleScale: CGFloat = 0
    @State private var floatOffset: CGFloat = 0
    @State private var shimmerPhase: CGFloat = -1
    @State private var sparkleOpacities: [Double] = [0, 0, 0]

    var body: some View {
        VStack(spacing: 0) {
            // Hero image area with animated overlay
            ZStack {
                // Background image with soft vignette
                Image("hero_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.45)
                    .clipped()
                    .mask(
                        RadialGradient(
                            colors: [.white, .white.opacity(0.8), .clear],
                            center: .center,
                            startRadius: 60,
                            endRadius: UIScreen.main.bounds.width * 0.55
                        )
                    )

                // Animated stars speech bubble
                VStack(spacing: 0) {
                    Spacer()

                    // Speech bubble with stars
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(.systemYellow), Color(.systemOrange).opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .scaleEffect(starScales[i])
                                    .shadow(color: Color(.systemYellow).opacity(0.4), radius: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .clear,
                                                .white.opacity(0.05),
                                                .white.opacity(0.12),
                                                .white.opacity(0.05),
                                                .clear
                                            ],
                                            startPoint: UnitPoint(x: shimmerPhase - 0.3, y: 0.5),
                                            endPoint: UnitPoint(x: shimmerPhase, y: 0.5)
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .shadow(color: theme.accent.opacity(0.3), radius: 20, y: 4)
                    )
                    .scaleEffect(bubbleScale)
                    .offset(y: floatOffset)

                    // Bubble tail
                    Triangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Triangle().fill(Color.white.opacity(0.05)))
                        .frame(width: 16, height: 10)
                        .scaleEffect(bubbleScale)
                        .offset(y: floatOffset)

                    Spacer()
                        .frame(height: 60)
                }

                // Floating sparkles
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: [12, 16, 10][i]))
                        .foregroundStyle(theme.accentBright)
                        .opacity(sparkleOpacities[i])
                        .offset(
                            x: [CGFloat(-80), 90, -50][i],
                            y: [CGFloat(-40), -20, 30][i] + floatOffset * [0.5, 0.7, 0.3][i]
                        )
                }
            }
            .frame(height: UIScreen.main.bounds.height * 0.45)

            // Text content
            VStack(spacing: 12) {
                (Text("We'd be so happy\nif you can ")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("rate us.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .multilineTextAlignment(.center)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                Text("A quick rating helps us bring this\nexperience to more users like you.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 15)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4), value: isAnimating)
            }
            .padding(.horizontal, 28)
            .padding(.top, 4)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }

            // Bubble pops in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                bubbleScale = 1
            }

            // Stars pop in sequentially
            for i in 0..<5 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.4 + Double(i) * 0.12)) {
                    starScales[i] = 1
                }
            }

            // Sparkles fade in
            for i in 0..<3 {
                withAnimation(.easeInOut(duration: 0.6).delay(0.8 + Double(i) * 0.2)) {
                    sparkleOpacities[i] = 0.7
                }
            }

            // Gentle float loop
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = -6
            }

            // Shimmer loop
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                shimmerPhase = 2
            }
        }
        .enableInjection()
    }
}

// MARK: - Speech bubble tail

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX - rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width / 2, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingRateUsView()
    }
}
