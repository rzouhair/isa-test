# Graph Report - .  (2026-05-12)

## Corpus Check
- 91 files · ~642,572 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 682 nodes · 799 edges · 84 communities detected
- Extraction: 82% EXTRACTED · 18% INFERRED · 0% AMBIGUOUS · INFERRED: 144 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]
- [[_COMMUNITY_Community 76|Community 76]]
- [[_COMMUNITY_Community 77|Community 77]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]

## God Nodes (most connected - your core abstractions)
1. `AnalyticsEvent` - 28 edges
2. `Route` - 23 edges
3. `SettingsItem` - 16 edges
4. `String` - 13 edges
5. `UnifiedCard Model` - 11 edges
6. `Router` - 10 edges
7. `PaywallYearlyViewModel` - 10 edges
8. `PaywallViewModel` - 10 edges
9. `OnboardingStep` - 10 edges
10. `OnboardingFlowView` - 10 edges

## Surprising Connections (you probably didn't know these)
- `UnifiedCard Model` --semantically_similar_to--> `SavedCard SwiftData Model`  [INFERRED] [semantically similar]
  UNIFIED_CARD_API_SPEC.md → API_SWIFT_MODEL.md
- `POST /v1/scan endpoint` --semantically_similar_to--> `CardResponse Codable`  [INFERRED] [semantically similar]
  UNIFIED_CARD_API_SPEC.md → API_SWIFT_MODEL.md
- `Scanner Screen Continuous Scan` --semantically_similar_to--> `Sports Scanner Screen`  [INFERRED] [semantically similar]
  MVP_PRD.md → MVP_PRD_SPORTS.md
- `CardRecord Collection Model` --semantically_similar_to--> `Sports CardRecord Model`  [INFERRED] [semantically similar]
  MVP_PRD.md → MVP_PRD_SPORTS.md
- `PriceEntry unified pricing` --semantically_similar_to--> `Pricing Codable`  [INFERRED] [semantically similar]
  UNIFIED_CARD_API_SPEC.md → API_SWIFT_MODEL.md

## Hyperedges (group relationships)
- **Two-Pass Vision LLM Scan Pipeline** — unified_card_api_spec_pass1_classification, unified_card_api_spec_pass2_tcg, unified_card_api_spec_pass2_sports, unified_card_api_spec_confidence_scoring, unified_card_api_spec_unifiedcard [EXTRACTED 0.95]
- **Scanner-ScanStore-SwiftData Core Loop** — mvp_prd_scanner_screen, mvp_prd_scanstore_singleton, mvp_prd_scanrecord_model, mvp_prd_cardrecord_model, api_swift_model_card_response [EXTRACTED 0.90]
- **Converter 5-Screen Onboarding Flow** — onboarding_analysis_screen_hook, onboarding_analysis_screen_value, onboarding_analysis_screen_trust, onboarding_analysis_screen_camera, onboarding_analysis_screen_paywall [EXTRACTED 0.95]

## Communities

### Community 0 - "Community 0"
Cohesion: 0.03
Nodes (36): Accordion, AccordionItem, Badge, BadgeStyle, destructive, outline, primary, secondary (+28 more)

### Community 1 - "Community 1"
Cohesion: 0.05
Nodes (12): Identifiable, ObservableObject, PaywallViewModel, PaywallYearlyViewModel, PurchaseProductDetails, XcodeProjectRenamer, SubscriptionService, Subscription (+4 more)

