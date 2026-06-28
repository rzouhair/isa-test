import SwiftUI
import Inject

/// "Realistic exam simulator" — animated gauge fills up then flips to a
/// "PASSED" stamp.
struct OnboardingValueProp2View: View {
    @ObserveInjection var inject

    @State private var gaugeProgress: Double = 0
    @State private var showStamp: Bool = false
    @State private var stampRotation: Double = -10
    @State private var copyOpacity: Double = 0

    private let targetScore: Double = 0.95

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            gauge
                .frame(height: 240)

            VStack(spacing: 8) {
                Text("Realistic ISA mock exam")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(copyOpacity)

                Text("200 questions. 210 minutes. 76% to pass — just like the real ISA Certified Arborist exam.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .opacity(copyOpacity)
            }

            Spacer()
        }
        .onAppear { animateIn() }
        .enableInjection()
    }

    private var gauge: some View {
        ZStack {
            Circle()
                .trim(from: 0.1, to: 0.9)
                .rotation(.degrees(90))
                .stroke(Color.white.opacity(0.1), style: StrokeStyle(lineWidth: 16, lineCap: .round))

            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * gaugeProgress)
                .rotation(.degrees(90))
                .stroke(
                    LinearGradient(
                        colors: [theme.accentBright, theme.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .animation(.easeOut(duration: 1.2), value: gaugeProgress)

            VStack(spacing: 6) {
                Text("\(Int(gaugeProgress * 100))%")
                    .font(.system(size: 54, weight: .heavy, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text("mock exam")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .textCase(.uppercase)
            }

            if showStamp {
                Text("PASSED")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .kerning(2)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(theme.accent.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .rotationEffect(.degrees(stampRotation))
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                    .offset(x: 60, y: -70)
                    .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .frame(width: 240, height: 240)
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 1.2).delay(0.15)) {
            gaugeProgress = targetScore
        }
        withAnimation(.easeOut(duration: 0.5).delay(1.2)) {
            copyOpacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.55)) {
                showStamp = true
                stampRotation = -12
            }
        }
    }
}
