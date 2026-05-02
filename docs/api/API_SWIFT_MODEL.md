# Swift Models — Cards Identifier API

Codable models for decoding API responses + SwiftData models for local persistence.

---

## API Response Models (Codable)

Drop these into your project for decoding `/identify` and `/status/{job_id}` responses.

```swift
import Foundation

// MARK: - Job Status Response (GET /status/{job_id})

struct JobStatusResponse: Codable {
    let jobId: String
    let status: String // pending | intake | vision | search | comparison | verifying | sweeping | complete | failed
    let createdAt: Int?
    let updatedAt: Int?
    let result: CardResponse?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case result
        case error
    }
}

// MARK: - Job Submission Response (POST /identify)

struct JobSubmitResponse: Codable {
    let jobId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
    }
}

// MARK: - Card Response (full result)

struct CardResponse: Codable {
    let status: String
    let jobId: String?
    let source: String?
    let cardData: CardData?
    let metadata: CardMetadata?

    enum CodingKeys: String, CodingKey {
        case status
        case jobId = "job_id"
        case source
        case cardData = "card_data"
        case metadata
    }
}

// MARK: - Card Data

struct CardData: Codable {
    let product: Product
    let images: CardImages?
    let identity: CardIdentity?
    let pricing: Pricing?
}

struct Product: Codable {
    let id: String?
    let name: String
    let platform: String // "tcgplayer" | "buysportscards"
    let url: String?
}

struct CardImages: Codable {
    let small: String?
    let medium: String?
    let large: String?
    let back: String?
}

struct CardIdentity: Codable {
    let cardNumber: String?
    let setName: String?
    let setCode: String?
    let rarity: String?
    let year: String?
    let language: String?
    let game: String?
    let sport: String?
    let edition: String?
    let foil: String?
    let cardType: String?
    let description: String?
    let flavorText: String?
    let playerName: String?
    let manufacturer: String?
    let variant: String?
    let variantName: String?
    let printing: String?
    let releaseDate: String?
    let productLine: String?
    let attributes: CardAttributes?

    enum CodingKeys: String, CodingKey {
        case cardNumber = "card_number"
        case setName = "set_name"
        case setCode = "set_code"
        case rarity, year, language, game, sport, edition, foil
        case cardType = "card_type"
        case description
        case flavorText = "flavor_text"
        case playerName = "player_name"
        case manufacturer, variant
        case variantName = "variant_name"
        case printing
        case releaseDate = "release_date"
        case productLine = "product_line"
        case attributes
    }
}

struct CardAttributes: Codable {
    // TCG
    let attack: String?
    let defense: String?
    let level: String?
    let attribute: [String]?
    let monsterType: [String]?
    let cardTypeB: String?
    let cardType: [String]?
    let hp: String?
    let stage: String?
    let energyType: [String]?
    let attacks: [String]?
    let weakness: String?
    let resistance: String?
    let retreatCost: String?
    // Sports
    let position: String?
    let team: String?

    enum CodingKeys: String, CodingKey {
        case attack, defense, level, attribute
        case monsterType = "monster_type"
        case cardTypeB = "card_type_b"
        case cardType = "card_type"
        case hp, stage
        case energyType = "energy_type"
        case attacks, weakness, resistance
        case retreatCost = "retreat_cost"
        case position, team
    }
}

struct Pricing: Codable {
    let marketPrice: Double?
    let lowestPrice: Double?
    let lowestPriceWithShipping: Double?
    let medianPrice: Double?
    let rawLeastPrice: Double?
    let gradedLeastPrice: Double?
    let currency: String

    enum CodingKeys: String, CodingKey {
        case marketPrice = "market_price"
        case lowestPrice = "lowest_price"
        case lowestPriceWithShipping = "lowest_price_with_shipping"
        case medianPrice = "median_price"
        case rawLeastPrice = "raw_least_price"
        case gradedLeastPrice = "graded_least_price"
        case currency
    }
}

// MARK: - Metadata

struct CardMetadata: Codable {
    let cacheHit: Bool
    let searchQuery: String?
    let game: String?
    let sport: String?
    let cardTypeDetected: String? // "tcg" | "sports"
    let confidence: Double
    let confidenceBreakdown: ConfidenceBreakdown?
    let productUrl: String?
    let productId: String?
    let candidatesCount: Int
    let candidates: [Candidate]

    enum CodingKeys: String, CodingKey {
        case cacheHit = "cache_hit"
        case searchQuery = "search_query"
        case game, sport
        case cardTypeDetected = "card_type_detected"
        case confidence
        case confidenceBreakdown = "confidence_breakdown"
        case productUrl = "product_url"
        case productId = "product_id"
        case candidatesCount = "candidates_count"
        case candidates
    }
}

struct ConfidenceBreakdown: Codable {
    let name: Double?
    let number: Double?
    let variant: Double?
    let set: Double?
}

struct Candidate: Codable {
    let productId: String?
    let name: String?
    let setName: String?
    let setCode: String?
    let cardNumber: String?
    let rarity: String?
    let year: String?
    let game: String?
    let sport: String?
    let playerName: String?
    let teamName: String?
    let variant: String?
    let edition: String?
    let lowestPrice: Double?
    let marketPrice: Double?
    let medianPrice: Double?
    let totalListings: Double?
    let image: String?
    let url: String?
    let source: String?

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case name
        case setName = "set_name"
        case setCode = "set_code"
        case cardNumber = "card_number"
        case rarity, year, game, sport
        case playerName = "player_name"
        case teamName = "team_name"
        case variant, edition
        case lowestPrice = "lowest_price"
        case marketPrice = "market_price"
        case medianPrice = "median_price"
        case totalListings = "total_listings"
        case image, url, source
    }
}
```

