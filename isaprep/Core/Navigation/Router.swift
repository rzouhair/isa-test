import SwiftUI

struct QuizConfig: Hashable, Sendable {
    let kind: SessionKind
    let licenseCode: String
    let categoryCode: String?
    let questionIds: [Int]
    let passThreshold: Double
    let timeLimitSec: Int?
}

struct FlashcardDeckConfig: Hashable, Sendable {
    /// nil = full library deck (all 250 cards). Otherwise a topic deck (25 cards).
    let categoryCode: String?
    /// nil = ordered by id; otherwise pre-resolved IDs (bookmarks, due-only, etc.).
    let flashcardIds: [Int]?
    /// When true, only surface cards whose `nextReviewAt` is due (or never seen).
    let dueOnly: Bool
}

@Observable final class Router {
    enum Route: Hashable, Identifiable {
        case onboarding
        case home
        case progress
        case settings
        case paywall
        case categoryList
        case practiceTestList(categoryCode: String)
        case quizSession(config: QuizConfig)
        case resumeQuizSession(sessionId: UUID)
        case quizResult(sessionId: UUID)
        case reviewSession(sessionId: UUID)
        case learnLevelList(categoryCode: String)
        case weakQuestions
        case statsDashboard
        case examDatePicker
        case bookmarks
        case aiTutor(questionId: Int?)
        case flashcardsLibrary
        case flashcardSession(config: FlashcardDeckConfig)
        case flashcardBookmarks

        var id: String {
            switch self {
            case .practiceTestList(let c): return "practiceTestList-\(c)"
            case .quizSession(let c): return "quizSession-\(c.hashValue)"
            case .resumeQuizSession(let id): return "resumeQuizSession-\(id)"
            case .quizResult(let id): return "quizResult-\(id)"
            case .reviewSession(let id): return "reviewSession-\(id)"
            case .learnLevelList(let c): return "learnLevelList-\(c)"
            case .aiTutor(let id): return "aiTutor-\(id.map(String.init) ?? "none")"
            case .flashcardSession(let c): return "flashcardSession-\(c.hashValue)"
            default: return String(describing: self)
            }
        }

        var title: String {
            switch self {
            case .onboarding: return "Onboarding"
            case .home: return "Home"
            case .progress: return "Progress"
            case .settings: return "Settings"
            case .paywall: return "Paywall"
            case .categoryList: return "Topics"
            case .practiceTestList: return "Practice Tests"
            case .quizSession: return "Quiz"
            case .resumeQuizSession: return "Quiz"
            case .quizResult: return "Results"
            case .reviewSession: return "Review"
            case .learnLevelList: return "Learn"
            case .weakQuestions: return "Weak Questions"
            case .statsDashboard: return "Progress"
            case .examDatePicker: return "Exam Date"
            case .bookmarks: return "Bookmarks"
            case .aiTutor: return "AI Tutor"
            case .flashcardsLibrary: return "Flashcards"
            case .flashcardSession: return "Study"
            case .flashcardBookmarks: return "Saved Cards"
            }
        }

        var iconName: String {
            switch self {
            case .onboarding: return "person.fill"
            case .home: return "house"
            case .progress: return "chart.bar"
            case .settings: return "gear"
            case .paywall: return "crown"
            case .categoryList: return "square.grid.2x2"
            case .practiceTestList: return "list.number"
            case .quizSession: return "questionmark.circle"
            case .resumeQuizSession: return "play.fill"
            case .quizResult: return "chart.bar.doc.horizontal"
            case .reviewSession: return "text.magnifyingglass"
            case .learnLevelList: return "graduationcap"
            case .weakQuestions: return "bolt"
            case .statsDashboard: return "chart.bar"
            case .examDatePicker: return "calendar"
            case .bookmarks: return "bookmark"
            case .aiTutor: return "sparkles"
            case .flashcardsLibrary: return "rectangle.stack"
            case .flashcardSession: return "rectangle.on.rectangle"
            case .flashcardBookmarks: return "bookmark.fill"
            }
        }
    }

    var navigationPath: [Route] = []
    var presentedSheet: Route?
    var presentedFullscreenCover: Route?

    func navigate(to destination: Route, replace: Bool? = false, allowDuplicates: Bool? = false) {
        if replace == true {
            dismissSheet()
            dismissFullscreenCover()
            navigationPath = [destination]
        } else {
            if allowDuplicates == true || (allowDuplicates == false && navigationPath.last != destination) {
                navigationPath.append(destination)
            }
        }
    }

    func navigateBack() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func navigateToRoot(route: Route? = nil) {
        navigationPath.removeAll()
        if let route { navigate(to: route, replace: true) }
    }

    /// Replace top of stack — useful for "Try Again" where the replaced
    /// session config mustn't leave a stale result screen above it.
    func replaceTop(with route: Route) {
        if !navigationPath.isEmpty { navigationPath.removeLast() }
        navigationPath.append(route)
    }

    func presentSheet(_ route: Route) {
        dismissFullscreenCover()
        presentedSheet = route
    }

    func dismissSheet() { presentedSheet = nil }

    func presentFullscreenCover(_ route: Route) {
        dismissSheet()
        presentedFullscreenCover = route
    }

    func dismissFullscreenCover() { presentedFullscreenCover = nil }

    /// Gate any pro-only destination. If user isn't Pro, shows paywall and skips
    /// navigation. Use for every session start (practice, simulator, learn,
    /// weak-question, bookmark, daily review, resume, review, flashcards).
    func startSession(_ route: Route, gatedBy appState: AppState) {
        guard appState.isProUser else {
            DIContainer.shared.analyticsService.capture(
                .paywallViewed,
                properties: ["source": "session_gate"]
            )
            appState.showPaywall()
            return
        }
        navigate(to: route)
    }
}
