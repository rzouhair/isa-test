import SwiftUI
import SwiftData
import Inject

struct EditStateView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var states: [StateDTO] = []
    @State private var query: String = ""
    @State private var currentCode: String = ""
    @State private var error: String?

    private var filtered: [StateDTO] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return states }
        let q = query.lowercased()
        return states.filter { $0.name.lowercased().contains(q) || $0.code.lowercased().contains(q) }
    }

    var body: some View {
        List {
            ForEach(filtered, id: \.id) { state in
                Button {
                    select(state)
                } label: {
                    HStack {
                        Text(state.name).foregroundStyle(.primary)
                        Spacer()
                        Text(state.code).font(.caption).foregroundStyle(.secondary)
                        if state.code == currentCode {
                            Image(systemName: "checkmark").foregroundStyle(theme.accent)
                        }
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search states")
        .navigationTitle("State")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .enableInjection()
    }

    private func load() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        currentCode = progress.profile()?.stateCode ?? ""
        states = (try? DIContainer.shared.contentRepository.allStates()) ?? []
    }

    private func select(_ state: StateDTO) {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let existing = progress.profile()
        do {
            try progress.setProfile(
                licenseCode: existing?.licenseCode ?? "cdl",
                stateCode: state.code,
                examDate: existing?.examDate
            )
            DIContainer.shared.analyticsService.capture(.stateSelected, properties: ["state": state.code, "source": "settings"])
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } catch {
            self.error = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
