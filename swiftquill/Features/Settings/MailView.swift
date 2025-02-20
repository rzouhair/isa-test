//
//  MailView.swift
//
//
//  Created by user on 11/10/2023.
//

import SwiftUI
import UIKit
import MessageUI

struct MailView: UIViewControllerRepresentable {

    var versionString: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
        return "Version \(appVersion ?? "") (\(buildNumber ?? ""))"
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mailViewController = MFMailComposeViewController()
        mailViewController.mailComposeDelegate = context.coordinator
        mailViewController.delegate = context.coordinator
        mailViewController.setToRecipients([Constants.supportEmail])
        mailViewController.setSubject("Sent from \(Constants.appName) app [\(versionString)]")
        return mailViewController
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
