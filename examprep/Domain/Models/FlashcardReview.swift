import Foundation
import SwiftData

/// Per-card spaced-repetition state for atomic flashcards.
/// Uses a simplified SM-2 algorithm: ease factor + interval (days) + repetition count.
@Model
final class FlashcardReview {
    @Attribute(.unique) var flashcardId: Int
    var ease: Double = 2.5             // SM-2 ease factor (min 1.3)
    var intervalDays: Int = 0          // current interval before next review
    var repetitions: Int = 0           // consecutive successful recalls
    var lastReviewedAt: Date?
    var nextReviewAt: Date?

    init(flashcardId: Int) {
        self.flashcardId = flashcardId
    }

    /// Apply a self-rated grade (Anki-style 4-button: Again/Hard/Good/Easy).
    /// Updates ease, interval, repetitions, and schedules nextReviewAt.
    func apply(grade: FlashcardGrade, at date: Date = Date()) {
        lastReviewedAt = date

        // Quality 0..5 scale (SM-2 traditional). Map button → quality.
        let q: Int
        switch grade {
        case .again: q = 0
        case .hard:  q = 3
        case .good:  q = 4
        case .easy:  q = 5
        }

        if q < 3 {
            // Lapse: reset reps, short interval to retry today.
            repetitions = 0
            intervalDays = 0
            nextReviewAt = date.addingTimeInterval(60 * 10) // 10 minutes
        } else {
            switch repetitions {
            case 0: intervalDays = 1
            case 1: intervalDays = grade == .easy ? 4 : 3
            default: intervalDays = max(1, Int(Double(intervalDays) * ease))
            }
            repetitions += 1
            nextReviewAt = Calendar.current.date(byAdding: .day, value: intervalDays, to: date)
        }

        // Adjust ease per SM-2 formula.
        let qd = Double(q)
        ease = max(1.3, ease + (0.1 - (5.0 - qd) * (0.08 + (5.0 - qd) * 0.02)))
    }
}

enum FlashcardGrade: String, Sendable {
    case again, hard, good, easy

    var label: String {
        switch self {
        case .again: return "Again"
        case .hard:  return "Hard"
        case .good:  return "Good"
        case .easy:  return "Easy"
        }
    }
}
