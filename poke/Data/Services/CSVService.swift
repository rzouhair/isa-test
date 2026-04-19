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
        var gradesCreated: Int = 0
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
            do {
                let orphans = try context.fetch(descriptor)
                for card in orphans { context.delete(card) }
            } catch {
                DIContainer.shared.crashReportingService.captureError(
                    error,
                    context: ["action": "csv_import_orphan_fetch"]
                )
                result.errors.append("Could not clean up existing cards: \(error.localizedDescription)")
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

            card.isUserConfirmed = true

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

    // MARK: - Grades Export

    private static let gradeHeaders = [
        "centering_score", "corners_score", "edges_score", "surface_score",
        "centering_notes", "corners_notes", "edges_notes", "surface_notes",
        "centering_defects", "corners_defects", "edges_defects", "surface_defects",
        "front_centering_lr", "front_centering_tb", "back_centering_lr", "back_centering_tb",
        "psa_range", "bgs_range", "confidence",
        "tips", "disclaimer", "created_at"
    ]

    static func exportGradesCSV(grades: [GradeRecord]) -> String {
        var lines = [gradeHeaders.joined(separator: ",")]
        for grade in grades {
            let fields: [String] = [
                String(format: "%.1f", grade.centeringScore),
                String(format: "%.1f", grade.cornersScore),
                String(format: "%.1f", grade.edgesScore),
                String(format: "%.1f", grade.surfaceScore),
                escape(grade.centeringNotes ?? ""),
                escape(grade.cornersNotes ?? ""),
                escape(grade.edgesNotes ?? ""),
                escape(grade.surfaceNotes ?? ""),
                escape(encodeArray(grade.centeringDefects)),
                escape(encodeArray(grade.cornersDefects)),
                escape(encodeArray(grade.edgesDefects)),
                escape(encodeArray(grade.surfaceDefects)),
                escape(grade.frontCenteringLR ?? ""),
                escape(grade.frontCenteringTB ?? ""),
                escape(grade.backCenteringLR ?? ""),
                escape(grade.backCenteringTB ?? ""),
                escape(grade.psaRange ?? ""),
                escape(grade.bgsRange ?? ""),
                escape(grade.confidence),
                escape(encodeArray(grade.tips)),
                escape(grade.disclaimer ?? ""),
                ISO8601DateFormatter().string(from: grade.createdAt)
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private static func encodeArray(_ arr: [String]) -> String {
        arr.joined(separator: "|")
    }

    private static func decodeArray(_ str: String) -> [String] {
        guard !str.isEmpty else { return [] }
        return str.components(separatedBy: "|")
    }

    // MARK: - Grades Import

    static func importGradesCSV(
        csvString: String,
        context: ModelContext,
        mode: ImportMode,
        existingGrades: [GradeRecord]
    ) -> ImportResult {
        var result = ImportResult()

        if mode == .replace {
            for grade in existingGrades { context.delete(grade) }
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
            guard fields.count >= 4 else {
                result.errors.append("Row \(i): too few columns")
                continue
            }

            let record = GradeRecord(
                centeringScore: doubleField(fields, columnMap, "centering_score"),
                cornersScore: doubleField(fields, columnMap, "corners_score"),
                edgesScore: doubleField(fields, columnMap, "edges_score"),
                surfaceScore: doubleField(fields, columnMap, "surface_score"),
                confidence: fieldOr(fields, columnMap, "confidence", default: "low")
            )

            record.centeringNotes = nilIfEmpty(field(fields, columnMap, "centering_notes"))
            record.cornersNotes = nilIfEmpty(field(fields, columnMap, "corners_notes"))
            record.edgesNotes = nilIfEmpty(field(fields, columnMap, "edges_notes"))
            record.surfaceNotes = nilIfEmpty(field(fields, columnMap, "surface_notes"))

            let cDefects = field(fields, columnMap, "centering_defects")
            let coDefects = field(fields, columnMap, "corners_defects")
            let eDefects = field(fields, columnMap, "edges_defects")
            let sDefects = field(fields, columnMap, "surface_defects")
            if !cDefects.isEmpty { record.centeringDefectsJSON = try? JSONEncoder().encode(decodeArray(cDefects)) }
            if !coDefects.isEmpty { record.cornersDefectsJSON = try? JSONEncoder().encode(decodeArray(coDefects)) }
            if !eDefects.isEmpty { record.edgesDefectsJSON = try? JSONEncoder().encode(decodeArray(eDefects)) }
            if !sDefects.isEmpty { record.surfaceDefectsJSON = try? JSONEncoder().encode(decodeArray(sDefects)) }

            record.frontCenteringLR = nilIfEmpty(field(fields, columnMap, "front_centering_lr"))
            record.frontCenteringTB = nilIfEmpty(field(fields, columnMap, "front_centering_tb"))
            record.backCenteringLR = nilIfEmpty(field(fields, columnMap, "back_centering_lr"))
            record.backCenteringTB = nilIfEmpty(field(fields, columnMap, "back_centering_tb"))

            record.psaRange = nilIfEmpty(field(fields, columnMap, "psa_range"))
            record.bgsRange = nilIfEmpty(field(fields, columnMap, "bgs_range"))

            let tips = field(fields, columnMap, "tips")
            if !tips.isEmpty { record.tipsJSON = try? JSONEncoder().encode(decodeArray(tips)) }
            record.disclaimer = nilIfEmpty(field(fields, columnMap, "disclaimer"))

            let dateStr = field(fields, columnMap, "created_at")
            if !dateStr.isEmpty, let date = ISO8601DateFormatter().date(from: dateStr) {
                record.createdAt = date
            }

            context.insert(record)
            result.gradesCreated += 1
        }

        return result
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
