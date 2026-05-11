import SwiftUI
import Inject

/// Compact exam-date pill: "Exam in Jan 22nd · 8 days left · Detail >"
/// Used on Stats dashboard. Tap opens the exam-date picker.
struct ExamCountdownPill: View {
    @ObserveInjection var inject

    let examDate: Date?
    let countdownSeconds: TimeInterval?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(theme.accent)

                if let examDate {
                    Text("Exam in \(Self.dateFormatter.string(from: examDate))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    if let days = daysRemaining {
                        Text("· \(days) day\(days == 1 ? "" : "s") left")
                            .font(.subheadline)
                            .foregroundStyle(urgencyColor(daysLeft: days))
                    }
                    Spacer()
                    HStack(spacing: 2) {
                        Text("Detail")
                            .font(.caption.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.bold))
                    }
                    .foregroundStyle(theme.accent)
                } else {
                    Text("Set your exam date")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(theme.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .enableInjection()
    }

    private var daysRemaining: Int? {
        guard let countdownSeconds, countdownSeconds > 0 else { return nil }
        return max(0, Int(countdownSeconds / 86_400))
    }

    private func urgencyColor(daysLeft: Int) -> Color {
        if daysLeft <= 3 { return theme.warning }
        if daysLeft <= 14 { return theme.accentWarm }
        return .secondary
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMM d")
        return f
    }()
}
