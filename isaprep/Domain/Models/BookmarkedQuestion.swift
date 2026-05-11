import Foundation
import SwiftData

@Model
final class BookmarkedQuestion {
    @Attribute(.unique) var questionId: Int
    var savedAt: Date = Date()

    init(questionId: Int) {
        self.questionId = questionId
    }
}
