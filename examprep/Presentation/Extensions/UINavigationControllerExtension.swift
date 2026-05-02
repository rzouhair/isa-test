//
//  UINavigationControllerExtension.swift
//  examprep
//
//  Created by user on 06/03/2024.
//

import SwiftUI

extension UINavigationController {
    func pushView<V: View>(_ view: V, animated: Bool = true) {
        pushViewController(UIHostingController(rootView: view), animated: animated)
    }
}
