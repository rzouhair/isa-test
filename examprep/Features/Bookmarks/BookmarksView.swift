import SwiftUI
import SwiftData
import Inject

struct BookmarksView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var rows: [(QuestionDTO, [AnswerDTO])] = []
    @State private var licenseCode: String = Constants.licenseCode
    @State private var error: String?

    var body: some View {
        Group {
            if rows.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(rows, id: \.0.id) { pair in
                        Button {
                            startSingle(questionId: pair.0.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pair.0.text)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                if let correct = pair.1.first(where: { $0.isCorrect == 1 }) {
                                    Text("Correct: \(correct.text)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                    .onDelete(perform: remove)
                }
            }
        }
        .navigationTitle("Bookmarks")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !rows.isEmpty {
                    Button("Study all") { startAll() }
                }
            }
        }
        .task { load() }
        .enableInjection()
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No bookmarks yet",
            systemImage: "bookmark",
            description: Text("Tap the bookmark icon during a quiz to save a question for later.")
        )
    }

    private func load() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let ids = progress.bookmarks()
        guard !ids.isEmpty else {
            rows = []
            return
        }
        do {
            rows = try DIContainer.shared.contentRepository.questions(ids: ids)
        } catch {
            self.error = "Couldn't load bookmarks: \(error.localizedDescription)"
        }
    }

    private func remove(at offsets: IndexSet) {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        let removed = offsets.map { rows[$0].0.id }
        for id in removed {
            try? progress.toggleBookmark(questionId: id)
        }
        rows.remove(atOffsets: offsets)
    }

    private func startSingle(questionId: Int) {
        startConfig(ids: [questionId])
    }

    private func startAll() {
        startConfig(ids: rows.map(\.0.id))
    }

    private func startConfig(ids: [Int]) {
        guard !ids.isEmpty else { return }
        let config = QuizConfig(
            kind: .bookmark,
            licenseCode: licenseCode,
            categoryCode: nil,
            questionIds: ids,
            passThreshold: 0.76,
            timeLimitSec: nil
        )
        router.startSession(.quizSession(config: config), gatedBy: appState)
    }
}
