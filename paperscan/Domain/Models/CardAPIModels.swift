import Foundation

// MARK: - Job Submit Response (POST /identify)

struct JobSubmitResponse: Codable, Sendable {
    let jobId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
        case status
    }
}

// MARK: - Job Status Response (GET /status/{job_id})

struct JobStatusResponse: Codable, Sendable {
    let jobId: String
    let status: String
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

// MARK: - Card Response (full result)

struct CardResponse: Codable, Sendable {
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

struct CardData: Codable, Sendable {
    let product: Product
    let images: CardImages?
    let identity: CardIdentity?
    let pricing: Pricing?
}

struct Product: Codable, Sendable {
    let id: String?
    let name: String
    let platform: String
    let url: String?
}

struct CardImages: Codable, Sendable {
    let small: String?
    let medium: String?
    let large: String?
    let back: String?
}

struct CardIdentity: Codable, Sendable {
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

struct CardAttributes: Codable, Sendable {
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

// MARK: - Pricing

struct Pricing: Codable, Sendable {
    let marketPrice: Double?
    let lowestPrice: Double?
    let lowestPriceWithShipping: Double?
    let medianPrice: Double?
    let rawLeastPrice: Double?
    let gradedLeastPrice: Double?
    let currency: String
    let history: PriceHistory?

    enum CodingKeys: String, CodingKey {
        case marketPrice = "market_price"
        case lowestPrice = "lowest_price"
        case lowestPriceWithShipping = "lowest_price_with_shipping"
        case medianPrice = "median_price"
        case rawLeastPrice = "raw_least_price"
        case gradedLeastPrice = "graded_least_price"
        case currency, history
    }
}

// MARK: - Price History

struct PriceHistory: Codable, Sendable {
    let summary: PriceSummary
    let chart: [ChartSeries]
}

struct PriceSummary: Codable, Sendable {
    let currentMarketPrice: Double?
    let previousMarketPrice: Double?
    let priceChange: Double?
    let priceChangePct: Double?
    let periodHigh: Double?
    let periodLow: Double?
    let totalVolume: Int
    let avgDailyVolume: Double

    enum CodingKeys: String, CodingKey {
        case currentMarketPrice = "current_market_price"
        case previousMarketPrice = "previous_market_price"
        case priceChange = "price_change"
        case priceChangePct = "price_change_pct"
        case periodHigh = "period_high"
        case periodLow = "period_low"
        case totalVolume = "total_volume"
        case avgDailyVolume = "avg_daily_volume"
    }
}

struct ChartSeries: Codable, Sendable, Identifiable {
    let id: String
    let label: String
    let variant: String
    let condition: String
    let language: String
    let totalVolume: Int
    let totalTransactions: Int
    let avgDailyVolume: Double
    let dataPoints: [ChartDataPoint]

    enum CodingKeys: String, CodingKey {
        case id, label, variant, condition, language
        case totalVolume = "total_volume"
        case totalTransactions = "total_transactions"
        case avgDailyVolume = "avg_daily_volume"
        case dataPoints = "data_points"
    }
}

struct ChartDataPoint: Codable, Sendable, Identifiable {
    let date: String
    let marketPrice: Double
    let lowPrice: Double
    let highPrice: Double
    let volume: Int
    let transactions: Int

    var id: String { date }

    var parsedDate: Date? {
        Self.dateFormatter.date(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    enum CodingKeys: String, CodingKey {
        case date
        case marketPrice = "market_price"
        case lowPrice = "low_price"
        case highPrice = "high_price"
        case volume, transactions
    }
}

// MARK: - Metadata

struct CardMetadata: Codable, Sendable {
    let cacheHit: Bool
    let searchQuery: String?
    let game: String?
    let sport: String?
    let cardTypeDetected: String?
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

struct ConfidenceBreakdown: Codable, Sendable {
    let name: Double?
    let number: Double?
    let variant: Double?
    let set: Double?
}

struct Candidate: Codable, Sendable {
    let productId: String?
    let confidence: Double?   // per-candidate match score (0–1) if returned by API
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
        case confidence
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
