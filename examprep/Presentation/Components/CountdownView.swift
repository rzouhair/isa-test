import SwiftUI
import Inject

struct CountdownView: View {
    @ObserveInjection var inject
    let secondsRemaining: TimeInterval

    var body: some View {
        HStack(spacing: 12) {
            tile(value: days, label: "days")
            tile(value: hours, label: "hrs")
            tile(value: minutes, label: "min")
            tile(value: seconds, label: "sec")
        }
        .enableInjection()
    }

    private var days: Int { Int(secondsRemaining) / 86_400 }
    private var hours: Int { (Int(secondsRemaining) % 86_400) / 3_600 }
    private var minutes: Int { (Int(secondsRemaining) % 3_600) / 60 }
    private var seconds: Int { Int(secondsRemaining) % 60 }

    private func tile(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 44)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
