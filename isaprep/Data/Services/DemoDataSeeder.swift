import Foundation
import SwiftData

/// Populates SwiftData with realistic ISA Arborist study progress for App Store screenshots.
///
/// Activate via Xcode scheme launch argument `--seed-demo` (DEBUG only).
/// Idempotent: wipes existing rows before insert, so screenshots stay reproducible.
@MainActor
enum DemoDataSeeder {

    static let launchArgument = "--seed-demo"

    static func shouldRun() -> Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains(launchArgument)
        #else
        return false
        #endif
    }

    static func seed(into context: ModelContext) {
        wipe(context)
        let now = Date()
        seedExamProfile(context, now: now)
        seedQuestionAttempts(context, now: now)
        seedSessions(context, now: now)
        seedStreaks(context, now: now)
        seedBookmarks(context)
        seedFlashcardReviews(context, now: now)
        try? context.save()
    }

    // MARK: - Wipe

    private static func wipe(_ context: ModelContext) {
        try? context.delete(model: SessionAnswer.self)
        try? context.delete(model: PracticeSession.self)
        try? context.delete(model: QuestionAttempt.self)
        try? context.delete(model: StudyStreak.self)
        try? context.delete(model: BookmarkedQuestion.self)
        try? context.delete(model: BookmarkedFlashcard.self)
        try? context.delete(model: FlashcardReview.self)
        try? context.delete(model: UserExamProfile.self)
    }

    // MARK: - Exam profile

    private static func seedExamProfile(_ context: ModelContext, now: Date) {
        let cal = Calendar.current
        let examDate = cal.date(byAdding: .day, value: 47, to: cal.startOfDay(for: now))
        let profile = UserExamProfile(licenseCode: "isa", examDate: examDate)
        profile.dailyGoalQuestions = 25
        context.insert(profile)
    }

    // MARK: - Question attempts (per-category progress story)

    /// Per-category progress targets for the topic grid + stats screens.
    /// Story: user is strongest in Tree Biology, weakest in Tree Protection.
    private struct CategoryPlan {
        let id: Int
        let attempted: Int    // distinct questions touched (out of 75)
        let correctRate: Double
    }

    private static let categoryPlans: [CategoryPlan] = [
        .init(id: 1,  attempted: 67, correctRate: 0.87), // Tree Biology
        .init(id: 5,  attempted: 58, correctRate: 0.82), // Pruning
        .init(id: 3,  attempted: 54, correctRate: 0.78), // Soil Management
        .init(id: 2,  attempted: 51, correctRate: 0.74), // ID & Selection
        .init(id: 6,  attempted: 49, correctRate: 0.71), // Diagnosis & Treatment
        .init(id: 4,  attempted: 44, correctRate: 0.66), // Installation
        .init(id: 9,  attempted: 41, correctRate: 0.62), // Safe Work Practices
        .init(id: 8,  attempted: 37, correctRate: 0.58), // Tree Risk Management
        .init(id: 10, attempted: 26, correctRate: 0.52), // Urban Forestry
        .init(id: 7,  attempted: 17, correctRate: 0.45), // Tree Protection
    ]

    private static func seedQuestionAttempts(_ context: ModelContext, now: Date) {
        let cal = Calendar.current
        for plan in categoryPlans {
            let baseId = (plan.id - 1) * 75 + 1 // questions 1..750 grouped per cat
            for offset in 0..<plan.attempted {
                let qid = baseId + offset
                let attempt = QuestionAttempt(questionId: qid)
                let attempts = Int.random(in: 1...4, using: &rng)
                let correct = Int(Double(attempts) * plan.correctRate + 0.5)
                attempt.attemptCount = attempts
                attempt.correctCount = min(correct, attempts)
                attempt.lastCorrect = correct > 0
                attempt.lastAttemptedAt = cal.date(byAdding: .day, value: -Int.random(in: 0...20, using: &rng), to: now)
                attempt.status = statusFor(rate: plan.correctRate, lastCorrect: attempt.lastCorrect)
                attempt.reviewBox = boxFor(status: attempt.status)
                attempt.nextReviewAt = cal.date(byAdding: .day, value: Int.random(in: -2...14, using: &rng), to: now)
                context.insert(attempt)
            }
        }
    }

    private static func statusFor(rate: Double, lastCorrect: Bool) -> QuestionStatus {
        switch rate {
        case 0.80...:     return lastCorrect ? .mastered : .reviewing
        case 0.65..<0.80: return lastCorrect ? .reviewing : .learning
        case 0.50..<0.65: return lastCorrect ? .learning : .weak
        default:          return .weak
        }
    }

    private static func boxFor(status: QuestionStatus) -> Int {
        switch status {
        case .mastered: return 5
        case .reviewing: return 4
        case .learning: return 2
        case .weak: return 1
        case .new: return 1
        }
    }

    // MARK: - Practice sessions (mock-exam history with rising scores)

    private static func seedSessions(_ context: ModelContext, now: Date) {
        let cal = Calendar.current
        // 12 mock exams over last 30 days, scores rising 0.62 → 0.87
        let mockScores: [Double] = [0.62, 0.65, 0.68, 0.71, 0.73, 0.75, 0.78, 0.80, 0.82, 0.84, 0.85, 0.87]
        for (idx, score) in mockScores.enumerated() {
            let daysAgo = 30 - idx * 2
            let started = cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            let session = PracticeSession(
                kind: .simulator,
                licenseCode: "isa",
                categoryCode: nil,
                questionIds: Array(1...100),
                passThreshold: 0.76,
                timeLimitSec: 7200
            )
            session.startedAt = started
            session.endedAt = started.addingTimeInterval(Double(Int.random(in: 3000...5400, using: &rng)))
            session.score = score
            context.insert(session)
        }
        // 8 learn sessions across top categories
        let learnCats = ["tree_biology", "pruning", "soil_management", "identification_and_selection",
                         "diagnosis_and_treatment", "installation_and_establishment", "safe_work_practices", "tree_risk_management"]
        for (idx, code) in learnCats.enumerated() {
            let started = cal.date(byAdding: .day, value: -(idx * 3 + 1), to: now) ?? now
            let session = PracticeSession(
                kind: .learn,
                licenseCode: "isa",
                categoryCode: code,
                questionIds: Array(1...20)
            )
            session.startedAt = started
            session.endedAt = started.addingTimeInterval(Double(Int.random(in: 600...1200, using: &rng)))
            session.score = Double.random(in: 0.65...0.92, using: &rng)
            context.insert(session)
        }
        // 5 weak-question sessions
        for idx in 0..<5 {
            let started = cal.date(byAdding: .day, value: -(idx * 4), to: now) ?? now
            let session = PracticeSession(
                kind: .weak,
                licenseCode: "isa",
                questionIds: Array(1...15)
            )
            session.startedAt = started
            session.endedAt = started.addingTimeInterval(Double(Int.random(in: 480...900, using: &rng)))
            session.score = Double.random(in: 0.55...0.78, using: &rng)
            context.insert(session)
        }
    }

    // MARK: - Study streaks (last 30 days, realistic pattern)

    private static func seedStreaks(_ context: ModelContext, now: Date) {
        let cal = Calendar.current
        // Last 30 days: most days active, a few zero-question rest days
        let restDays: Set<Int> = [4, 11, 18, 25] // ~weekly rest
        for daysAgo in 0..<30 {
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            let streak = StudyStreak(date: day)
            if restDays.contains(daysAgo) {
                streak.minutesStudied = 0
                streak.questionsAnswered = 0
            } else if daysAgo == 0 {
                streak.minutesStudied = 28
                streak.questionsAnswered = 32
            } else {
                streak.minutesStudied = Int.random(in: 12...38, using: &rng)
                streak.questionsAnswered = Int.random(in: 14...44, using: &rng)
            }
            context.insert(streak)
        }
    }

    // MARK: - Bookmarks

    private static func seedBookmarks(_ context: ModelContext) {
        // 22 bookmarked questions spread across categories
        let bookmarkedQIds = [4, 12, 47, 63, 88, 102, 134, 156, 189, 212,
                              245, 278, 301, 334, 367, 412, 445, 478, 521, 567, 612, 678]
        for qid in bookmarkedQIds {
            context.insert(BookmarkedQuestion(questionId: qid))
        }
        // 14 bookmarked flashcards
        let bookmarkedFcIds = [3, 17, 28, 44, 61, 78, 92, 105, 128, 147, 168, 192, 215, 233]
        for fcid in bookmarkedFcIds {
            context.insert(BookmarkedFlashcard(flashcardId: fcid))
        }
    }

    // MARK: - Flashcard reviews (SM-2 lite progress)

    private static func seedFlashcardReviews(_ context: ModelContext, now: Date) {
        let cal = Calendar.current
        // 85 reviewed flashcards out of 250 (34%)
        for fcid in 1...85 {
            let review = FlashcardReview(flashcardId: fcid)
            review.repetitions = Int.random(in: 1...6, using: &rng)
            review.intervalDays = [1, 3, 7, 14, 30][min(review.repetitions - 1, 4)]
            review.ease = Double.random(in: 1.8...2.7, using: &rng)
            let lastDay = Int.random(in: 0...18, using: &rng)
            review.lastReviewedAt = cal.date(byAdding: .day, value: -lastDay, to: now)
            review.nextReviewAt = cal.date(byAdding: .day, value: review.intervalDays - lastDay, to: now)
            context.insert(review)
        }
    }

    // Deterministic-ish rng (still varies per seed run; good enough for demo screenshots).
    private static var rng = SystemRandomNumberGenerator()
}
