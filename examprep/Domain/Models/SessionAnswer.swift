import Foundation
import SwiftData

@Model
final class SessionAnswer {
    var questionId: Int
    var selectedAnswerId: Int?
    var correct: Bool = false
    var timeMs: Int = 0
    var answeredAt: Date = Date()
    var session: PracticeSession?

    init(questionId: Int,
         selectedAnswerId: Int? = nil,
         correct: Bool = false,
         timeMs: Int = 0) {
        self.questionId = questionId
        self.selectedAnswerId = selectedAnswerId
        self.correct = correct
        self.timeMs = timeMs
    }
}
