import SwiftUI
import Inject

/// Large donut showing overall readiness percentage, with a right-side legend
/// listing top-N category completion ratios each paired with a colored dot.
struct ReadinessDonutWithLegend: View {
    @ObserveInjection var inject

    struct LegendItem: Identifiable, Hashable {
        let id: String           // category code
        let name: String
        let ratio: Double        // 0–1, completion
        let color: Color
    }

    let passing: Double          // 0–1
    let legend: [LegendItem]     // top N items (caller caps)

    private let donutSize: CGFloat = 128
    private let lineWidth: CGFloat = 12

    var body: some View {
        HStack(alignment: .center, spacing: 20) {
            donut
            legendList
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .enableInjection()
    }

    // MARK: - Donut

    private var donut: some View {
        let tint = passingTint(for: passing)
        return ZStack {
            Circle()
                .stroke(Color(.systemFill), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, passing)))
                .rotation(.degrees(-90))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .animation(.easeOut(duration: 0.5), value: passing)

            VStack(spacing: 0) {
                Text("\(Int(passing * 100))%")
                    .font(.system(size: 28, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(tint)
                Text("ready")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: donutSize, height: donutSize)
    }

    // MARK: - Legend

    private var legendList: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(legend) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(item.color)
                        .frame(width: 10, height: 10)
                    Text(item.name)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text("\(Int(item.ratio * 100))%")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            if legend.isEmpty {
                Text("Practice to see your breakdown.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Colors

    private func passingTint(for value: Double) -> Color {
        switch value {
        case 0: return Color(.systemGray3)
        case 0..<0.5: return theme.scoreLow
        case 0.5..<0.75: return theme.scoreMid
        default: return theme.scoreHigh
        }
    }
}

/// Shared 2-hue palette derived from theme tokens. Alternates primary and
/// warm accent, then fades through opacity stops for distinctness.
enum CategoryPalette {
    static func color(at index: Int) -> Color {
        let hues: [Color] = [theme.accent, theme.accentWarm]
        let fades: [Double] = [1.0, 0.7, 0.45]
        let base = hues[index % hues.count]
        let fade = fades[(index / hues.count) % fades.count]
        return base.opacity(fade)
    }
}
