import SwiftUI

// MARK: - App Theme Configuration
// Change `current` to switch the entire app's look.

struct AppTheme {

    // ┌──────────────────────────────────────────┐
    // │  SWITCH THEME HERE                       │
    // └──────────────────────────────────────────┘
    static let current: AppTheme = .animeTCG
    // static let current: AppTheme = .sportsCards

    // MARK: - Core Colors

    /// Primary accent used for tint, buttons, links, icons
    let accent: Color
    /// Price / value highlight color
    let value: Color
    /// Scanner viewfinder bracket color
    let scannerBracket: Color
    /// FAB (floating action button) fill
    let fabFill: Color
    /// FAB shadow color
    let fabShadow: Color

    // MARK: - Onboarding Colors

    /// Dark base background for onboarding screens
    let onboardingBg: Color
    /// Slightly lighter card/container background
    let onboardingCardBg: Color
    /// Bright accent for highlights, serif text, scan line
    let accentBright: Color
    /// Secondary warm accent (value callouts, gold-like highlights)
    let accentWarm: Color
    /// Light warm accent for scan line gradient
    let accentWarmLight: Color
    /// Muted accent for badge text
    let accentMuted: Color
    /// CTA button fill (lighter accent)
    let ctaFill: Color
    /// Active progress dot color
    let dotActive: Color

    // MARK: - Gradient (summary boxes, All Cards card)

    let gradientStart: Color
    let gradientEnd: Color

    /// Convenience: the standard top-to-bottom gradient
    var summaryGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var summaryGradientDiagonal: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gradient for large price text on light backgrounds
    var valueGradient: LinearGradient {
        LinearGradient(
            colors: [gradientStart, gradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Semantic Helpers

    /// Subtle background tint (icon badges, selection highlights)
    var accentSubtle: Color { accent.opacity(0.12) }
    var accentLight: Color { accent.opacity(0.15) }
    var valueFaded: Color { value.opacity(0.6) }
}

// MARK: - Presets

extension AppTheme {

    /// Green theme — TCG / Trading Card Games (Pokemon, Magic, Yu-Gi-Oh)
    static let tcgCards = AppTheme(
        accent: Color(.systemGreen),
        value: Color(.systemGreen),
        scannerBracket: Color(hex: 0xBEF264),
        fabFill: Color(.systemGreen),
        fabShadow: Color(.systemGreen).opacity(0.3),
        onboardingBg: Color(hex: 0x0D2818),
        onboardingCardBg: Color(hex: 0x133520),
        accentBright: Color(hex: 0x5AB87A),
        accentWarm: Color(hex: 0xC8A84B),
        accentWarmLight: Color(hex: 0xF0D080),
        accentMuted: Color(hex: 0xB8E8C8),
        ctaFill: Color(hex: 0x3A9960),
        dotActive: Color(hex: 0x3A9960),
        gradientStart: Color(red: 0.22, green: 0.35, blue: 0.28),
        gradientEnd: Color(red: 0.14, green: 0.24, blue: 0.18)
    )

    /// Blue theme — Sports Cards (Baseball, Basketball, Football)
    static let sportsCards = AppTheme(
        accent: Color(red: 0.25, green: 0.48, blue: 0.95),
        value: Color(red: 0.25, green: 0.48, blue: 0.95),
        scannerBracket: Color(red: 0.55, green: 0.75, blue: 1.0),
        fabFill: Color(red: 0.25, green: 0.48, blue: 0.95),
        fabShadow: Color(red: 0.25, green: 0.48, blue: 0.95).opacity(0.3),
        onboardingBg: Color(red: 0.06, green: 0.10, blue: 0.22),
        onboardingCardBg: Color(red: 0.08, green: 0.14, blue: 0.28),
        accentBright: Color(red: 0.55, green: 0.75, blue: 1.0),
        accentWarm: Color(red: 0.85, green: 0.70, blue: 0.35),
        accentWarmLight: Color(red: 0.95, green: 0.82, blue: 0.50),
        accentMuted: Color(red: 0.70, green: 0.82, blue: 1.0),
        ctaFill: Color(red: 0.35, green: 0.58, blue: 1.0),
        dotActive: Color(red: 0.35, green: 0.58, blue: 1.0),
        gradientStart: Color(red: 0.18, green: 0.30, blue: 0.55),
        gradientEnd: Color(red: 0.10, green: 0.18, blue: 0.38)
    )

    /// Purple theme — Anime / Japanese TCG
    /// Hex reference (no code change — `Color(red:green:blue:)` values below):
    ///   accent / value / fabFill    → 0x8C59D9
    ///   scannerBracket / accentBright → 0xBF99FF
    ///   fabShadow                   → 0x8C59D9 @ 30%
    ///   onboardingBg                → 0x140D29
    ///   onboardingCardBg            → 0x1F1438
    ///   accentWarm                  → 0xE6B373
    ///   accentWarmLight             → 0xF2CC8C
    ///   accentMuted                 → 0xD1B8FF
    ///   ctaFill / dotActive         → 0xA673F2
    ///   gradientStart               → 0x4D3373
    ///   gradientEnd                 → 0x2E1F52
    static let animeTCG = AppTheme(
        accent: Color(red: 0.55, green: 0.35, blue: 0.85),
        value: Color(red: 0.55, green: 0.35, blue: 0.85),
        scannerBracket: Color(red: 0.75, green: 0.60, blue: 1.0),
        fabFill: Color(red: 0.55, green: 0.35, blue: 0.85),
        fabShadow: Color(red: 0.55, green: 0.35, blue: 0.85).opacity(0.3),
        onboardingBg: Color(red: 0.08, green: 0.05, blue: 0.16),
        onboardingCardBg: Color(red: 0.12, green: 0.08, blue: 0.22),
        accentBright: Color(red: 0.75, green: 0.60, blue: 1.0),
        accentWarm: Color(red: 0.90, green: 0.70, blue: 0.45),
        accentWarmLight: Color(red: 0.95, green: 0.80, blue: 0.55),
        accentMuted: Color(red: 0.82, green: 0.72, blue: 1.0),
        ctaFill: Color(red: 0.65, green: 0.45, blue: 0.95),
        dotActive: Color(red: 0.65, green: 0.45, blue: 0.95),
        gradientStart: Color(red: 0.30, green: 0.20, blue: 0.45),
        gradientEnd: Color(red: 0.18, green: 0.12, blue: 0.32)
    )
}

// MARK: - Shorthand

/// Global shorthand so views can write `theme.accent` instead of `AppTheme.current.accent`
let theme = AppTheme.current
