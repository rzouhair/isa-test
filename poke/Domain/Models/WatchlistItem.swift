import Foundation
import SwiftData

@Model
final class WatchlistItem {
    @Attribute(.unique) var id: UUID
    var tcgplayerProductId: String
    var name: String
    var setName: String
    var setCode: String
    var number: String
    var rarity: String
    var game: String
    var imageUrl: String?
    var lastKnownPrice: Double
    var addedAt: Date
    var notes: String?

    init(
        id: UUID = UUID(),
        tcgplayerProductId: String,
        name: String,
        setName: String = "",
        setCode: String = "",
        number: String = "",
        rarity: String = "",
        game: String = "",
        imageUrl: String? = nil,
        lastKnownPrice: Double = 0,
        notes: String? = nil
    ) {
        self.id = id
        self.tcgplayerProductId = tcgplayerProductId
        self.name = name
        self.setName = setName
        self.setCode = setCode
        self.number = number
        self.rarity = rarity
        self.game = game
        self.imageUrl = imageUrl
        self.lastKnownPrice = lastKnownPrice
        self.addedAt = Date()
        self.notes = notes
    }

    /// Create from a CardRecord
    convenience init(from card: CardRecord) {
        self.init(
            tcgplayerProductId: card.tcgplayerProductId,
            name: card.name,
            setName: card.setName,
            setCode: card.setCode,
            number: card.number,
            rarity: card.rarity,
            game: card.game,
            imageUrl: card.scanImageUrl,
            lastKnownPrice: card.tcgplayerPrice
        )
    }

    /// Create from a ScanRecord
    convenience init(from scan: ScanRecord) {
        self.init(
            tcgplayerProductId: scan.productId ?? "",
            name: scan.productName ?? "Unknown",
            setName: scan.setName ?? "",
            setCode: scan.setCode ?? "",
            number: scan.cardNumber ?? "",
            rarity: scan.rarity ?? "",
            game: scan.game ?? "",
            imageUrl: scan.imageSmall ?? scan.imageMedium,
            lastKnownPrice: scan.marketPrice ?? 0
        )
    }
}
