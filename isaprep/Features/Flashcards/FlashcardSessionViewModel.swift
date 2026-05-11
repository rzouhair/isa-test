import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class FlashcardSessionViewModel {
    enum SessionState {
        case loading
        case empty(message: String)
        case studying(card: FlashcardDTO, isFlipped: Bool, position: Int, total: Int)
        case finished(reviewed: Int, sessionSeconds: Int)
    }

    private let content: ContentRepositoryProtocol
    private let progress: UserProgressRepositoryProtocol
    private let config: FlashcardDeckConfig

    private var queue: [FlashcardDTO] = []
    private var index: Int = 0
    private var reviewedCount: Int = 0
    private let startedAt = Date()

    private(set) var state: SessionState = .loading
    private(set) var deckTitle: String = "Flashcards"
    var isCurrentBookmarked: Bool {
        guard case .studying(let card, _, _, _) = state else { return false }
        return progress.isFlashcardBookmarked(card.id)
    }

    init(config: FlashcardDeckConfig,
         content: ContentRepositoryProtocol = DIContainer.shared.contentRepository,
         progress: UserProgressRepositoryProtocol) {
        self.config = config
        self.content = content
        self.progress = progress
    }

    func start() {
        if let ids = config.flashcardIds {
            queue = (try? content.flashcards(ids: ids)) ?? []
            deckTitle = "Saved Cards"
        } else {
            let all = (try? content.flashcards(
                licenseCode: Constants.licenseCode,
                categoryCode: config.categoryCode,
                lang: "en"
            )) ?? []

            if config.dueOnly {
                let now = Date()
                let reviews = Dictionary(uniqueKeysWithValues:
                    progress.allFlashcardReviews().map { ($0.flashcardId, $0) })
                queue = all.filter { card in
                    if let next = reviews[card.id]?.nextReviewAt { return next <= now }
                    return true
                }
                deckTitle = "Due Today"
            } else {
                queue = all.shuffled()
                deckTitle = config.categoryCode.flatMap(Self.titleForCategory) ?? "All Cards"
            }
        }

        guard !queue.isEmpty else {
            state = .empty(message: config.dueOnly
                ? "Nothing is due right now — come back later or pick a topic deck."
                : "No cards in this deck yet.")
            return
        }
        showCurrent(flipped: false)
    }

    func flip() {
        guard case .studying(let card, let isFlipped, let pos, let total) = state else { return }
        state = .studying(card: card, isFlipped: !isFlipped, position: pos, total: total)
    }

    func grade(_ grade: FlashcardGrade) {
        guard case .studying(let card, _, _, _) = state else { return }
        try? progress.recordFlashcardReview(flashcardId: card.id, grade: grade)
        try? progress.incrementStreak(minutes: 0, questions: 0)  // touch streak
        reviewedCount += 1

        // "Again" cards loop back near the end of the queue for re-review this session.
        if grade == .again, queue.count > 1 {
            let card = queue.remove(at: index)
            let insertAt = min(queue.count, index + 3)
            queue.insert(card, at: insertAt)
        } else {
            index += 1
        }

        if index >= queue.count {
            let elapsed = Int(Date().timeIntervalSince(startedAt))
            state = .finished(reviewed: reviewedCount, sessionSeconds: elapsed)
            return
        }
        showCurrent(flipped: false)
    }

    func toggleBookmark() {
        guard case .studying(let card, _, _, _) = state else { return }
        try? progress.toggleFlashcardBookmark(flashcardId: card.id)
    }

    private func showCurrent(flipped: Bool) {
        let card = queue[index]
        state = .studying(card: card, isFlipped: flipped, position: index + 1, total: queue.count)
    }

    private static func titleForCategory(_ code: String) -> String? {
        switch code {
        case "tree_biology": return "Tree Biology"
        case "identification_and_selection": return "Identification and Selection"
        case "soil_management": return "Soil Management"
        case "installation_and_establishment": return "Installation and Establishment"
        case "pruning": return "Pruning"
        case "diagnosis_and_treatment": return "Diagnosis and Treatment"
        case "tree_protection": return "Tree Protection"
        case "tree_risk_management": return "Tree Risk Management"
        case "safe_work_practices": return "Safe Work Practices"
        case "urban_forestry": return "Urban Forestry"
        default: return nil
        }
    }
}