### Community 2 - "Community 2"
Cohesion: 0.04
Nodes (53): AnalyticsEvent, appOpened, bookmarkToggled, cheatSheetViewed, examDateSet, handbookOpened, learnSessionStarted, licenseSelected (+45 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (20): AnswerState, correct, neutral, AppPreviewCardsView, image(), CountdownView, FeaturesList, FeaturesListItem (+12 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (44): Candidate Codable, CardAttributes Codable, CardData Codable, CardIdentity Codable, CardImages Codable, CardMetadata Codable, CardResponse Codable, CardsAPI Client Class (+36 more)

### Community 5 - "Community 5"
Cohesion: 0.07
Nodes (18): App, AppMain, main(), topic_to_code(), main(), add_source_file(), cleanup_orphan_buildfiles(), find_target_obj() (+10 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (28): AnalyticsServiceProtocol, AnalyticsServiceProtocol, Hashable, PostHogAnalyticsService, FlashcardDeckConfig, QuizConfig, Route, aiTutor (+20 more)

### Community 7 - "Community 7"
Cohesion: 0.09
Nodes (6): AppState, showPaywall(), triggerPostActivationNotificationPromptIfNeeded(), OnboardingFlowView, RootView, Router

### Community 8 - "Community 8"
Cohesion: 0.08
Nodes (13): ArcShape, examprepUITests, examprepUITestsLaunchTests, OnboardingRateUsView, Triangle, add(), find_or_create_group(), add() (+5 more)

### Community 9 - "Community 9"
Cohesion: 0.08
Nodes (29): API Swift Model Reference, Card Detail Screen TCG, CardRecord Collection Model, Collection Dashboard, Price Data TCGPlayer eBay Cache, Scan Job State Machine, Scanner Screen Continuous Scan, ScanRecord SwiftData Model (+21 more)

### Community 10 - "Community 10"
Cohesion: 0.14
Nodes (8): CrashReportingServiceProtocol, ensure_buildfile(), ensure_frameworks_phase(), find_target(), main(), Decimal, String, SwiftDataDatasource

### Community 11 - "Community 11"
Cohesion: 0.13
Nodes (10): DIContainer, captureError(), captureMessage(), initialize(), sanitize(), sendDebugTestEvent(), setAnonymousUser(), Event (+2 more)

### Community 12 - "Community 12"
Cohesion: 0.13
Nodes (14): Int, Color, OnboardingConstants, OnboardingStep, hero, notifications, placeholder1, placeholder2 (+6 more)

### Community 13 - "Community 13"
Cohesion: 0.13
Nodes (9): AppDelegate, Coordinator, MailView, MFMailComposeViewControllerDelegate, NSObject, UIApplicationDelegate, UINavigationControllerDelegate, UIViewControllerRepresentable (+1 more)

### Community 14 - "Community 14"
Cohesion: 0.16
Nodes (8): Asset, BundleToken, ColorAsset.Color, Colors, ImageAsset.Image, Images, SwiftUI.Color, SwiftUI.Image

### Community 15 - "Community 15"
Cohesion: 0.15
Nodes (5): FixedSizeScrollView, View, SentryTestAlertModifier, SettingsView, ViewModifier

### Community 16 - "Community 16"
Cohesion: 0.24
Nodes (8): BundleToken, FontConvertible.Font, FontFamily, register(), registerIfNeeded(), Rubik, SwiftUI.Font, swiftUIFont()

### Community 17 - "Community 17"
Cohesion: 0.27
Nodes (7): add_grdb_package!(), ensure_resource_in_target(), ensure_source_in_target(), main(), Package, SubscriptionPeriod, SubscriptionPeriod.Unit

### Community 18 - "Community 18"
Cohesion: 0.25
Nodes (8): AppMain Bootstrap Entry Point, MVVM Clean Architecture Layout, Swift 6 Code Conventions, PaperScan CLAUDE.md Project Guide, TCGPlayer Scanner MVP PRD, SportScan MVP PRD, Architecture Overview Two Apps One API, Unified Card API Spec v1.0

### Community 19 - "Community 19"
Cohesion: 0.38
Nodes (7): Hero Background Image, Fanned Magic The Gathering Cards, Desaturated Monochrome Treatment, Magic The Gathering Card Back, PaperScan App, Purple Gradient Backdrop, TCG Collection Theme

### Community 20 - "Community 20"
Cohesion: 0.4
Nodes (2): AuthService, AuthServiceProtocol

### Community 21 - "Community 21"
Cohesion: 0.4
Nodes (6): Competitor App CardDex, Competitor App CardScan Pro, Onboarding Competitive Analysis, Feature Gap Analysis PaperScan vs Competition, Competitor App Scanemon, Competitor App Snapdex

### Community 22 - "Community 22"
Cohesion: 0.5
Nodes (1): AuthStore

### Community 23 - "Community 23"
Cohesion: 0.5
Nodes (3): SignInProvider, apple, google

### Community 24 - "Community 24"
Cohesion: 0.5
Nodes (1): Preview

### Community 25 - "Community 25"
Cohesion: 0.5
Nodes (4): CSV Export M3, Offline Behaviour M3, Push Notifications M3, Phase 4 Polish Retention Cleanup Tasks

### Community 26 - "Community 26"
Cohesion: 0.5
Nodes (4): Asset catalog image likely used for app author/about screen, Author portrait photo (young man, outdoor greenery background), Outdoor nature setting with foliage and rocks, Man with short dark hair, beard, white t-shirt

### Community 27 - "Community 27"
Cohesion: 0.67
Nodes (1): examprepTests

### Community 28 - "Community 28"
Cohesion: 0.67
Nodes (1): SKStoreReviewController

### Community 29 - "Community 29"
Cohesion: 0.67
Nodes (1): JSONDecoder

### Community 30 - "Community 30"
Cohesion: 0.67
Nodes (1): UINavigationController

### Community 31 - "Community 31"
Cohesion: 1.0
Nodes (1): Constants

### Community 32 - "Community 32"
Cohesion: 1.0
Nodes (1): AppTheme

### Community 33 - "Community 33"
Cohesion: 1.0
Nodes (1): UserRepositoryProtocol

### Community 34 - "Community 34"
Cohesion: 1.0
Nodes (1): SwiftUI.Font

### Community 35 - "Community 35"
Cohesion: 1.0
Nodes (0): 

### Community 36 - "Community 36"
Cohesion: 1.0
Nodes (0): 

### Community 37 - "Community 37"
Cohesion: 1.0
Nodes (0): 

### Community 38 - "Community 38"
Cohesion: 1.0
Nodes (2): TCG Scanner Implementation Plan, Risk Log

### Community 39 - "Community 39"
Cohesion: 1.0
Nodes (0): 

### Community 40 - "Community 40"
Cohesion: 1.0
Nodes (0): 

### Community 41 - "Community 41"
Cohesion: 1.0
Nodes (0): 

### Community 42 - "Community 42"
Cohesion: 1.0
Nodes (0): 

### Community 43 - "Community 43"
Cohesion: 1.0
Nodes (0): 

### Community 44 - "Community 44"
Cohesion: 1.0
Nodes (0): 

### Community 45 - "Community 45"
Cohesion: 1.0
Nodes (1): Immediate Fixes Before New Onboarding

### Community 46 - "Community 46"
Cohesion: 1.0
Nodes (1): GET /v1/search endpoint

### Community 47 - "Community 47"
Cohesion: 1.0
Nodes (1): GET /v1/catalog/sets endpoint

### Community 48 - "Community 48"
Cohesion: 1.0
Nodes (1): Local Card Index Offline Autocomplete

### Community 49 - "Community 49"
Cohesion: 1.0
Nodes (1): Grading API Documentation

### Community 50 - "Community 50"
Cohesion: 1.0
Nodes (1): TCG Scanner Progress Log

### Community 51 - "Community 51"
Cohesion: 1.0
Nodes (1): PaperScan App Icon (1024x1024)

### Community 52 - "Community 52"
Cohesion: 1.0
Nodes (1): TCG Card Illustration

### Community 53 - "Community 53"
Cohesion: 1.0
Nodes (1): Pokeball Symbol

### Community 54 - "Community 54"
Cohesion: 1.0
Nodes (1): Scanner Corner Brackets

### Community 55 - "Community 55"
Cohesion: 1.0
Nodes (1): Purple Rounded Background

### Community 56 - "Community 56"
Cohesion: 1.0
Nodes (1): TCG Text Label

### Community 57 - "Community 57"
Cohesion: 1.0
Nodes (1): Metallic Shield with Checkmark

### Community 58 - "Community 58"
Cohesion: 1.0
Nodes (1): 3D Red Padlock Icon

### Community 59 - "Community 59"
Cohesion: 1.0
Nodes (1): 3D Camera Icon

### Community 60 - "Community 60"
Cohesion: 1.0
Nodes (1): PaperScan App Icon

### Community 61 - "Community 61"
Cohesion: 1.0
Nodes (1): TCG Card Illustration

### Community 62 - "Community 62"
Cohesion: 1.0
Nodes (1): Scan Frame Corners

### Community 63 - "Community 63"
Cohesion: 1.0
Nodes (1): Pokeball Symbol

### Community 64 - "Community 64"
Cohesion: 1.0
Nodes (1): Purple Rounded Background

### Community 65 - "Community 65"
Cohesion: 1.0
Nodes (1): Magic Top Hat with Wand

### Community 66 - "Community 66"
Cohesion: 1.0
Nodes (1): Silver Star Magic Wand

### Community 67 - "Community 67"
Cohesion: 1.0
Nodes (1): Red Hat Band

### Community 68 - "Community 68"
Cohesion: 1.0
Nodes (1): Google Logo Icon

### Community 69 - "Community 69"
Cohesion: 1.0
Nodes (1): Stack of Cash with Dollar Sign

### Community 70 - "Community 70"
Cohesion: 1.0
Nodes (1): SwiftSail Pro Paywall Mockup

### Community 71 - "Community 71"
Cohesion: 1.0
Nodes (1): Free vs Pro Features Table

### Community 72 - "Community 72"
Cohesion: 1.0
Nodes (1): 4.7 Star Rating 200+ Reviews

### Community 73 - "Community 73"
Cohesion: 1.0
Nodes (1): Streamlined Trading Journal Testimonial

### Community 74 - "Community 74"
Cohesion: 1.0
Nodes (1): Get SwiftSail Pro CTA

### Community 75 - "Community 75"
Cohesion: 1.0
Nodes (1): Xcode Project Navigator - SwiftSail

### Community 76 - "Community 76"
Cohesion: 1.0
Nodes (1): Features Folder (Onboarding, Analytics, Settings, Purchases, Dashboard, Auth)

### Community 77 - "Community 77"
Cohesion: 1.0
Nodes (1): Architecture Folders (Domain, Data, Presentation)

### Community 78 - "Community 78"
Cohesion: 1.0
Nodes (1): Swift Files (AppDependencies, ContentView, AppRouter, AppDelegate, SceneDelegate, Constants)

### Community 79 - "Community 79"
Cohesion: 1.0
Nodes (1): Onboarding Screen 2 - UI Components Showcase

### Community 80 - "Community 80"
Cohesion: 1.0
Nodes (1): Button Component Samples (Sign in with Apple, I agree)

### Community 81 - "Community 81"
Cohesion: 1.0
Nodes (1): Card Component - Create Account Form

### Community 82 - "Community 82"
Cohesion: 1.0
Nodes (1): Bottom Tab Bar - Dashboard / UI Components

### Community 83 - "Community 83"
Cohesion: 1.0
Nodes (1): iPhone Device Frame Mockup

## Knowledge Gaps
- **194 isolated node(s):** `Dedup key helper — lowercase, collapse whitespace, strip trailing punctuation.`, `Constants`, `AppTheme`, `onboarding`, `home` (+189 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 31`** (2 nodes): `Constants`, `Constants.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (2 nodes): `Theme.swift`, `AppTheme`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (2 nodes): `UserRepositoryProtocol.swift`, `UserRepositoryProtocol`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (2 nodes): `FontExtension.swift`, `SwiftUI.Font`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (2 nodes): `find_or_create_group()`, `project_add_edit_profile.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (2 nodes): `add_source()`, `project_add_phase3.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 37`** (2 nodes): `find_or_create_group()`, `project_reorg.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 38`** (2 nodes): `TCG Scanner Implementation Plan`, `Risk Log`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 39`** (1 nodes): `project_add_handbooks_json.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (1 nodes): `project_inspect.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (1 nodes): `project_fix.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 42`** (1 nodes): `project_fix_test_path.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (1 nodes): `project_remove_grdb.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (1 nodes): `project_clean_tests_sources.rb`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (1 nodes): `Immediate Fixes Before New Onboarding`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 46`** (1 nodes): `GET /v1/search endpoint`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (1 nodes): `GET /v1/catalog/sets endpoint`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 48`** (1 nodes): `Local Card Index Offline Autocomplete`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 49`** (1 nodes): `Grading API Documentation`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 50`** (1 nodes): `TCG Scanner Progress Log`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 51`** (1 nodes): `PaperScan App Icon (1024x1024)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 52`** (1 nodes): `TCG Card Illustration`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 53`** (1 nodes): `Pokeball Symbol`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 54`** (1 nodes): `Scanner Corner Brackets`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 55`** (1 nodes): `Purple Rounded Background`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 56`** (1 nodes): `TCG Text Label`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 57`** (1 nodes): `Metallic Shield with Checkmark`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 58`** (1 nodes): `3D Red Padlock Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 59`** (1 nodes): `3D Camera Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 60`** (1 nodes): `PaperScan App Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 61`** (1 nodes): `TCG Card Illustration`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 62`** (1 nodes): `Scan Frame Corners`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 63`** (1 nodes): `Pokeball Symbol`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 64`** (1 nodes): `Purple Rounded Background`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 65`** (1 nodes): `Magic Top Hat with Wand`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 66`** (1 nodes): `Silver Star Magic Wand`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 67`** (1 nodes): `Red Hat Band`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 68`** (1 nodes): `Google Logo Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 69`** (1 nodes): `Stack of Cash with Dollar Sign`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 70`** (1 nodes): `SwiftSail Pro Paywall Mockup`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 71`** (1 nodes): `Free vs Pro Features Table`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 72`** (1 nodes): `4.7 Star Rating 200+ Reviews`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 73`** (1 nodes): `Streamlined Trading Journal Testimonial`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 74`** (1 nodes): `Get SwiftSail Pro CTA`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 75`** (1 nodes): `Xcode Project Navigator - SwiftSail`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 76`** (1 nodes): `Features Folder (Onboarding, Analytics, Settings, Purchases, Dashboard, Auth)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 77`** (1 nodes): `Architecture Folders (Domain, Data, Presentation)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 78`** (1 nodes): `Swift Files (AppDependencies, ContentView, AppRouter, AppDelegate, SceneDelegate, Constants)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 79`** (1 nodes): `Onboarding Screen 2 - UI Components Showcase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 80`** (1 nodes): `Button Component Samples (Sign in with Apple, I agree)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 81`** (1 nodes): `Card Component - Create Account Form`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 82`** (1 nodes): `Bottom Tab Bar - Dashboard / UI Components`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 83`** (1 nodes): `iPhone Device Frame Mockup`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `String` connect `Community 10` to `Community 0`, `Community 1`, `Community 11`, `Community 3`?**
  _High betweenness centrality (0.089) - this node is a cross-community bridge._
- **Why does `OnboardingFlowView` connect `Community 7` to `Community 0`, `Community 12`?**
  _High betweenness centrality (0.085) - this node is a cross-community bridge._
- **Why does `handleItemTap()` connect `Community 2` to `Community 1`, `Community 11`, `Community 5`, `Community 15`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **Are the 9 inferred relationships involving `String` (e.g. with `.toLocalCurrencyString()` and `.scheduleTrialReminderIfNeeded()`) actually correct?**
  _`String` has 9 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Dedup key helper — lowercase, collapse whitespace, strip trailing punctuation.`, `Constants`, `AppTheme` to the rest of the system?**
  _194 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._