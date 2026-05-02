import SwiftUI
import SwiftData
import Inject

struct HandbookCatalogEntry: Codable, Hashable, Identifiable {
    let state: String
    let abbr: String
    let handbookName: String
    let url: String
    let filename: String

    var id: String { abbr }
    var pdfURL: URL? { URL(string: url) }

    enum CodingKeys: String, CodingKey {
        case state, abbr, url, filename
        case handbookName = "handbook_name"
    }
}

struct HandbookView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var entries: [HandbookCatalogEntry] = []
    @State private var error: String?
    @State private var query: String = ""
    @State private var userStateAbbr: String?

    var body: some View {
        Group {
            if !appState.isProUser {
                lockedState
            } else if let error {
                ContentUnavailableView(error, systemImage: "book.closed")
            } else if entries.isEmpty {
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                list
                    .searchable(text: $query, prompt: "Search states")
            }
        }
        .navigationTitle("Handbooks")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .enableInjection()
    }

    private var lockedState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundStyle(theme.accent)
            Text("Pro feature")
                .font(.title3.weight(.semibold))
            Text("State CDL handbooks are part of the Pro plan.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "handbook"])
                appState.showPaywall()
            } label: {
                Text("Unlock Pro")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.accent)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private var filtered: [HandbookCatalogEntry] {
        guard !query.isEmpty else { return entries }
        let q = query.lowercased()
        return entries.filter {
            $0.state.lowercased().contains(q) || $0.abbr.lowercased().contains(q)
        }
    }

    private var list: some View {
        List {
            if let abbr = userStateAbbr,
               let mine = entries.first(where: { $0.abbr == abbr }),
               query.isEmpty {
                Section("Your state") {
                    row(entry: mine)
                }
            }
            Section("All states") {
                ForEach(filtered) { entry in
                    row(entry: entry)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func row(entry: HandbookCatalogEntry) -> some View {
        if let url = entry.pdfURL {
            Link(destination: url) {
                HStack(spacing: 12) {
                    Text(entry.abbr)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.state)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(entry.handbookName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
        }
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "handbooks", withExtension: "json") else {
            error = "Handbooks catalog missing from bundle."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            entries = try JSONDecoder().decode([HandbookCatalogEntry].self, from: data)
        } catch {
            self.error = "Couldn't load handbooks: \(error.localizedDescription)"
            return
        }
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        userStateAbbr = progress.profile()?.stateCode
    }
}
