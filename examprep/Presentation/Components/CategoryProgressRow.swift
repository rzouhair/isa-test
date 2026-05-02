import SwiftUI
import Inject

struct CategoryProgressRow: View {
    @ObserveInjection var inject
    let name: String
    let avgScore: Double     // 0.0 – 1.0
    let attempts: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ProgressRingView(value: avgScore)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("\(Int(avgScore * 100))")
                            .font(.caption2.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.primary)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(attempts == 0 ? "No attempts yet" : "\(attempts) attempt\(attempts == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .enableInjection()
    }
}
