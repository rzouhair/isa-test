import Foundation
import SwiftData

@Model
final class CardRecord {
    @Attribute(.unique) var id: UUID
    var tcgplayerProductId: String
    var name: String
    var setName: String
    var setCode: String
    var number: String
    var rarity: String
    var variant: String
    var game: String
    var tcgplayerPrice: Double
    var ebayPrice: Double?
    var priceUpdatedAt: Date
    var addedAt: Date
    var scanImageUrl: String?
    var confidenceScore: Double
    var isGraded: Bool
    var gradeCompany: String?
    var gradeValue: String?
    var notes: String?
    var collection: CardCollection?

    // Price history (JSON-encoded for SwiftData)
    var priceHistoryJSON: Data?
    // Candidates (JSON-encoded)
    var candidatesJSON: Data?
    var priceChange: Double?
    var priceChangePct: Double?
    var periodHigh: Double?
    var periodLow: Double?

    init(
        id: UUID = UUID(),
        tcgplayerProductId: String,
        name: String,
        setName: String = "",
        setCode: String = "",
        number: String = "",
        rarity: String = "",
        variant: String = "STANDARD",
        game: String = "",
        tcgplayerPrice: Double = 0,
        confidenceScore: Double = 0
    ) {
        self.id = id
        self.tcgplayerProductId = tcgplayerProductId
        self.name = name
        self.setName = setName
        self.setCode = setCode
        self.number = number
        self.rarity = rarity
        self.variant = variant
        self.game = game
        self.tcgplayerPrice = tcgplayerPrice
        self.priceUpdatedAt = Date()
        self.addedAt = Date()
        self.confidenceScore = confidenceScore
        self.isGraded = false
    }

    /// Decoded candidates from stored JSON
    var candidates: [Candidate] {
        guard let data = candidatesJSON else { return [] }
        return (try? JSONDecoder().decode([Candidate].self, from: data)) ?? []
    }

    /// Decoded chart series from stored JSON
    var priceHistory: PriceHistory? {
        guard let data = priceHistoryJSON else { return nil }
        return try? JSONDecoder().decode(PriceHistory.self, from: data)
    }

    /// Store price history from API response
    func storePriceHistory(_ history: PriceHistory?) {
        guard let history else { return }
        self.priceHistoryJSON = try? JSONEncoder().encode(history)
        self.priceChange = history.summary.priceChange
        self.priceChangePct = history.summary.priceChangePct
        self.periodHigh = history.summary.periodHigh
        self.periodLow = history.summary.periodLow
    }

    /// Create from a completed ScanRecord
    convenience init(from scan: ScanRecord) {
        self.init(
            tcgplayerProductId: scan.productId ?? "",
            name: scan.productName ?? "Unknown",
            setName: scan.setName ?? "",
            setCode: scan.setCode ?? "",
            number: scan.cardNumber ?? "",
            rarity: scan.rarity ?? "",
            variant: scan.variant ?? "STANDARD",
            game: scan.game ?? "",
            tcgplayerPrice: scan.marketPrice ?? 0,
            confidenceScore: scan.confidence ?? 0
        )
        self.scanImageUrl = scan.imageSmall ?? scan.imageMedium
        self.priceHistoryJSON = scan.priceHistoryJSON
        self.candidatesJSON = scan.candidatesJSON
    }
}
