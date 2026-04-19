//
//  UIApplicationExtension.swift
//  poke
//
//  Created by user on 06/03/2024.
//

import UIKit

public extension UIApplication {
    static func topViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }

    static func showAlert(title: String, message: String, action: (() -> Void)? = nil) {
        // Callers often trigger this right after dismissing a fullScreenCover
        // (e.g. paywall). The hosting controller is still being torn down on
        // the current runloop, so `topViewController` returns a view that's
        // already leaving the window hierarchy — leading to:
        //   "Attempt to present … whose view is not in the window hierarchy"
        // Defer to the next runloop so the dismissal completes first, then
        // retry on the now-stable top controller.
        DispatchQueue.main.async {
            presentAlertWhenReady(title: title, message: message, action: action, attempt: 0)
        }
    }

    private static func presentAlertWhenReady(title: String, message: String, action: (() -> Void)?, attempt: Int) {
        guard let top = topViewController(), top.view.window != nil, top.presentedViewController == nil else {
            // Up to ~500ms of retries; anything longer is a genuine bug, not a race.
            if attempt < 5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    presentAlertWhenReady(title: title, message: message, action: action, attempt: attempt + 1)
                }
            }
            return
        }

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            if let action {
                action()
            } else {
                alertController.dismiss(animated: true)
            }
        }
        alertController.addAction(okAction)
        top.present(alertController, animated: true)
    }

    var keyWindow: UIWindow? {
        return self.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .first(where: { $0 is UIWindowScene })
            .flatMap({ $0 as? UIWindowScene })?.windows
            .first(where: \.isKeyWindow)
    }
}