---

## SwiftData Models (Local Persistence)

For saving identified cards locally on the device.

```swift
import Foundation
import SwiftData

@Model
final class SavedCard {
    @Attribute(.unique) var jobId: String
    var status: String
    var source: String?
    var createdAt: Date
    var updatedAt: Date

    // Product
    var productId: String?
    var productName: String
    var platform: String
    var productUrl: String?

    // Images
    var imageSmall: String?
    var imageMedium: String?
    var imageLarge: String?
    var imageBack: String?

    // Identity
    var cardNumber: String?
    var setName: String?
    var setCode: String?
    var rarity: String?
    var year: String?
    var language: String?
    var game: String?
    var sport: String?
    var edition: String?
    var foil: String?
    var cardType: String?
    var cardDescription: String?
    var flavorText: String?
    var playerName: String?
    var manufacturer: String?
    var variant: String?
    var variantName: String?
    var printing: String?
    var releaseDate: String?
    var productLine: String?

    // Pricing
    var marketPrice: Double?
    var lowestPrice: Double?
    var medianPrice: Double?
    var currency: String?

    // Metadata
    var confidence: Double
    var cardTypeDetected: String? // "tcg" | "sports"

    init(from response: CardResponse) {
        self.jobId = response.jobId ?? UUID().uuidString
        self.status = response.status
        self.source = response.source
        self.createdAt = Date()
        self.updatedAt = Date()

        let data = response.cardData
        self.productId = data?.product.id
        self.productName = data?.product.name ?? "Unknown"
        self.platform = data?.product.platform ?? ""
        self.productUrl = data?.product.url

        self.imageSmall = data?.images?.small
        self.imageMedium = data?.images?.medium
        self.imageLarge = data?.images?.large
        self.imageBack = data?.images?.back

        let identity = data?.identity
        self.cardNumber = identity?.cardNumber
        self.setName = identity?.setName
        self.setCode = identity?.setCode
        self.rarity = identity?.rarity
        self.year = identity?.year
        self.language = identity?.language
        self.game = identity?.game
        self.sport = identity?.sport
        self.edition = identity?.edition
        self.foil = identity?.foil
        self.cardType = identity?.cardType
        self.cardDescription = identity?.description
        self.flavorText = identity?.flavorText
        self.playerName = identity?.playerName
        self.manufacturer = identity?.manufacturer
        self.variant = identity?.variant
        self.variantName = identity?.variantName
        self.printing = identity?.printing
        self.releaseDate = identity?.releaseDate
        self.productLine = identity?.productLine

        let pricing = data?.pricing
        self.marketPrice = pricing?.marketPrice
        self.lowestPrice = pricing?.lowestPrice
        self.medianPrice = pricing?.medianPrice
        self.currency = pricing?.currency

        self.confidence = response.metadata?.confidence ?? 0.0
        self.cardTypeDetected = response.metadata?.cardTypeDetected
    }
}
```

### SwiftData Container Setup

```swift
import SwiftData

@main
struct CardsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SavedCard.self)
    }
}
```

---

## Usage Example

### API Client

```swift
class CardsAPI {
    let baseURL: URL

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    // Submit card for identification
    func identify(imageData: Data) async throws -> JobSubmitResponse {
        let url = baseURL.appendingPathComponent("identify")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "image_base64": imageData.base64EncodedString()
        ]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(JobSubmitResponse.self, from: data)
    }

    // Poll job status
    func status(jobId: String) async throws -> JobStatusResponse {
        let url = baseURL.appendingPathComponent("status/\(jobId)")
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(JobStatusResponse.self, from: data)
    }

    // Submit and poll until complete
    func identifyAndWait(imageData: Data, pollInterval: TimeInterval = 2.0) async throws -> CardResponse {
        let job = try await identify(imageData: imageData)

        while true {
            try await Task.sleep(for: .seconds(pollInterval))
            let status = try await status(jobId: job.jobId)

            switch status.status {
            case "complete":
                guard let result = status.result else {
                    throw CardsAPIError.noResult
                }
                return result
            case "failed":
                throw CardsAPIError.failed(status.error ?? "Unknown error")
            default:
                continue // still processing
            }
        }
    }
}

enum CardsAPIError: Error {
    case noResult
    case failed(String)
}
```

### Save to SwiftData

```swift
func scanCard(imageData: Data, context: ModelContext) async throws {
    let api = CardsAPI(baseURL: URL(string: "https://abc123.lambda-url.us-east-1.on.aws")!)
    let result = try await api.identifyAndWait(imageData: imageData)
    let saved = SavedCard(from: result)
    context.insert(saved)
}
```

---

## Type Mapping Reference

| Python (API) | JSON | Swift (Codable) | SwiftData |
|---|---|---|---|
| `str` | `string` | `String` | `String` |
| `str \| None` | `string \| null` | `String?` | `String?` |
| `int` | `number` | `Int` | `Int` |
| `float` | `number` | `Double` | `Double` |
| `float \| None` | `number \| null` | `Double?` | `Double?` |
| `bool` | `boolean` | `Bool` | `Bool` |
| `list[str]` | `[string]` | `[String]` | Not stored (flattened) |
| `list[Candidate]` | `[object]` | `[Candidate]` | Not stored (metadata only) |
