//
//  File.swift
//  
//
//  Created by user on 10/09/2023.
//

import Foundation

class Constants {
    /// Set up the basic constants here...
    ///
    ///
    static let appName = "Karten" /// TODO: Update to your app name
    static let privacyPolicyUrl = "https://www.notion.so/Poke-TCG-Card-Scanner-Privacy-Policy-3454d383e4768002b37cf14373c082bd" /// IMPORTANT: set this to the correct URL
    static let termsOfUseUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/" /// IMPORTANT: set this to the correct URL

    static let appleEulaUrl = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let supportEmail = "rouikaalt@gmail.com"

    /// Socials
    static let instagram = "https://instagram.com/maros_iosdev"
    static let twitter = "https://twitter.com/maros_petrus"
    static let twitch = "https://twitch.com/maros_petrus"

    /// API Keys
    static let revenueCat = "appl_JgQnDcbCPoDFMAFycVEDXapFBzo" /// RevenueCat public SDK key for Poke - TCG Card scanner
    /// RevenueCat entitlement identifier — must match the dashboard exactly.
    /// The dashboard uses the full product title as the entitlement ID for this
    /// project, verified from `CustomerInfo.entitlements.active` logs.
    static let revenueCatProEntitlement = "Poke - TCG Card scanner Pro"
    /// Offering identifier in RevenueCat dashboard (usually "default").
    static let revenueCatDefaultOffering = "Pro"
    /// Package identifiers within the offering.
    static let revenueCatYearlyPackage = "$rc_annual"
    static let revenueCatWeeklyPackage = "$rc_weekly"
    static let posthogAPIKey = "phc_yrpKbGUmHd4ixTRT3Admzj3Af3RM6BDojGH4fpavDMJB" /// IMPORTANT: Replace with your PostHog project API key
    static let posthogHost = "https://us.i.posthog.com" /// Change to eu.i.posthog.com for EU region
    static let sentryDSN = "https://6a565a2c385b8220ded6c0accc7ab6b8@o4511191277371392.ingest.us.sentry.io/4511191343169536" /// IMPORTANT: Replace with your Sentry project DSN
    
    static let proxyLambdaURL = ""
    static let cardIdentifierBaseURL = "https://d7myl3nxhryo7jlgpf5xi4j46e0oilfc.lambda-url.us-east-1.on.aws"

    static let appStoreId = "6479833602" /// IMPORTANT: set this to your App Store ID
}
