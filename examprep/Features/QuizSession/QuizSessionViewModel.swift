import Foundation
import Observation

@MainActor
@Observable
final class QuizSessionViewModel {
    private(set) var config: QuizConfig

    let resumingSessionId: UUID?
    private(set) var isResumed: Bool = false

    private(set) var questions: [(QuestionDTO, [AnswerDTO])] = []
    private(set) var currentIndex: Int = 0
    private(set) var revealed: Bool = false
    private(set) var selectedAnswerId: Int?
    private(set) var sessionId: UUID = UUID()
    private(set) var elapsed: TimeInterval = 0
    private(set) var loading: Bool = true
    private(set) var finished: Bool = false

    /// Accumulated answers (questionId, correct, timeMs) — source of truth
    /// for scoring and for the result screen breakdown.
    private(set) var results: [AnswerResult] = []

    struct AnswerResult: Hashable {
        let questionId: Int
        let correct: Bool
        let timeMs: Int
    }

    private let content: ContentRepositoryProtocol
    private let progress: UserProgressRepositoryProtocol
    private let analytics: AnalyticsServiceProtocol
    private let now: () -> Date

    private var startedAt: Date = Date()
    private var questionStartedAt: Date = Date()

    init(config: QuizConfig,
         content: ContentRepositoryProtocol,
         progress: UserProgressRepositoryProtocol,
         analytics: AnalyticsServiceProtocol = DIContainer.shared.analyticsService,
         now: @escaping () -> Date = Date.init) {
        self.config = config
        self.resumingSessionId = nil
        self.content = content
        self.progress = progress
        self.analytics = analytics
        self.now = now
    }

    init(resumingSessionId: UUID,
         content: ContentRepositoryProtocol,
         progress: UserProgressRepositoryProtocol,
         analytics: AnalyticsServiceProtocol = DIContainer.shared.analyticsService,
         now: @escaping () -> Date = Date.init) {
        self.config = QuizConfig(
            kind: .practice,
            licenseCode: "",
            stateCode: "",
            categoryCode: nil,
            questionIds: [],
            passThreshold: 0.8,
            timeLimitSec: nil
        )
        self.resumingSessionId = resumingSessionId
        self.content = content
        self.progress = progress
        self.analytics = analytics
        self.now = now
    }

    // MARK: Lifecycle

    private var didLoad = false

    func load() async {
        // Guard against accidental re-load (e.g., view re-identification).
        guard !didLoad else {
            #if DEBUG
            print("[Quiz] load() called again — ignoring")
            #endif
            return
        }
        didLoad = true
        loading = true
        defer { loading = false }

        if let resumeId = resumingSessionId {
            await resumeLoad(resumeId: resumeId)
        } else {
            await freshLoad()
        }
    }

    private func freshLoad() async {
        do {
            let fetched = try content.questions(ids: config.questionIds)
            questions = fetched

            let session = PracticeSession(
                kind: config.kind,
                licenseCode: config.licenseCode,
                stateCode: config.stateCode,
                categoryCode: config.categoryCode,
                questionIds: config.questionIds,
                passThreshold: config.passThreshold,
                timeLimitSec: config.timeLimitSec
            )
            sessionId = session.id
            try progress.createSession(session)

            startedAt = now()
            questionStartedAt = now()
            analytics.capture(.quizStarted, properties: [
                "kind": config.kind.rawValue,
                "category": config.categoryCode ?? "mixed",
                "question_count": questions.count,
                "resumed": false,
            ])
            #if DEBUG
            print("[Quiz] loaded \(questions.count) questions, sessionId=\(sessionId)")
            #endif
        } catch {
            questions = []
            #if DEBUG
            print("[Quiz] load() failed: \(error)")
            #endif
        }
    }

    private func resumeLoad(resumeId: UUID) async {
        guard let session = progress.session(id: resumeId) else {
            questions = []
            #if DEBUG
            print("[Quiz] resume failed: session \(resumeId) not found")
            #endif
            return
        }

        // Reconstruct config from stored session so downstream UI & rules match.
        self.config = QuizConfig(
            kind: session.kind,
            licenseCode: session.licenseCode,
            stateCode: session.stateCode,
            categoryCode: session.categoryCode,
            questionIds: session.questionIds,
            passThreshold: session.passThreshold,
            timeLimitSec: session.timeLimitSec
        )
        self.sessionId = resumeId

        do {
            let fetched = try content.questions(ids: config.questionIds)
            questions = fetched
        } catch {
            questions = []
            return
        }

        // Replay prior answers into results for scoring at finish.
        let ordered = session.answers.sorted { $0.answeredAt < $1.answeredAt }
        let answeredIds = Set(ordered.map(\.questionId))
        results = ordered.map { AnswerResult(questionId: $0.questionId, correct: $0.correct, timeMs: $0.timeMs) }

        // Position at first question whose id is not in answered set.
        if let nextIdx = config.questionIds.firstIndex(where: { !answeredIds.contains($0) }) {
            currentIndex = nextIdx
        } else {
            // Every question already answered — auto-finish.
            currentIndex = max(0, questions.count - 1)
            finish()
            return
        }

        revealed = false
        selectedAnswerId = nil
        // Reconstruct startedAt so `elapsed = now - startedAt` equals stored seconds.
        // Falls back to session.startedAt for legacy rows (elapsedSecAtPause == 0).
        if session.elapsedSecAtPause > 0 {
            startedAt = now().addingTimeInterval(-TimeInterval(session.elapsedSecAtPause))
        } else {
            startedAt = session.startedAt
        }
        questionStartedAt = now()
        isResumed = true

        analytics.capture(.quizStarted, properties: [
            "kind": config.kind.rawValue,
            "category": config.categoryCode ?? "mixed",
            "question_count": questions.count,
            "resumed": true,
            "answered_so_far": results.count,
        ])
        #if DEBUG
        print("[Quiz] resumed sessionId=\(resumeId) at idx=\(currentIndex) with \(results.count) prior answers")
        #endif
    }

