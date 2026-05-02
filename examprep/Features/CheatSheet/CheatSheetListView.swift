import SwiftUI
import SwiftData
import Inject

struct CheatSheetListView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    @State private var sheets: [CheatSheetDTO] = []
    @State private var error: String?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(sheets.enumerated()), id: \.element.id) { idx, sheet in
                    card(sheet: sheet, index: idx)
                }
            }
            .padding(16)

            if let error {
                Text(error).font(.caption).foregroundStyle(.secondary).padding()
            }
        }
        .navigationTitle("Cheat Sheets")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .enableInjection()
    }

    private func card(sheet: CheatSheetDTO, index: Int) -> some View {
        let locked = index >= Constants.cheatSheetsFreeCount && !appState.isProUser

        return Button {
            if locked {
                DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "cheat_sheet"])
                appState.showPaywall()
            } else {
                DIContainer.shared.analyticsService.capture(.cheatSheetViewed, properties: ["id": sheet.id])
                router.navigate(to: .cheatSheetDetail(id: sheet.id))
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "book.pages")
                        .font(.title3)
                        .foregroundStyle(theme.accent)
                    Spacer()
                    if locked {
                        Image(systemName: "lock.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(sheet.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                Text(locked ? "Pro" : "Free")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(locked ? theme.accent : .secondary)
                    .textCase(.uppercase)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func load() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let profile = progress.profile()
        let licenseCode = profile?.licenseCode ?? "cdl"
        let stateCode = profile?.stateCode
        let lang = profile?.preferredLang ?? "en"
        do {
            sheets = try DIContainer.shared.contentRepository.cheatSheets(
                licenseCode: licenseCode,
                stateCode: stateCode,
                lang: lang
            )
        } catch {
            self.error = "Couldn't load cheat sheets: \(error.localizedDescription)"
        }
    }
}
