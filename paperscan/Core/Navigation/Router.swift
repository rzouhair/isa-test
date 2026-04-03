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

        var id: String {
            switch self {
            case .detection: return "detection"
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
