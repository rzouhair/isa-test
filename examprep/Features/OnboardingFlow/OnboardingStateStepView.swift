import SwiftUI
import SwiftData
import Inject

struct OnboardingStateStepView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    let onAdvance: () -> Void

    @State private var states: [StateDTO] = []
    @State private var query: String = ""
    @State private var selected: String?

    private var filtered: [StateDTO] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return states }
        let q = query.lowercased()
        return states.filter { $0.name.lowercased().contains(q) || $0.code.lowercased().contains(q) }
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 6) {
                Text("Where are you taking it?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Questions vary by state — we tailor yours.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
            .padding(.top, 8)

            searchBar
                .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filtered, id: \.id) { state in
                        stateRow(state: state)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .task { load() }
        .enableInjection()
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.white.opacity(0.5))
            TextField("", text: $query, prompt: Text("Search states").foregroundStyle(Color.white.opacity(0.4)))
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .tint(theme.accentBright)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .clipShape(Capsule())
    }

    private func stateRow(state: StateDTO) -> some View {
        let isSelected = selected == state.code
        return Button {
            select(state: state)
        } label: {
            HStack {
                Text(state.name)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                Spacer()
                Text(state.code)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color.white.opacity(0.5))
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accentBright)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white.opacity(isSelected ? 0.1 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func load() {
        states = (try? DIContainer.shared.contentRepository.allStates()) ?? []
    }

    private func select(state: StateDTO) {
        selected = state.code
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let existing = progress.profile()
        try? progress.setProfile(
            licenseCode: existing?.licenseCode ?? "cdl",
            stateCode: state.code,
            examDate: existing?.examDate
        )
        DIContainer.shared.analyticsService.capture(.stateSelected, properties: ["state": state.code, "source": "onboarding"])
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onAdvance()
        }
    }
}