    // MARK: Derived state

    var currentQuestion: QuestionDTO? { questions[safe: currentIndex]?.0 }
    var currentAnswers: [AnswerDTO] { questions[safe: currentIndex]?.1 ?? [] }
    var totalCount: Int { questions.count }
    var correctCount: Int { results.filter(\.correct).count }
    var answeredCount: Int { results.count }
    var totalTimeMs: Int { results.map(\.timeMs).reduce(0, +) }
    var score: Double {
        guard !results.isEmpty else { return 0 }
        return Double(correctCount) / Double(results.count)
    }
    var passed: Bool { score >= config.passThreshold }

    var showsExplanationOnReveal: Bool { config.kind != .simulator }
    var allowsSkip: Bool { config.kind != .simulator }

    func buttonState(for answer: AnswerDTO) -> AnswerOptionState {
        guard revealed else {
            return selectedAnswerId == answer.id ? .selected : .idle
        }
        if answer.isCorrect == 1 { return .correct }
        if selectedAnswerId == answer.id { return .incorrect }
        return .disabled
    }

    // MARK: Actions

    func select(answerId: Int) {
        guard !revealed, currentQuestion != nil else { return }
        selectedAnswerId = answerId
        revealed = true

        let answers = currentAnswers
        let correct = answers.first { $0.id == answerId }?.isCorrect == 1
        let timeMs = max(0, Int(now().timeIntervalSince(questionStartedAt) * 1000))
        let qid = currentQuestion?.id ?? 0
        results.append(AnswerResult(questionId: qid, correct: correct, timeMs: timeMs))

        try? progress.recordAnswer(questionId: qid, correct: correct, timeMs: timeMs)
        try? progress.appendSessionAnswer(
            sessionId: sessionId,
            questionId: qid,
            selectedAnswerId: answerId,
            correct: correct,
            timeMs: timeMs
        )
        let elapsedSec = max(0, Int(now().timeIntervalSince(startedAt)))
        try? progress.updateSessionElapsed(id: sessionId, seconds: elapsedSec)

        analytics.capture(.questionAnswered, properties: [
            "correct": correct,
            "question_id": qid,
            "time_ms": timeMs,
        ])
    }

    func next() {
        #if DEBUG
        print("[Quiz] next() — idx=\(currentIndex) revealed=\(revealed) selected=\(String(describing: selectedAnswerId)) total=\(questions.count) finished=\(finished)")
        #endif

        guard !finished else { return }
        if config.kind == .simulator {
            guard selectedAnswerId != nil else { return }
        } else {
            guard revealed else { return }
        }

        if config.kind == .learn, let last = results.last, !last.correct,
           let current = questions[safe: currentIndex] {
            // Re-queue wrong question at the end.
            questions.append(current)
        }

        let nextIndex = currentIndex + 1
        if nextIndex < questions.count {
            currentIndex = nextIndex
            revealed = false
            selectedAnswerId = nil
            questionStartedAt = now()
            #if DEBUG
            print("[Quiz] advanced to idx=\(currentIndex)")
            #endif
        } else {
            #if DEBUG
            print("[Quiz] no more questions — finishing")
            #endif
            finish()
        }
    }

    func skip() {
        guard allowsSkip, !revealed else { return }
        if currentIndex + 1 < questions.count {
            currentIndex += 1
            questionStartedAt = now()
        } else {
            finish()
        }
    }

    func tickTimer() {
        elapsed = now().timeIntervalSince(startedAt)
        if let limit = config.timeLimitSec, Int(elapsed) >= limit, !finished {
            finish()
        }
    }

    func finish() {
        guard !finished else { return }
        finished = true
        try? progress.completeSession(id: sessionId, score: score)
        try? progress.incrementStreak(
            minutes: max(1, Int(totalTimeMs / 60_000)),
            questions: results.count
        )
        analytics.capture(.quizCompleted, properties: [
            "score": score,
            "passed": passed,
            "kind": config.kind.rawValue,
        ])
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
