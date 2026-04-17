import SwiftUI
import UIKit

@Observable final class Router {
    enum Route: Hashable, Identifiable {
        case onboarding
        case settings
        case paywall
        case home
        case camera
        case detection(images: [UIImage])
        case scanner
        case collection
        case cardDetail(CardRecord)
        case collectionDetail(CardCollection)
        case search
        case watchlist
        case grading
        case gradingHistory
        case gradeDetail(GradeRecord)

        var id: String {
            switch self {
            case .detection: return "detection"
            case .cardDetail(let card): return "cardDetail-\(card.id)"
            case .collectionDetail(let col): return "collectionDetail-\(col.id)"
            case .gradeDetail(let grade): return "gradeDetail-\(grade.id)"
            default: return String(describing: self)
            }
        }

        static func == (lhs: Route, rhs: Route) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        var title: String {
            switch self {
            case .onboarding: return "Onboarding"
            case .settings: return "Settings"
            case .paywall: return "Paywall"
            case .home: return "Home"
            case .camera: return "Camera"
            case .detection: return "Detection"
            case .scanner: return "Scanner"
            case .collection: return "Collection"
            case .cardDetail: return "Card Detail"
            case .collectionDetail: return "Collection"
            case .search: return "Search"
            case .watchlist: return "Watchlist"
            case .grading: return "Grading"
            case .gradingHistory: return "Grading History"
            case .gradeDetail: return "Grade Detail"
            }
        }

        var iconName: String {
            switch self {
            case .onboarding: return "person.fill"
            case .settings: return "gear"
            case .paywall: return "crown"
            case .home: return "house"
            case .camera: return "camera.fill"
            case .detection: return "magnifyingglass"
            case .scanner: return "camera.viewfinder"
            case .collection: return "square.stack"
            case .cardDetail: return "creditcard"
            case .collectionDetail: return "square.stack"
            case .search: return "magnifyingglass"
            case .watchlist: return "eye"
            case .grading: return "star.circle"
            case .gradingHistory: return "star.circle"
            case .gradeDetail: return "star.circle"
            }
        }
    }

    var tabViewRoutes: [Route] = [
        .home,
        .home
    ]
    
    var navigationPath: [Route] = [] {
        didSet {
            print(navigationPath)
        }
    }
    var presentedSheet: Route?
    var presentedFullscreenCover: Route?
    
    func navigate(to destination: Route, replace: Bool? = false, allowDuplicates: Bool? = false) {
        if replace == true {
            dismissSheet()
            dismissFullscreenCover()
            navigationPath = [destination]
        } else {
            if (allowDuplicates == true || (allowDuplicates == false && navigationPath.last != destination)) {
                navigationPath.append(destination)
            }
        }
    }
    
    func navigateBack() {
        navigationPath.removeLast()
    }
    
    func navigateToRoot(route: Route? = nil) {
        navigationPath.removeAll()
        
        if let navigateToRoute = route {
            navigate(to: navigateToRoute, replace: true)
        }
    }

    func presentSheet(_ route: Route) {
        dismissFullscreenCover()
        presentedSheet = route
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func presentFullscreenCover(_ route: Route) {
        dismissSheet()
        presentedFullscreenCover = route
    }
    
    func dismissFullscreenCover() {
        presentedFullscreenCover = nil
    }
}
