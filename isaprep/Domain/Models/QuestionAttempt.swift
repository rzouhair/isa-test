import Foundation
import SwiftData

enum QuestionStatus: String, Codable, Sendable {
    case new, learning, reviewing, weak, mastered
}

@Model
final class QuestionAttempt {
    @Attribute(.unique) var questionId: Int     // FK to SQLite questions.id
    var attemptCount: Int = 0
    var correctCount: Int = 0
    var lastAttemptedAt: Date?
    var lastCorrect: Bool = false
    var status: QuestionStatus = QuestionStatus.new

    /// Leitner box 1…6. Wrong answer drops back to 1. Correct advances by 1.
    var reviewBox: Int = 1
    /// When this card should next surface in the review queue.
    var nextReviewAt: Date?

    init(questionId: Int) {
        self.questionId = questionId
    }

    /// Leitner intervals in seconds, indexed by (box - 1).
    /// Box 1 = 10 min (same session retry), 2 = 1d, 3 = 3d, 4 = 7d, 5 = 14d, 6 = 30d.
    private static let boxIntervals: [TimeInterval] = [
        600,        // 10 min
        86_400,     // 1 day
        3 * 86_400, // 3 days
        7 * 86_400,
        14 * 86_400,
        30 * 86_400,
    ]

    /// Spaced-rep lite transitions.
    /// new + correct → mastered; new + wrong → learning.
    /// learning + correct → reviewing; + wrong → stays learning.
    /// reviewing + correct → mastered; + wrong → weak.
    /// weak + correct → reviewing; + wrong → stays weak.
    /// mastered + wrong → reviewing.
    func applyAnswer(correct: Bool, at date: Date) {
        attemptCount += 1
        if correct { correctCount += 1 }
        lastAttemptedAt = date
        lastCorrect = correct

        switch (status, correct) {
        case (.new, true): status = .mastered
        case (.new, false): status = .learning
        case (.learning, true): status = .reviewing
        case (.learning, false): status = .learning
        case (.reviewing, true): status = .mastered
        case (.reviewing, false): status = .weak
        case (.weak, true): status = .reviewing
        case (.weak, false): status = .weak
        case (.mastered, true): status = .mastered
        case (.mastered, false): status = .reviewing
        }

        // Leitner schedule: advance on correct, reset to box 1 on wrong.
        if correct {
            reviewBox = min(Self.boxIntervals.count, reviewBox + 1)
        } else {
            reviewBox = 1
        }
        let interval = Self.boxIntervals[reviewBox - 1]
        nextReviewAt = date.addingTimeInterval(interval)
    }
}
