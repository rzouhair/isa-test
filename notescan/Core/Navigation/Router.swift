import SwiftUI

@Observable final class Router {
    enum Route: Hashable, Identifiable {
        case onboarding
        case login
        case settings
        case paywall
        case home
        case camera
        case detection(images: [UIImage])
        case collection
        case banknoteDetails(banknote: Banknote)
        
        var id: Self {
            switch self {
            default: self
            }
        }
        
        var title: String {
            switch self {
            case .onboarding:
                return "Onboarding"
            case .login:
                return "Login"
            case .settings:
                return "Settings"
            case .paywall:
                return "Paywall"
            case .home:
                return "Home"
            case .collection:
                return "Collection"
            case .camera:
                return "Camera"
            case .detection:
                return "Banknote Detection"
            case .banknoteDetails(let banknote):
                return banknote.title
            }
        }
        
        var iconName: String {
            switch self {
            case .onboarding:
                return "person.fill"
            case .login:
                return "person.circle"
            case .settings:
                return "gear"
            case .paywall:
                return "crown"
            case .home:
                return "house"
            case .collection:
                return "bag"
            case .camera:
                return "camera.fill"
            case .detection:
                return "magnifyingglass"
            case .banknoteDetails(let banknote):
                return "money"
            }
        }
    }
    
    var tabViewRoutes: [Route] = [
        .home,
        .collection,
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
