import Foundation
import SwiftData

@Model
final class CardCollection {
    @Attribute(.unique) var id: UUID
    var name: String
    var tcgType: TCGType
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \CardRecord.collection)
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
