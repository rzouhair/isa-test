import SwiftUI
import Inject

/// Per-category dashboard card: icon + name, horizontal practice progress bar
/// with attempted/total caption, and an average test score row underneath.
struct CategoryProgressCard: View {
    @ObserveInjection var inject

    let progress: CategoryProgress
    let accent: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 10) {
                header
                practiceBar
                averageScoreRow
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .enableInjection()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: progress.iconName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(accent)
            }
            Text(progress.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Practice bar

    private var practiceBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("Practice")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text("\(progress.attemptedDistinct)/\(progress.totalQuestions)")
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                    Capsule()
                        .fill(accent)
                        .frame(width: max(4, geo.size.width * progress.completionRatio))
                }
            }
            .frame(height: 8)
        }
    }

    // MARK: - Avg score

    private var averageScoreRow: some View {
        HStack(spacing: 6) {
            Text("Avg. Test Score")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(scoreText)
                .font(.caption.weight(.bold).monospacedDigit())
                .foregroundStyle(scoreColor)
        }
    }

    private var scoreText: String {
        if progress.avgTestScore == 0 {
            return "—"
        }
        return String(format: "%.1f%%", progress.avgTestScore * 100)
    }

    private var scoreColor: Color {
        if progress.avgTestScore == 0 { return .secondary }
        switch progress.avgTestScore {
        case 0..<0.5: return theme.scoreLow
        case 0.5..<0.75: return theme.scoreMid
        default: return theme.scoreHigh
        }
    }
}
