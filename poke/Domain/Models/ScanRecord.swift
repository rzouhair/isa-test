import Foundation
import SwiftData

// Maps 8 API statuses → 4 client states
enum ScanStatus: String, Codable, Sendable {
    case pending     // API: pending, intake
    case processing  // API: vision, search, comparison, verifying, sweeping
    case complete    // API: complete
    case failed      // API: failed

    init(apiStatus: String) {
        switch apiStatus {
        case "pending", "intake":
            self = .pending
        case "complete":
            self = .complete
        case "failed":
            self = .failed
        default:
            self = .processing
        }
    }
}

@Model
final class ScanRecord {
    @Attribute(.unique) var id: UUID
    var jobId: String?
    var status: String // ScanStatus rawValue
    var capturedImagePath: String

    // Product (populated on complete)
    var productId: String?
    var productName: String?
    var platform: String?
    var productUrl: String?

    // Images
    var imageSmall: String?
    var imageMedium: String?

    // Identity
    var cardNumber: String?
    var setName: String?
    var setCode: String?
    var rarity: String?
    var year: String?
    var language: String?
    var game: String?
    var variant: String?
    var variantName: String?

    // Pricing
    var marketPrice: Double?
    var lowestPrice: Double?
    var medianPrice: Double?
    var currency: String?

    // Price history (JSON-encoded)
    var priceHistoryJSON: Data?

    // Candidates (JSON-encoded)
    var candidatesJSON: Data?

    // Metadata
    var confidence: Double?
    var candidatesCount: Int?
    var cardTypeDetected: String?

    var cardRecordId: UUID?
    var addedToCollection: Bool = false
    var errorMessage: String?
    var createdAt: Date
    var updatedAt: Date

    var scanStatus: ScanStatus {
        get { ScanStatus(rawValue: status) ?? .pending }
        set { status = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        capturedImagePath: String,
        status: ScanStatus = .pending
    ) {
        self.id = id
        self.capturedImagePath = capturedImagePath
        self.status = status.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Explicit Identifiable so ScanRecord works as a sheet(item:) binding
    var sheetId: UUID { id }

    /// Populate fields from a completed CardResponse
    func update(from response: CardResponse) {
        let data = response.cardData
        self.productId = data?.product.id
        self.productName = data?.product.name
        self.platform = data?.product.platform
        self.productUrl = data?.product.url

        self.imageSmall = data?.images?.small
        self.imageMedium = data?.images?.medium

        let identity = data?.identity
        self.cardNumber = identity?.cardNumber
        self.setName = identity?.setName
        self.setCode = identity?.setCode
        self.rarity = identity?.rarity
        self.year = identity?.year
        self.language = identity?.language
        self.game = identity?.game
        self.variant = identity?.variant
        self.variantName = identity?.variantName

        self.marketPrice = data?.pricing?.marketPrice
        self.lowestPrice = data?.pricing?.lowestPrice
        self.medianPrice = data?.pricing?.medianPrice
        self.currency = data?.pricing?.currency
        if let history = data?.pricing?.history {
            self.priceHistoryJSON = try? JSONEncoder().encode(history)
        }

        self.confidence = response.metadata?.confidence
        self.candidatesCount = response.metadata?.candidatesCount
        self.cardTypeDetected = response.metadata?.cardTypeDetected
        if let candidates = response.metadata?.candidates, !candidates.isEmpty {
            self.candidatesJSON = try? JSONEncoder().encode(candidates)
        }

        self.scanStatus = .complete
        self.updatedAt = Date()
    }
}
