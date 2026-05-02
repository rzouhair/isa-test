import SwiftUI
import SwiftData
import Inject

struct StateSelectView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext

    @State private var all: [StateDTO] = []
    @State private var query: String = ""
    @State private var error: String?

    private var filtered: [StateDTO] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        let q = query.lowercased()
        return all.filter { $0.name.lowercased().contains(q) || $0.code.lowercased().contains(q) }
    }

    var body: some View {
        List {
            if let error {
                Text(error).foregroundStyle(.secondary)
            }
            ForEach(filtered, id: \.id) { state in
                Button {
                    select(state)
                } label: {
                    HStack {
                        Text(state.name).foregroundStyle(.primary)
                        Spacer()
                        Text(state.code).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Search states")
        .navigationTitle("State")
        .task { load() }
        .enableInjection()
    }

    private func load() {
        do {
            all = try DIContainer.shared.contentRepository.allStates()
        } catch {
            self.error = "Couldn't load states: \(error.localizedDescription)"
        }
    }

    private func select(_ state: StateDTO) {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let existing = progress.profile()
        let licenseCode = existing?.licenseCode ?? "cdl"
        do {
            try progress.setProfile(
                licenseCode: licenseCode,
                stateCode: state.code,
                examDate: existing?.examDate
            )
            DIContainer.shared.analyticsService.capture(.stateSelected, properties: ["state": state.code])
            router.navigateToRoot()
        } catch {
            self.error = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
