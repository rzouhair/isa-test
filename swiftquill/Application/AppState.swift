import Foundation
import Observation

@Observable final class AppState {
    var isProUser: Bool {
        SubscriptionService.shared.isProUser
    }
    
    var wasPaywallShown: Bool = false
    var isPaywallShown: Bool = false
    
    var shouldShowPaywall: Bool {
        guard !isProUser else { return false }
        guard !wasPaywallShown else { return false }
        guard !isPaywallShown else { return false }

        return true
    }
    
    func showPaywall () {
        isPaywallShown = true
        wasPaywallShown = true
    }
}
