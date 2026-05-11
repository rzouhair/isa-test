import SwiftUI
import SwiftData
import Inject

struct QuizSessionView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialConfig: QuizConfig?
    let resumingSessionId: UUID?

    init(config: QuizConfig) {
        self.initialConfig = config
        self.resumingSessionId = nil
    }

    init(resumingSessionId: UUID) {
        self.initialConfig = nil
        self.resumingSessionId = resumingSessionId
    }

    @State private var vm: QuizSessionViewModel?
    @State private var showExit = false
    @State private var bookmarkTick: Int = 0

    var body: some View {
        Group {
            if let vm {
                content(vm: vm)
            } else {
                ProgressView().controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showExit = true
                } label: {
                    Image(systemName: "xmark")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                bookmarkToolbarButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                aiTutorToolbarButton
            }
        }
        .task {
            // Defensive Pro gate — catches deep links, restored nav stacks,
            // and subscription lapses mid-session.
            guard appState.isProUser else {
                DIContainer.shared.analyticsService.capture(.paywallViewed, properties: ["source": "session_gate"])
                router.navigateBack()
                appState.showPaywall()
                return
            }
            guard vm == nil else { return }
            let content = DIContainer.shared.contentRepository
            let progress = DIContainer.shared.userProgressRepository(context: modelContext)
            let model: QuizSessionViewModel
            if let resumeId = resumingSessionId {
                model = QuizSessionViewModel(resumingSessionId: resumeId, content: content, progress: progress)
            } else if let cfg = initialConfig {
                model = QuizSessionViewModel(config: cfg, content: content, progress: progress)
            } else {
                return
            }
            await model.load()
            vm = model
        }
        .alert("Leave quiz?", isPresented: $showExit) {
            Button("Cancel", role: .cancel) {}
            Button("Save & Leave") {
                router.navigateBack()
            }
            Button("Discard", role: .destructive) {
                if let id = vm?.sessionId {
                    let progress = DIContainer.shared.userProgressRepository(context: modelContext)
                    try? progress.deleteSession(id: id)
                }
                router.navigateBack()
            }
        } message: {
            Text("Save to resume later, or discard this attempt.")
        }
        .onChange(of: vm?.finished ?? false) { _, done in
            if done, let id = vm?.sessionId {
                router.replaceTop(with: .quizResult(sessionId: id))
            }
        }
        .enableInjection()
    }

    @ViewBuilder
    private var bookmarkToolbarButton: some View {
        if let qid = vm?.currentQuestion?.id {
            let progress = DIContainer.shared.userProgressRepository(context: modelContext)
            let _ = bookmarkTick   // invalidate on toggle
            let isBookmarked = progress.isBookmarked(qid)
            Button {
                try? progress.toggleBookmark(questionId: qid)
                DIContainer.shared.analyticsService.capture(.bookmarkToggled, properties: ["question_id": qid])
                bookmarkTick &+= 1
            } label: {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
            }
        }
    }

    @ViewBuilder
    private var aiTutorToolbarButton: some View {
        if Constants.aiTutorEnabled,
           let vm,
           vm.revealed,
           let qid = vm.currentQuestion?.id,
           let last = vm.results.last,
           !last.correct {
            Button {
                router.navigate(to: .aiTutor(questionId: qid))
            } label: {
                Image(systemName: "sparkles")
            }
        }
    }

    @ViewBuilder
    private func content(vm: QuizSessionViewModel) -> some View {
        if vm.loading {
            ProgressView("Loading questions…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.questions.isEmpty {
            ContentUnavailableView(
                "No questions",
                systemImage: "questionmark.circle",
                description: Text("Couldn't find questions for this set.")
            )
        } else {
            sessionBody(vm: vm)
        }
    }

    @ViewBuilder
    private func sessionBody(vm: QuizSessionViewModel) -> some View {
        VStack(spacing: 0) {
            header(vm: vm)
            ScrollView {
                VStack(spacing: 14) {
                    if let q = vm.currentQuestion {
                        QuestionCardView(text: q.text, imageName: q.imageName)
                    }
                    ForEach(vm.currentAnswers, id: \.id) { answer in
                        AnswerOptionButton(
                            text: answer.text,
                            state: vm.buttonState(for: answer),
                            action: { vm.select(answerId: answer.id) }
                        )
                    }
                }
                .padding(16)
            }
            // Explanation + Continue live in a pinned bottom area, OUTSIDE
            // the ScrollView, so the question + answers above never reflow
            // when the explanation appears.
            revealPanel(vm: vm)
        }
        .task(id: vm.sessionId) {
            while !vm.finished {
                try? await Task.sleep(for: .seconds(1))
                vm.tickTimer()
            }
        }
    }

    @ViewBuilder
    private func revealPanel(vm: QuizSessionViewModel) -> some View {
        VStack(spacing: 10) {
            if vm.revealed,
               vm.showsExplanationOnReveal,
               let explanation = vm.currentQuestion?.explanation,
               !explanation.isEmpty {
                explanationCard(
                    explanation: explanation,
                    correct: vm.results.last?.correct ?? false
                )
            }
            continueRow(vm: vm)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(alignment: .top) { Divider() }
    }

    private func header(vm: QuizSessionViewModel) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("\(vm.currentIndex + 1) / \(vm.totalCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                if vm.isResumed {
                    resumedBadge
                }
                Spacer()
                timerLabel(vm: vm)
            }
            ProgressView(value: Double(vm.currentIndex + 1), total: Double(max(vm.totalCount, 1)))
                .tint(theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var resumedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "arrow.clockwise")
                .font(.caption2.weight(.bold))
            Text("Resumed")
                .font(.caption2.weight(.semibold))
        }
        .foregroundStyle(theme.accent)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(theme.accent.opacity(0.12))
        .clipShape(Capsule())
    }

    @ViewBuilder
    private func timerLabel(vm: QuizSessionViewModel) -> some View {
        if let limit = vm.config.timeLimitSec {
            let remaining = max(0, Double(limit) - vm.elapsed)
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.caption2.weight(.semibold))
                Text(timeString(remaining))
                    .font(.caption.monospacedDigit().weight(.semibold))
            }
            .foregroundStyle(remaining < 300 ? .red : .secondary)
        } else {
            Text(timeString(vm.elapsed))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func explanationCard(explanation: String, correct: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: correct ? "checkmark" : "info.circle")
                    .font(.caption.weight(.semibold))
                Text(correct ? "Correct" : "Why")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
            }
            .foregroundStyle(correct ? Color.green : .secondary)
            Text(explanation)
                .font(.callout)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            HStack(spacing: 0) {
                Rectangle()
                    .fill(correct ? Color.green : theme.accent)
                    .frame(width: 3)
                Spacer()
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        )
    }

    @ViewBuilder
    private func continueRow(vm: QuizSessionViewModel) -> some View {
        let isLast = vm.currentIndex + 1 >= vm.totalCount
        let continueEnabled = vm.revealed || (vm.config.kind == .simulator && vm.selectedAnswerId != nil)

        HStack(spacing: 10) {
            if vm.allowsSkip && !vm.revealed {
                Button { vm.skip() } label: {
                    Text("Skip")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Button {
                vm.next()
            } label: {
                Text(isLast ? "Finish" : "Continue")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(continueEnabled ? theme.accent : Color(.systemFill))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!continueEnabled)
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
