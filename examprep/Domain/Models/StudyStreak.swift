import Foundation
import SwiftData

@Model
final class StudyStreak {
    /// Day-truncated (00:00 local).
    @Attribute(.unique) var date: Date
    var minutesStudied: Int = 0
    var questionsAnswered: Int = 0

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }
}
