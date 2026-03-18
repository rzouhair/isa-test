import SwiftUI
import Foundation
import Observation

@Observable
class HomeViewModel {
    private var router: Router
    private var appState: AppState

    init(router: Router, appState: AppState) {
        self.router = router
        self.appState = appState
    }

    func openCamera() {
        if appState.isProUser {
            router.presentFullscreenCover(.camera)
        } else {
            appState.showPaywall()
        }
    }
}
