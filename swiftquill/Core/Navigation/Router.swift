import SwiftUI

@Observable final class Router {
    enum Route: Hashable, CaseIterable, Identifiable {
        case onboarding
        case login
        case settings
        case paywall
        case home
        
        var id: Self { self }
        
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
                return "Chat"
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
                return "message"
            }
        }
    }
    
    var tabViewRoutes: [Route] = [
        .home,
        .settings,
    ]
    
    var navigationPath: [Route] = [] {
        didSet {
            print(navigationPath)
        }
    }
    var presentedSheet: Route?
    
    func navigate(to destination: Route, replace: Bool? = false, allowDuplicates: Bool? = false) {
        if replace == true {
            dismissSheet()
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
    
    func navigateToRoot() {
        navigationPath.removeAll()
    }
    
    func presentSheet(_ route: Route) {
        presentedSheet = route
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
}
