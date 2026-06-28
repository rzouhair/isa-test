import SwiftUI
import Inject
import SwiftData

struct FlashcardBookmarksView: View {
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var savedCards: [FlashcardDTO] = []
    @ObserveInjection var inject

    var body: some View {
        Group {
            if savedCards.isEmpty {
                ContentUnavailableView {
                    Label("No saved cards", systemImage: "bookmark.slash")
                } description: {
                    Text("Tap the bookmark icon during a flashcard session to save cards for later review.")
                }
            } else {
                List {
                    Section {
                        Button {
                            router.startSession(
                                .flashcardSession(config: FlashcardDeckConfig(
                                    categoryCode: nil,
                                    flashcardIds: savedCards.map(\.id),
                                    dueOnly: false
                                )),
                                gatedBy: appState
                            )
                        } label: {
                            Label("Study all \(savedCards.count) saved cards", systemImage: "play.fill")
                                .font(.headline)
                                .foregroundStyle(theme.accent)
                        }
                    }
                    Section("Cards") {
                        ForEach(savedCards, id: \.id) { card in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(card.front).font(.subheadline.bold()).lineLimit(2)
                                Text(card.back).font(.caption).foregroundStyle(.secondary).lineLimit(3)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    let progress = DIContainer.shared.userProgressRepository(context: modelContext)
                                    try? progress.toggleFlashcardBookmark(flashcardId: card.id)
                                    reload()
                                } label: {
                                    Label("Remove", systemImage: "bookmark.slash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Saved Cards")
        .navigationBarTitleDisplayMode(.inline)
        .task { reload() }
        .onAppear { reload() }
        .enableInjection()
    }

    private func reload() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let ids = progress.flashcardBookmarks()
        let content = DIContainer.shared.contentRepository
        savedCards = (try? content.flashcards(ids: ids)) ?? []
    }
}
