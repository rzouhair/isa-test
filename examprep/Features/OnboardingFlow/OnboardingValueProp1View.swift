import SwiftUI
import Inject

/// "1,020+ real CDL exam questions" — animated counter, then a stack of
/// category cards with confetti + class A/B medallions in the background.
struct OnboardingValueProp1View: View {
    @ObserveInjection var inject

    struct CategoryItem: Identifiable {
        let id = UUID()
        let label: String
        let icon: String
    }

    private let finalCount: Double = 1020
    private let cards: [CategoryItem] = [
        .init(label: "General Knowledge", icon: "lightbulb.fill"),
        .init(label: "Pre-Trip Inspection", icon: "checklist"),
        .init(label: "Hazmat", icon: "exclamationmark.triangle.fill"),
        .init(label: "School Bus", icon: "bus.fill"),
        .init(label: "Passenger Vehicles", icon: "person.2.fill"),
    ]

    @State private var count: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var visibleCards: Int = 0
    @State private var medallionRotation: Double = -8

    var body: some View {
        ZStack {
            decorativeBackdrop

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                VStack(spacing: 6) {
                    Text("\(Int(count))+")
                        .font(.system(size: 80, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentBright, theme.accentWarmLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .contentTransition(.numericText())

                    Text("real CDL exam questions")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Every category covered. Every endorsement included.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(subtitleOpacity)
                }

                cardStack
                    .padding(.horizontal, 36)

                Spacer(minLength: 0)
            }
        }
        .onAppear { animateIn() }
        .enableInjection()
    }

    // MARK: - Card stack

    private var cardStack: some View {
        VStack(spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { idx, card in
                cardRow(item: card)
                    .opacity(idx < visibleCards ? 1 : 0)
                    .offset(y: idx < visibleCards ? 0 : 12)
                    .scaleEffect(idx < visibleCards ? 1 : 0.92)
            }
        }
    }

    private func cardRow(item: CategoryItem) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.accentWarm.opacity(0.18))
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.accentWarmLight)
            }
            .frame(width: 32, height: 32)

            Text(item.label)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Color(.label).opacity(0.95))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.95))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
    }

    // MARK: - Decorative backdrop (medallions + confetti)

    private var decorativeBackdrop: some View {
        ZStack {
            // Class B medallion — top-right corner, partially off-canvas.
            classMedallion(letter: "B", innerSize: 56)
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(medallionRotation))
                .offset(x: 30, y: -10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            // Class A medallion — bottom-left corner, partially off-canvas.
            classMedallion(letter: "A", innerSize: 64)
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-medallionRotation))
                .offset(x: -28, y: 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            // Confetti particles
            confettiLayer
        }
        .allowsHitTesting(false)
    }

    private func classMedallion(letter: String, innerSize: CGFloat) -> some View {
        ZStack {
            // Sun-ray burst
            ForEach(0..<12, id: \.self) { i in
                Capsule()
                    .fill(theme.accentWarm.opacity(0.5))
                    .frame(width: 3, height: 14)
                    .offset(y: -(innerSize / 2 + 12))
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            // Inner disc
            Circle()
                .fill(
                    LinearGradient(
                        colors: [theme.accentWarmLight, theme.accentWarm],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: innerSize, height: innerSize)
            // Letter
            Text(letter)
                .font(.system(size: innerSize * 0.5, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
        }
        .opacity(0.32)
    }

    private var confettiLayer: some View {
        ZStack {
            ForEach(0..<22, id: \.self) { idx in
                let pos = confettiOffsets[idx % confettiOffsets.count]
                let size = confettiSizes[idx % confettiSizes.count]
                let useAmber = idx % 2 == 0
                Circle()
                    .fill(useAmber ? theme.accentWarmLight : theme.accentBright)
                    .opacity(useAmber ? 0.55 : 0.45)
                    .frame(width: size, height: size)
                    .position(x: pos.x, y: pos.y)
            }
        }
    }

    private var confettiOffsets: [CGPoint] {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        return [
            CGPoint(x: w * 0.10, y: h * 0.18),
            CGPoint(x: w * 0.88, y: h * 0.28),
            CGPoint(x: w * 0.22, y: h * 0.34),
            CGPoint(x: w * 0.78, y: h * 0.42),
            CGPoint(x: w * 0.05, y: h * 0.55),
            CGPoint(x: w * 0.92, y: h * 0.60),
            CGPoint(x: w * 0.30, y: h * 0.72),
            CGPoint(x: w * 0.85, y: h * 0.78),
            CGPoint(x: w * 0.15, y: h * 0.85),
            CGPoint(x: w * 0.66, y: h * 0.20),
            CGPoint(x: w * 0.42, y: h * 0.30),
        ]
    }

    private let confettiSizes: [CGFloat] = [6, 10, 8, 4, 12, 7, 9, 5, 11]

    private func animateIn() {
        withAnimation(.easeOut(duration: 1.4)) { count = finalCount }
        withAnimation(.easeOut(duration: 0.6).delay(1.0)) { subtitleOpacity = 1 }
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            medallionRotation = 8
        }
        for idx in 0..<cards.count {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.45 + Double(idx) * 0.12)) {
                visibleCards = idx + 1
            }
        }
    }
}
