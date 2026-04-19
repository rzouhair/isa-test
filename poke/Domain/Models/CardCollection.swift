import Foundation
import SwiftData

@Model
final class CardCollection {
    @Attribute(.unique) var id: UUID
    var name: String
    var tcgType: TCGType
    var createdAt: Date
    var updatedAt: Date

    // Nullify rule: deleting a collection sets each card's `collection` to nil
    // (cards move to "unassigned") rather than cascading a card delete. Callers
    // that want to delete cards must do so explicitly before removing the collection.
    @Relationship(deleteRule: .nullify, inverse: \CardRecord.collection)
    var cards: [CardRecord] = []

    var totalValue: Double {
        cards.reduce(0) { $0 + $1.tcgplayerPrice }
    }

    var cardCount: Int { cards.count }

    var distinctSets: Int {
        Set(cards.map(\.setName)).subtracting([""]).count
    }

    init(name: String, tcgType: TCGType) {
        self.id = UUID()
        self.name = name
        self.tcgType = tcgType
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
