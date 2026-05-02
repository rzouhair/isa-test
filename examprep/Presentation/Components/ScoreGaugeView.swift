import SwiftUI
import Inject

struct ScoreGaugeView: View {
    @ObserveInjection var inject
    /// 0.0 – 1.0
    let score: Double
    /// 0.0 – 1.0, determines pass tint.
    let passThreshold: Double

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.1, to: 0.9)
                .rotation(.degrees(90))
                .stroke(Color(.systemFill), style: StrokeStyle(lineWidth: 18, lineCap: .round))

            Circle()
                .trim(from: 0.1, to: 0.1 + 0.8 * score)
                .rotation(.degrees(90))
                .stroke(tint, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .animation(.easeOut(duration: 0.6), value: score)

            VStack(spacing: 4) {
                Text("\(Int(score * 100))%")
                    .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(tint)
                Text(passed ? "Passed" : "Keep practicing")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 180, height: 180)
        .enableInjection()
    }

    private var passed: Bool { score >= passThreshold }
    private var tint: Color { passed ? theme.accent : theme.accentWarm }
}
