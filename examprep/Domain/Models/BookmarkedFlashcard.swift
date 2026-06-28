import Foundation
import SwiftData

@Model
final class BookmarkedFlashcard {
    @Attribute(.unique) var flashcardId: Int
    var savedAt: Date = Date()

    init(flashcardId: Int) {
        self.flashcardId = flashcardId
    }
}
