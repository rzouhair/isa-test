import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class FlashcardsLibraryViewModel {
    struct Deck: Identifiable, Hashable {
        let id: String          // category code, or "_all" / "_due" / "_bookmarks"
        let title: String
        let subtitle: String
        let iconName: String
        let total: Int
        let dueCount: Int
        let masteredCount: Int
        let categoryCode: String?  // nil for special decks

        var progress: Double {
            total == 0 ? 0 : min(1, Double(masteredCount) / Double(total))
        }
    }

    private let content: ContentRepositoryProtocol
    private let progress: UserProgressRepositoryProtocol

    private(set) var decks: [Deck] = []
    private(set) var totalDue: Int = 0
    private(set) var totalCards: Int = 0
    private(set) var totalBookmarks: Int = 0

    init(content: ContentRepositoryProtocol = DIContainer.shared.contentRepository,
         progress: UserProgressRepositoryProtocol) {
        self.content = content
        self.progress = progress
    }

    func reload() {
        let cats = (try? content.categories(licenseCode: Constants.licenseCode)) ?? []
        let counts = (try? content.flashcardCounts(licenseCode: Constants.licenseCode, lang: "en")) ?? [:]
        let allCards = (try? content.flashcards(licenseCode: Constants.licenseCode, categoryCode: nil, lang: "en")) ?? []

        let reviews = progress.allFlashcardReviews()
        let reviewByCard = Dictionary(uniqueKeysWithValues: reviews.map { ($0.flashcardId, $0) })
        let now = Date()

        // Index card → category code, used for per-deck mastery / due breakdown.
        let categoryByCardId: [Int: String] = {
            let byCatId = Dictionary(uniqueKeysWithValues: cats.map { ($0.id, $0.code) })
            return Dictionary(uniqueKeysWithValues: allCards.compactMap { card -> (Int, String)? in
                guard let code = byCatId[card.categoryId] else { return nil }
                return (card.id, code)
            })
        }()

        var perCatDue: [String: Int] = [:]
        var perCatMastered: [String: Int] = [:]
        for card in allCards {
            guard let code = categoryByCardId[card.id] else { continue }
            let review = reviewByCard[card.id]
            if let next = review?.nextReviewAt {
                if next <= now { perCatDue[code, default: 0] += 1 }
            } else {
                perCatDue[code, default: 0] += 1     // never seen → counts as "to study"
            }
            // Mastered = 3+ successful repetitions.
            if let r = review, r.repetitions >= 3 { perCatMastered[code, default: 0] += 1 }
        }

        decks = cats.map { cat in
            Deck(
                id: cat.code,
                title: cat.name,
                subtitle: "\(counts[cat.code] ?? 0) cards",
                iconName: Self.iconName(for: cat.code),
                total: counts[cat.code] ?? 0,
                dueCount: perCatDue[cat.code] ?? 0,
                masteredCount: perCatMastered[cat.code] ?? 0,
                categoryCode: cat.code
            )
        }

        totalCards = allCards.count
        totalDue = perCatDue.values.reduce(0, +)
        totalBookmarks = progress.flashcardBookmarks().count
    }

    static func iconName(for categoryCode: String) -> String {
        switch categoryCode {
        case "tree_biology": return "leaf.fill"
        case "identification_and_selection": return "magnifyingglass"
        case "soil_management": return "square.grid.3x3.fill"
        case "installation_and_establishment": return "shovel.fill"
        case "pruning": return "scissors"
        case "diagnosis_and_treatment": return "stethoscope"
        case "tree_protection": return "shield.fill"
        case "tree_risk_management": return "exclamationmark.triangle.fill"
        case "safe_work_practices": return "hammer.fill"
        case "urban_forestry": return "building.2.fill"
        default: return "rectangle.stack"
        }
    }
}
