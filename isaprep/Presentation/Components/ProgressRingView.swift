import SwiftUI
import Inject

struct ProgressRingView: View {
    @ObserveInjection var inject
    /// 0.0 – 1.0
    let value: Double
    var lineWidth: CGFloat = 8
    var tint: Color = theme.accent

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, value)))
                .rotation(.degrees(-90))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .animation(.easeOut(duration: 0.5), value: value)
        }
        .enableInjection()
    }
}
