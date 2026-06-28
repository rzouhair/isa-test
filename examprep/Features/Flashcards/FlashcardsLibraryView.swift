import SwiftUI
import Inject
import SwiftData

struct FlashcardsLibraryView: View {
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FlashcardsLibraryViewModel?
    @ObserveInjection var inject

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                quickActions
                topicGrid
                disclaimer
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    router.navigate(to: .flashcardBookmarks)
                } label: {
                    Image(systemName: "bookmark")
                }
            }
        }
        .task {
            if viewModel == nil {
                viewModel = FlashcardsLibraryViewModel(
                    progress: DIContainer.shared.userProgressRepository(context: modelContext)
                )
            }
            viewModel?.reload()
        }
        .onAppear { viewModel?.reload() }
        .enableInjection()
    }

    @ViewBuilder
    private var header: some View {
        if let vm = viewModel {
            VStack(alignment: .leading, spacing: 6) {
                Text("Atomic Reference Cards")
                    .font(.title2.bold())
                Text("\(vm.totalCards) cards across \(vm.decks.count) ISA topics. \(vm.totalDue) due now.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private var quickActions: some View {
        if let vm = viewModel {
            VStack(spacing: 10) {
                quickActionRow(
                    title: "Due Today",
                    detail: vm.totalDue == 0 ? "Nothing due — try a topic deck" : "\(vm.totalDue) cards waiting",
                    iconName: "clock.badge.exclamationmark.fill",
                    tint: theme.accentWarm,
                    enabled: vm.totalDue > 0
                ) {
                    router.startSession(
                        .flashcardSession(config: FlashcardDeckConfig(categoryCode: nil, flashcardIds: nil, dueOnly: true)),
                        gatedBy: appState
                    )
                }
                quickActionRow(
                    title: "Study All",
                    detail: "Shuffle all \(vm.totalCards) cards",
                    iconName: "rectangle.stack.fill",
                    tint: theme.accent,
                    enabled: vm.totalCards > 0
                ) {
                    router.startSession(
                        .flashcardSession(config: FlashcardDeckConfig(categoryCode: nil, flashcardIds: nil, dueOnly: false)),
                        gatedBy: appState
                    )
                }
            }
        }
    }

    private func quickActionRow(
        title: String,
        detail: String,
        iconName: String,
        tint: Color,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.18))
                    Image(systemName: iconName)
                        .font(.title3.bold())
                        .foregroundStyle(tint)
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
    }

    @ViewBuilder
    private var topicGrid: some View {
        if let vm = viewModel {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(vm.decks) { deck in
                    Button {
                        router.startSession(
                            .flashcardSession(config: FlashcardDeckConfig(
                                categoryCode: deck.categoryCode,
                                flashcardIds: nil,
                                dueOnly: false
                            )),
                            gatedBy: appState
                        )
                    } label: {
                        deckTile(deck)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func deckTile(_ deck: FlashcardsLibraryViewModel.Deck) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: deck.iconName)
                    .font(.title3.bold())
                    .foregroundStyle(theme.accent)
                Spacer()
                if deck.dueCount > 0 {
                    Text("\(deck.dueCount)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(theme.accentWarm.opacity(0.18))
                        .foregroundStyle(theme.accentWarm)
                        .clipShape(Capsule())
                }
            }
            Text(deck.title)
                .font(.subheadline.bold())
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            ProgressView(value: deck.progress)
                .tint(theme.accent)
            Text("\(deck.masteredCount)/\(deck.total) mastered")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var disclaimer: some View {
        Text("AI-authored study cards aligned to ISA standards. Not actual exam content.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
