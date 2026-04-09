import Foundation
import SwiftData

struct CSVService {

    // MARK: - Column Definitions

    private static let headers = [
        "collection_name", "collection_type",
        "name", "set_name", "set_code", "number", "rarity", "variant",
        "game", "tcgplayer_product_id", "tcgplayer_price",
        "confidence_score", "is_graded", "grade_company", "grade_value",
        "scan_image_url", "notes", "added_at"
    ]

    // MARK: - Export

    static func exportCSV(collections: [CardCollection], includeUncollected: [CardRecord] = []) -> String {
        var lines = [headers.joined(separator: ",")]

        for collection in collections {
            for card in collection.cards {
                lines.append(row(card: card, collectionName: collection.name, collectionType: collection.tcgType.rawValue))
            }
        }

        for card in includeUncollected {
            lines.append(row(card: card, collectionName: "", collectionType: ""))
        }

        return lines.joined(separator: "\n")
    }

    private static func row(card: CardRecord, collectionName: String, collectionType: String) -> String {
        let fields: [String] = [
            escape(collectionName),
            escape(collectionType),
            escape(card.name),
            escape(card.setName),
            escape(card.setCode),
            escape(card.number),
            escape(card.rarity),
            escape(card.variant),
            escape(card.game),
            escape(card.tcgplayerProductId),
            String(format: "%.2f", card.tcgplayerPrice),
            String(format: "%.2f", card.confidenceScore),
            card.isGraded ? "true" : "false",
            escape(card.gradeCompany ?? ""),
            escape(card.gradeValue ?? ""),
            escape(card.scanImageUrl ?? ""),
            escape(card.notes ?? ""),
            ISO8601DateFormatter().string(from: card.addedAt)
        ]
        return fields.joined(separator: ",")
    }

    private static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    // MARK: - Import

    struct ImportResult {
        var cardsCreated: Int = 0
        var collectionsCreated: Int = 0
        var watchlistCreated: Int = 0
        var errors: [String] = []
    }

    static func importCSV(
        csvString: String,
        context: ModelContext,
        mode: ImportMode,
        existingCollections: [CardCollection]
    ) -> ImportResult {
        var result = ImportResult()

        if mode == .replace {
            // Delete all existing cards and collections
            for collection in existingCollections {
                context.delete(collection)
            }
            // Also delete uncollected cards
            let descriptor = FetchDescriptor<CardRecord>(predicate: #Predicate { $0.collection == nil })
            if let orphans = try? context.fetch(descriptor) {
                for card in orphans { context.delete(card) }
            }
        }

        let lines = parseCSVLines(csvString)
        guard lines.count > 1 else {
            result.errors.append("CSV file is empty or has no data rows")
            return result
        }

        let headerRow = parseCSVFields(lines[0])
        let columnMap = buildColumnMap(headerRow)

        // Cache collections by name for fast lookup
        var collectionCache: [String: CardCollection] = [:]
        if mode == .merge {
            for c in existingCollections {
                collectionCache[c.name.lowercased()] = c
            }
        }

        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            let fields = parseCSVFields(line)
            guard fields.count >= 3 else {
                result.errors.append("Row \(i): too few columns")
                continue
            }

            let collectionName = field(fields, columnMap, "collection_name")
            let collectionType = field(fields, columnMap, "collection_type")
            let name = field(fields, columnMap, "name")

            guard !name.isEmpty else {
                result.errors.append("Row \(i): missing card name")
                continue
            }

            // Resolve or create collection
            var targetCollection: CardCollection?
            if !collectionName.isEmpty {
                let key = collectionName.lowercased()
                if let existing = collectionCache[key] {
                    targetCollection = existing
                } else {
                    let tcgType = TCGType(rawValue: collectionType) ?? .other
                    let newCollection = CardCollection(name: collectionName, tcgType: tcgType)
                    context.insert(newCollection)
                    collectionCache[key] = newCollection
                    targetCollection = newCollection
                    result.collectionsCreated += 1
                }
            }

            // Create card
            let card = CardRecord(
                tcgplayerProductId: field(fields, columnMap, "tcgplayer_product_id"),
                name: name,
                setName: field(fields, columnMap, "set_name"),
                setCode: field(fields, columnMap, "set_code"),
                number: field(fields, columnMap, "number"),
                rarity: field(fields, columnMap, "rarity"),
                variant: fieldOr(fields, columnMap, "variant", default: "STANDARD"),
                game: field(fields, columnMap, "game"),
                tcgplayerPrice: doubleField(fields, columnMap, "tcgplayer_price"),
                confidenceScore: doubleField(fields, columnMap, "confidence_score")
            )

            // Optional fields
            let graded = field(fields, columnMap, "is_graded").lowercased()
            card.isGraded = graded == "true" || graded == "1" || graded == "yes"
            card.gradeCompany = nilIfEmpty(field(fields, columnMap, "grade_company"))
            card.gradeValue = nilIfEmpty(field(fields, columnMap, "grade_value"))
            card.scanImageUrl = nilIfEmpty(field(fields, columnMap, "scan_image_url"))
            card.notes = nilIfEmpty(field(fields, columnMap, "notes"))

            let dateStr = field(fields, columnMap, "added_at")
            if !dateStr.isEmpty, let date = ISO8601DateFormatter().date(from: dateStr) {
                card.addedAt = date
            }

            card.collection = targetCollection
            context.insert(card)
            result.cardsCreated += 1
        }

        return result
    }

