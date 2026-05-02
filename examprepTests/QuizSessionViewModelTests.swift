import XCTest
import SwiftData
@testable import examprep

@MainActor
final class QuizSessionViewModelTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var progress: SwiftDataUserProgressRepository!

    override func setUp() async throws {
        let schema = Schema([
            UserExamProfile.self,
            QuestionAttempt.self,
            PracticeSession.self,
            SessionAnswer.self,
            BookmarkedQuestion.self,
            StudyStreak.self,
        ])
        container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        context = ModelContext(container)
        progress = SwiftDataUserProgressRepository(context: context)
        try progress.setProfile(licenseCode: "car", stateCode: "CA", examDate: nil)
    }

    func testScoringFromRealQuestions() async throws {
        let content = GRDBContentRepository()
        let seeded = try content.questions(
            licenseCode: "car",
            stateCode: "CA",
            categoryCode: "general_knowledge",
            lang: "en",
            limit: nil
        )
        try XCTSkipIf(seeded.isEmpty, "No seeded questions — skipping")

        let ids = seeded.prefix(3).map(\.0.id)
        let config = QuizConfig(
            kind: .practice,
            licenseCode: "car",
            stateCode: "CA",
            categoryCode: "general_knowledge",
            questionIds: Array(ids),
            passThreshold: 0.66,
            timeLimitSec: nil
        )
        let vm = QuizSessionViewModel(
            config: config,
            content: content,
            progress: progress,
            analytics: NoopAnalytics()
        )
        await vm.load()
        XCTAssertEqual(vm.questions.count, 3)

        // Answer all 3 correctly.
        for _ in 0..<3 {
            if let correct = vm.currentAnswers.first(where: { $0.isCorrect == 1 }) {
                vm.select(answerId: correct.id)
                vm.next()
            }
        }
        XCTAssertTrue(vm.finished)
        XCTAssertEqual(vm.correctCount, 3)
        XCTAssertEqual(vm.score, 1.0, accuracy: 0.001)
        XCTAssertTrue(vm.passed)
    }

    func testWrongAnswerFlipsButtonStateAndPersistsAttempt() async throws {
        let content = GRDBContentRepository()
        let seeded = try content.questions(
            licenseCode: "car",
            stateCode: "CA",
            categoryCode: "general_knowledge",
            lang: "en",
            limit: nil
        )
        try XCTSkipIf(seeded.isEmpty, "No seeded questions — skipping")

        let first = seeded[0]
        let config = QuizConfig(
            kind: .practice,
            licenseCode: "car",
            stateCode: "CA",
            categoryCode: "general_knowledge",
            questionIds: [first.0.id],
            passThreshold: 0.8,
            timeLimitSec: nil
        )
        let vm = QuizSessionViewModel(
            config: config,
            content: content,
            progress: progress,
            analytics: NoopAnalytics()
        )
        await vm.load()

        guard let wrong = vm.currentAnswers.first(where: { $0.isCorrect == 0 }) else {
            XCTFail("No wrong answer in fixture"); return
        }
        vm.select(answerId: wrong.id)

        XCTAssertEqual(vm.buttonState(for: wrong), .incorrect)
        if let correct = vm.currentAnswers.first(where: { $0.isCorrect == 1 }) {
            XCTAssertEqual(vm.buttonState(for: correct), .correct)
        }
        XCTAssertEqual(progress.attempt(for: first.0.id)?.status, .learning)
    }
}

private struct NoopAnalytics: AnalyticsServiceProtocol {
    func initialize() {}
    func capture(_ event: AnalyticsEvent, properties: [String: Any]) {}
    func screen(_ name: String) {}
    func reset() {}
}
