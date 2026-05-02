import SwiftUI
import SwiftData
import Inject

struct ReviewSessionView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let sessionId: UUID

    @State private var rows: [ReviewRow] = []
    @State private var error: String?

    struct ReviewRow: Identifiable {
        let question: QuestionDTO
        let answers: [AnswerDTO]
        let selectedAnswerId: Int?
        let correct: Bool
        var id: Int { question.id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let error {
                    Text(error).foregroundStyle(.secondary).padding()
                }
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    reviewCard(index: index, row: row)
                }
            }
            .padding(16)
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard appState.isProUser else {
                DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "session_gate"])
                router.navigateBack()
                appState.showPaywall()
                return
            }
            load()
        }
        .enableInjection()
    }

    private func reviewCard(index: Int, row: ReviewRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Q\(index + 1)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: row.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(row.correct ? .green : .red)
            }
            Text(row.question.text)
                .font(.headline)

            VStack(spacing: 6) {
                ForEach(row.answers, id: \.id) { answer in
                    answerRow(answer: answer, selected: row.selectedAnswerId == answer.id)
                }
            }

            if let explanation = row.question.explanation, !explanation.isEmpty {
                Text(explanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func answerRow(answer: AnswerDTO, selected: Bool) -> some View {
        let correct = answer.isCorrect == 1
        let bg: Color = {
            if correct { return Color.green.opacity(0.15) }
            if selected { return Color.red.opacity(0.15) }
            return Color(.tertiarySystemGroupedBackground)
        }()
        return HStack {
            Text(answer.text)
                .font(.callout)
            Spacer()
            if correct {
                Image(systemName: "checkmark").foregroundStyle(.green)
            } else if selected {
                Image(systemName: "xmark").foregroundStyle(.red)
            }
        }
        .padding(10)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func load() {
        let id = sessionId
        let predicate = #Predicate<PracticeSession> { $0.id == id }
        var desc = FetchDescriptor<PracticeSession>(predicate: predicate)
        desc.fetchLimit = 1
        guard let session = (try? modelContext.fetch(desc))?.first else {
            error = "Session not found."
            return
        }
        let answersById = Dictionary(
            uniqueKeysWithValues: session.answers.map { ($0.questionId, $0) }
        )
        do {
            let fetched = try DIContainer.shared.contentRepository.questions(ids: session.questionIds)
            rows = fetched.map { (q, options) in
                let sa = answersById[q.id]
                return ReviewRow(
                    question: q,
                    answers: options,
                    selectedAnswerId: sa?.selectedAnswerId,
                    correct: sa?.correct ?? false
                )
            }
        } catch {
            self.error = "Couldn't load review: \(error.localizedDescription)"
        }
    }
}