    enum ImportMode {
        case merge   // Add imported data alongside existing
        case replace // Wipe existing, replace with imported
    }

    // MARK: - CSV Parsing

    private static func parseCSVLines(_ csv: String) -> [String] {
        // Handle both \r\n and \n, respecting quoted fields with newlines
        var lines: [String] = []
        var current = ""
        var inQuotes = false

        for char in csv {
            if char == "\"" {
                inQuotes.toggle()
                current.append(char)
            } else if char == "\n" && !inQuotes {
                lines.append(current)
                current = ""
            } else if char == "\r" && !inQuotes {
                continue
            } else {
                current.append(char)
            }
        }
        if !current.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.append(current)
        }
        return lines
    }

    private static func parseCSVFields(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                if inQuotes && current.last == "\"" {
                    // Escaped quote
                } else {
                    inQuotes.toggle()
                }
                current.append(char)
            } else if char == "," && !inQuotes {
                fields.append(unescapeField(current))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(unescapeField(current))
        return fields
    }

    private static func unescapeField(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("\"") && s.hasSuffix("\"") && s.count >= 2 {
            s = String(s.dropFirst().dropLast())
            s = s.replacingOccurrences(of: "\"\"", with: "\"")
        }
        return s
    }

    private static func buildColumnMap(_ headers: [String]) -> [String: Int] {
        var map: [String: Int] = [:]
        for (i, h) in headers.enumerated() {
            map[h.lowercased().trimmingCharacters(in: .whitespaces)] = i
        }
        return map
    }

    private static func field(_ fields: [String], _ map: [String: Int], _ key: String) -> String {
        guard let idx = map[key], idx < fields.count else { return "" }
        return fields[idx]
    }

    private static func fieldOr(_ fields: [String], _ map: [String: Int], _ key: String, default def: String) -> String {
        let v = field(fields, map, key)
        return v.isEmpty ? def : v
    }

    private static func doubleField(_ fields: [String], _ map: [String: Int], _ key: String) -> Double {
        Double(field(fields, map, key)) ?? 0
    }

    private static func nilIfEmpty(_ s: String) -> String? {
        s.isEmpty ? nil : s
    }

    // MARK: - Watchlist Export

    private static let watchlistHeaders = [
        "name", "set_name", "set_code", "number", "rarity",
        "game", "tcgplayer_product_id", "last_known_price",
        "image_url", "notes", "added_at"
    ]

    static func exportWatchlistCSV(items: [WatchlistItem]) -> String {
        var lines = [watchlistHeaders.joined(separator: ",")]
        for item in items {
            let fields: [String] = [
                escape(item.name),
                escape(item.setName),
                escape(item.setCode),
                escape(item.number),
                escape(item.rarity),
                escape(item.game),
                escape(item.tcgplayerProductId),
                String(format: "%.2f", item.lastKnownPrice),
                escape(item.imageUrl ?? ""),
                escape(item.notes ?? ""),
                ISO8601DateFormatter().string(from: item.addedAt)
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Watchlist Import

    static func importWatchlistCSV(
        csvString: String,
        context: ModelContext,
        mode: ImportMode,
        existingItems: [WatchlistItem]
    ) -> ImportResult {
        var result = ImportResult()

        if mode == .replace {
            for item in existingItems { context.delete(item) }
        }

        let lines = parseCSVLines(csvString)
        guard lines.count > 1 else {
            result.errors.append("CSV file is empty or has no data rows")
            return result
        }

        let headerRow = parseCSVFields(lines[0])
        let columnMap = buildColumnMap(headerRow)

        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else { continue }

            let fields = parseCSVFields(line)
            let name = field(fields, columnMap, "name")
            guard !name.isEmpty else {
                result.errors.append("Row \(i): missing name")
                continue
            }

            let item = WatchlistItem(
                tcgplayerProductId: field(fields, columnMap, "tcgplayer_product_id"),
                name: name,
                setName: field(fields, columnMap, "set_name"),
                setCode: field(fields, columnMap, "set_code"),
                number: field(fields, columnMap, "number"),
                rarity: field(fields, columnMap, "rarity"),
                game: field(fields, columnMap, "game"),
                imageUrl: nilIfEmpty(field(fields, columnMap, "image_url")),
                lastKnownPrice: doubleField(fields, columnMap, "last_known_price"),
                notes: nilIfEmpty(field(fields, columnMap, "notes"))
            )

            let dateStr = field(fields, columnMap, "added_at")
            if !dateStr.isEmpty, let date = ISO8601DateFormatter().date(from: dateStr) {
                item.addedAt = date
            }

            context.insert(item)
            result.watchlistCreated += 1
        }

        return result
    }
}
