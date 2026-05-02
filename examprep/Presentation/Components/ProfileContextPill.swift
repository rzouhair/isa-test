import SwiftUI
import Inject
import SwiftData

struct ProfileContextPill: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @Query private var profiles: [UserExamProfile]
    @State private var stateName: String?

    private var profile: UserExamProfile? { profiles.first }

    var body: some View {
        Button {
            router.navigate(to: .statePicker)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.accent)
                Text(stateDisplay)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color(.tertiarySystemFill)))
        }
        .buttonStyle(.plain)
        .onAppear(perform: loadStateMeta)
        .onChange(of: profile?.stateCode) { _, _ in loadStateMeta() }
        .enableInjection()
    }

    private var stateDisplay: String {
        if let name = stateName, !name.isEmpty { return name }
        return profile?.stateCode.uppercased() ?? "Select state"
    }

    private func loadStateMeta() {
        guard let code = profile?.stateCode, !code.isEmpty else {
            stateName = nil
            return
        }
        let match = (try? DIContainer.shared.contentRepository.allStates())?
            .first(where: { $0.code == code })
        stateName = match?.name
    }
}
