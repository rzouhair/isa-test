import SwiftUI
import Inject

struct GradingProcessingView: View {
    @ObserveInjection var inject
    let message: String

    @State private var ringProgress: Double = 0
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.1), lineWidth: 6)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(
                        AngularGradient(
                            colors: [theme.accent.opacity(0.3), theme.accent],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 32))
                    .foregroundStyle(theme.accent)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: isAnimating)
            }

            VStack(spacing: 8) {
                Text("Analyzing Card")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: message)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            isAnimating = true
            withAnimation(.linear(duration: 30)) {
                ringProgress = 0.9
            }
        }
        .enableInjection()
    }
}
