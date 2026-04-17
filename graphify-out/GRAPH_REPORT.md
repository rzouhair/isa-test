# Graph Report - .  (2026-04-16)

## Corpus Check
- Large corpus: 160 files · ~677,902 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder, or use --no-semantic to run AST-only.

## Summary
- 1348 nodes · 2081 edges · 86 communities detected
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 511 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Shared UI Components|Shared UI Components]]
- [[_COMMUNITY_AI Service Layer|AI Service Layer]]
- [[_COMMUNITY_Card API Models|Card API Models]]
- [[_COMMUNITY_Card Detail View|Card Detail View]]
- [[_COMMUNITY_Card Model Coding Keys|Card Model Coding Keys]]
- [[_COMMUNITY_App Lifecycle & Delegates|App Lifecycle & Delegates]]
- [[_COMMUNITY_App Bootstrap & Analytics|App Bootstrap & Analytics]]
- [[_COMMUNITY_Paywall & Subscriptions|Paywall & Subscriptions]]
- [[_COMMUNITY_Collection Sorting & Filters|Collection Sorting & Filters]]
- [[_COMMUNITY_OpenAI Parser & Detection|OpenAI Parser & Detection]]
- [[_COMMUNITY_Camera Service|Camera Service]]
- [[_COMMUNITY_Home & App State|Home & App State]]
- [[_COMMUNITY_Swift API Model Docs|Swift API Model Docs]]
- [[_COMMUNITY_CSV ImportExport Service|CSV Import/Export Service]]
- [[_COMMUNITY_AI Service Errors|AI Service Errors]]
- [[_COMMUNITY_MVP PRD Concepts|MVP PRD Concepts]]
- [[_COMMUNITY_Grading API Models|Grading API Models]]
- [[_COMMUNITY_Analytics Events Enum|Analytics Events Enum]]
- [[_COMMUNITY_Grading Capture Steps|Grading Capture Steps]]
- [[_COMMUNITY_Generated Color Assets|Generated Color Assets]]
- [[_COMMUNITY_Onboarding Welcome Flow|Onboarding Welcome Flow]]
- [[_COMMUNITY_Generated Fonts|Generated Fonts]]
- [[_COMMUNITY_UI Tests|UI Tests]]
- [[_COMMUNITY_Scan Correction State|Scan Correction State]]
- [[_COMMUNITY_Sail Button Styles|Sail Button Styles]]
- [[_COMMUNITY_Project Architecture Docs|Project Architecture Docs]]
- [[_COMMUNITY_Badge Component|Badge Component]]
- [[_COMMUNITY_Hero Background Image|Hero Background Image]]
- [[_COMMUNITY_Authentication Service|Authentication Service]]
- [[_COMMUNITY_Competitor Onboarding Analysis|Competitor Onboarding Analysis]]
- [[_COMMUNITY_Subscription Period Helpers|Subscription Period Helpers]]
- [[_COMMUNITY_Auth Store|Auth Store]]
- [[_COMMUNITY_Sign-In Providers Enum|Sign-In Providers Enum]]
- [[_COMMUNITY_SwiftData Preview Helper|SwiftData Preview Helper]]
- [[_COMMUNITY_Phase 4 Roadmap Tasks|Phase 4 Roadmap Tasks]]
- [[_COMMUNITY_Author Portrait Asset|Author Portrait Asset]]
- [[_COMMUNITY_Item Data Model|Item Data Model]]
- [[_COMMUNITY_DI Container|DI Container]]
- [[_COMMUNITY_AI Tool Definition|AI Tool Definition]]
- [[_COMMUNITY_StoreKit Review Extension|StoreKit Review Extension]]
- [[_COMMUNITY_UINavigationController Extension|UINavigationController Extension]]
- [[_COMMUNITY_Unit Tests|Unit Tests]]
- [[_COMMUNITY_App Constants|App Constants]]
- [[_COMMUNITY_App Theme|App Theme]]
- [[_COMMUNITY_User Repository Protocol|User Repository Protocol]]
- [[_COMMUNITY_SwiftUI Font Extension|SwiftUI Font Extension]]
- [[_COMMUNITY_TCG Scanner Plan & Risks|TCG Scanner Plan & Risks]]
- [[_COMMUNITY_Pre-Onboarding Fixes|Pre-Onboarding Fixes]]
- [[_COMMUNITY_Search API Endpoint|Search API Endpoint]]
- [[_COMMUNITY_Sets Catalog Endpoint|Sets Catalog Endpoint]]
- [[_COMMUNITY_Offline Card Autocomplete|Offline Card Autocomplete]]
- [[_COMMUNITY_Grading API Docs|Grading API Docs]]
- [[_COMMUNITY_TCG Scanner Progress Log|TCG Scanner Progress Log]]
- [[_COMMUNITY_App Icon Container|App Icon Container]]
- [[_COMMUNITY_Logo Card Illustration|Logo Card Illustration]]
- [[_COMMUNITY_Logo Pokeball Symbol|Logo Pokeball Symbol]]
- [[_COMMUNITY_Logo Scan Corners|Logo Scan Corners]]
- [[_COMMUNITY_Logo Purple Backdrop|Logo Purple Backdrop]]
- [[_COMMUNITY_Logo TCG Text Label|Logo TCG Text Label]]
- [[_COMMUNITY_Shield Checkmark Icon|Shield Checkmark Icon]]
- [[_COMMUNITY_Red Padlock Icon|Red Padlock Icon]]
- [[_COMMUNITY_3D Camera Icon|3D Camera Icon]]
- [[_COMMUNITY_AppIcon Container|AppIcon Container]]
- [[_COMMUNITY_AppIcon Card Illustration|AppIcon Card Illustration]]
- [[_COMMUNITY_AppIcon Scan Corners|AppIcon Scan Corners]]
- [[_COMMUNITY_AppIcon Pokeball Symbol|AppIcon Pokeball Symbol]]
- [[_COMMUNITY_AppIcon Purple Backdrop|AppIcon Purple Backdrop]]
- [[_COMMUNITY_Magic Top Hat Icon|Magic Top Hat Icon]]
- [[_COMMUNITY_Magic Star Wand Icon|Magic Star Wand Icon]]
- [[_COMMUNITY_Magic Red Band Icon|Magic Red Band Icon]]
- [[_COMMUNITY_Google Logo Asset|Google Logo Asset]]
- [[_COMMUNITY_Cash Stack Icon|Cash Stack Icon]]
- [[_COMMUNITY_Onboarding Paywall Mockup|Onboarding Paywall Mockup]]
- [[_COMMUNITY_Pro Features Table|Pro Features Table]]
- [[_COMMUNITY_Reviews Rating Badge|Reviews Rating Badge]]
- [[_COMMUNITY_Testimonial Text|Testimonial Text]]
- [[_COMMUNITY_Paywall CTA Button|Paywall CTA Button]]
- [[_COMMUNITY_Xcode Navigator Screenshot|Xcode Navigator Screenshot]]
- [[_COMMUNITY_Features Folder Structure|Features Folder Structure]]
- [[_COMMUNITY_Architecture Folders Layout|Architecture Folders Layout]]
- [[_COMMUNITY_Core Swift Files|Core Swift Files]]
- [[_COMMUNITY_UI Components Screenshot|UI Components Screenshot]]
- [[_COMMUNITY_Sign-In Button Samples|Sign-In Button Samples]]
- [[_COMMUNITY_Account Form Card|Account Form Card]]
- [[_COMMUNITY_Dashboard Tab Bar|Dashboard Tab Bar]]
- [[_COMMUNITY_iPhone Device Mockup|iPhone Device Mockup]]

## God Nodes (most connected - your core abstractions)
1. `CodingKeys` - 90 edges
2. `CodingKeys` - 51 edges
3. `text` - 46 edges
4. `font()` - 46 edges
5. `String` - 34 edges
6. `image()` - 32 edges
7. `AnalyticsEvent` - 28 edges
8. `data` - 22 edges
9. `CodingKeys` - 22 edges
10. `Route` - 21 edges

## Surprising Connections (you probably didn't know these)
- `SavedCard SwiftData Model` --semantically_similar_to--> `UnifiedCard Model`  [INFERRED] [semantically similar]
  API_SWIFT_MODEL.md → UNIFIED_CARD_API_SPEC.md
- `CardResponse Codable` --semantically_similar_to--> `POST /v1/scan endpoint`  [INFERRED] [semantically similar]
  API_SWIFT_MODEL.md → UNIFIED_CARD_API_SPEC.md
- `Sports Scanner Screen` --semantically_similar_to--> `Scanner Screen Continuous Scan`  [INFERRED] [semantically similar]
  MVP_PRD_SPORTS.md → MVP_PRD.md
- `Sports CardRecord Model` --semantically_similar_to--> `CardRecord Collection Model`  [INFERRED] [semantically similar]
  MVP_PRD_SPORTS.md → MVP_PRD.md
- `Pricing Codable` --semantically_similar_to--> `PriceEntry unified pricing`  [INFERRED] [semantically similar]
  API_SWIFT_MODEL.md → UNIFIED_CARD_API_SPEC.md

## Hyperedges (group relationships)
- **Two-Pass Vision LLM Scan Pipeline** — unified_card_api_spec_pass1_classification, unified_card_api_spec_pass2_tcg, unified_card_api_spec_pass2_sports, unified_card_api_spec_confidence_scoring, unified_card_api_spec_unifiedcard [EXTRACTED 0.95]
- **Scanner-ScanStore-SwiftData Core Loop** — mvp_prd_scanner_screen, mvp_prd_scanstore_singleton, mvp_prd_scanrecord_model, mvp_prd_cardrecord_model, api_swift_model_card_response [EXTRACTED 0.90]
- **Converter 5-Screen Onboarding Flow** — onboarding_analysis_screen_hook, onboarding_analysis_screen_value, onboarding_analysis_screen_trust, onboarding_analysis_screen_camera, onboarding_analysis_screen_paywall [EXTRACTED 0.95]

## Communities

### Community 0 - "Shared UI Components"
Cohesion: 0.02
Nodes (66): AboutAuthorView, AboutAuthorView_Previews, Accordion, AccordionItem, AddToCollectionSheet, AppPreviewCardsView, ArcShape, Banner (+58 more)

### Community 1 - "AI Service Layer"
Cohesion: 0.04
Nodes (41): AIServiceProvider, Message, info, ButtonStyle, result, CardIdentifierError, decodingFailed, invalidResponse (+33 more)

### Community 2 - "Card API Models"
Cohesion: 0.05
Nodes (66): Candidate, CardAttributes, CardData, CardIdentity, CardImages, CardMetadata, CardResponse, ChartDataPoint (+58 more)

### Community 3 - "Card Detail View"
Cohesion: 0.06
Nodes (16): text, image(), CardDetailView, font(), GradeDetailView, GradingHistoryView, GradingResultsView, HomeView (+8 more)

### Community 4 - "Card Model Coding Keys"
Cohesion: 0.02
Nodes (84): CodingKeys, attack, attacks, attribute, attributes, avgDailyVolume, cacheHit, candidates (+76 more)

### Community 5 - "App Lifecycle & Delegates"
Cohesion: 0.03
Nodes (30): AppDelegate, AVCapturePhotoCaptureDelegate, PreviewContainerView, ScannerCameraPreview, ScannerPhotoCaptureDelegate, CameraPreviewView, CameraView, PhotoCaptureDelegate (+22 more)

### Community 6 - "App Bootstrap & Analytics"
Cohesion: 0.05
Nodes (18): AnalyticsServiceProtocol, App, AppMain, date, set, CardCollection, CardRecord, CrashReportingServiceProtocol (+10 more)

### Community 7 - "Paywall & Subscriptions"
Cohesion: 0.05
Nodes (14): ObservableObject, PaywallViewModel, PaywallYearlyViewModel, PurchaseProductDetails, XcodeProjectRenamer, messageUs, restorePurchase, SettingsViewModel (+6 more)

### Community 8 - "Collection Sorting & Filters"
Cohesion: 0.04
Nodes (54): CaseIterable, CollectionSortMode, nameAsc, newest, valueAsc, valueDesc, ExportScope, all (+46 more)

### Community 9 - "OpenAI Parser & Detection"
Cohesion: 0.03
Nodes (50): CodingKeys, arguments, cachedTokens, callId, content, createdAt, description, domains (+42 more)

### Community 10 - "Camera Service"
Cohesion: 0.05
Nodes (14): AnalyticsServiceProtocol, CameraService, Equatable, GradeRecord, GradingFlowView, FlowPhase, capturing, error (+6 more)

### Community 11 - "Home & App State"
Cohesion: 0.05
Nodes (23): AppState, Hashable, HomeViewModel, Color, OnboardingConstants, OnboardingFlowView, Route, camera (+15 more)

### Community 12 - "Swift API Model Docs"
Cohesion: 0.05
Nodes (44): Candidate Codable, CardAttributes Codable, CardData Codable, CardIdentity Codable, CardImages Codable, CardMetadata Codable, CardResponse Codable, CardsAPI Client Class (+36 more)

### Community 13 - "CSV Import/Export Service"
Cohesion: 0.13
Nodes (7): CSVService, ImportMode, merge, replace, ImportResult, ImportExportView, WatchlistItem

### Community 14 - "AI Service Errors"
Cohesion: 0.06
Nodes (27): AIServiceError, functionHandlingFailed, invalidAPIKey, invalidResponse, networkError, rateLimited, serverError, unknownError (+19 more)

### Community 15 - "MVP PRD Concepts"
Cohesion: 0.08
Nodes (29): API Swift Model Reference, Card Detail Screen TCG, CardRecord Collection Model, Collection Dashboard, Price Data TCGPlayer eBay Cache, Scan Job State Machine, Scanner Screen Continuous Scan, ScanRecord SwiftData Model (+21 more)

### Community 16 - "Grading API Models"
Cohesion: 0.07
Nodes (25): CodingKeys, imageURL, type, CodingKey, CodingKeys, backFlat, bgsRange, centering (+17 more)

### Community 17 - "Analytics Events Enum"
Cohesion: 0.07
Nodes (26): AnalyticsEvent, appOpened, cardAddedToCollection, collectionCreated, detectionCompleted, detectionFailed, detectionStarted, gradingCompleted (+18 more)

### Community 18 - "Grading Capture Steps"
Cohesion: 0.12
Nodes (14): GradingStep, backFlat, cornersBottom, cornersTop, edges, frontAngled, frontFlat, ViewfinderStyle (+6 more)

### Community 19 - "Generated Color Assets"
Cohesion: 0.16
Nodes (9): Asset, BundleToken, ColorAsset.Color, Colors, ImageAsset.Image, Images, SwiftUI.Color, SwiftUI.Image (+1 more)

### Community 20 - "Onboarding Welcome Flow"
Cohesion: 0.13
Nodes (8): position, FixedSizeScrollView, View, BlinkingDot, OnboardingHeroView, ScanLineView, ScanRingPulse, ViewModifier

### Community 21 - "Generated Fonts"
Cohesion: 0.24
Nodes (8): BundleToken, FontConvertible.Font, FontFamily, register(), registerIfNeeded(), Rubik, SwiftUI.Font, swiftUIFont()

### Community 22 - "UI Tests"
Cohesion: 0.18
Nodes (3): pokeUITests, pokeUITestsLaunchTests, XCTestCase

### Community 23 - "Scan Correction State"
Cohesion: 0.25
Nodes (6): LoadState, expired, failed, loaded, loading, ScanCorrectionViewModel

### Community 24 - "Sail Button Styles"
Cohesion: 0.25
Nodes (6): SailButton, SailButtonStyle, link, neutral, primary, secondary

### Community 25 - "Project Architecture Docs"
Cohesion: 0.25
Nodes (8): AppMain Bootstrap Entry Point, MVVM Clean Architecture Layout, Swift 6 Code Conventions, PaperScan CLAUDE.md Project Guide, TCGPlayer Scanner MVP PRD, SportScan MVP PRD, Architecture Overview Two Apps One API, Unified Card API Spec v1.0

### Community 26 - "Badge Component"
Cohesion: 0.29
Nodes (6): Badge, BadgeStyle, destructive, outline, primary, secondary

### Community 27 - "Hero Background Image"
Cohesion: 0.38
Nodes (7): Hero Background Image, Fanned Magic The Gathering Cards, Desaturated Monochrome Treatment, Magic The Gathering Card Back, PaperScan App, Purple Gradient Backdrop, TCG Collection Theme

### Community 28 - "Authentication Service"
Cohesion: 0.4
Nodes (2): AuthService, AuthServiceProtocol

### Community 29 - "Competitor Onboarding Analysis"
Cohesion: 0.4
Nodes (6): Competitor App CardDex, Competitor App CardScan Pro, Onboarding Competitive Analysis, Feature Gap Analysis PaperScan vs Competition, Competitor App Scanemon, Competitor App Snapdex

### Community 30 - "Subscription Period Helpers"
Cohesion: 0.4
Nodes (3): Package, SubscriptionPeriod, SubscriptionPeriod.Unit

### Community 31 - "Auth Store"
Cohesion: 0.5
Nodes (1): AuthStore

### Community 32 - "Sign-In Providers Enum"
Cohesion: 0.5
Nodes (3): SignInProvider, apple, google

### Community 33 - "SwiftData Preview Helper"
Cohesion: 0.5
Nodes (1): Preview

### Community 34 - "Phase 4 Roadmap Tasks"
Cohesion: 0.5
Nodes (4): CSV Export M3, Offline Behaviour M3, Push Notifications M3, Phase 4 Polish Retention Cleanup Tasks

### Community 35 - "Author Portrait Asset"
Cohesion: 0.5
Nodes (4): Asset catalog image likely used for app author/about screen, Author portrait photo (young man, outdoor greenery background), Outdoor nature setting with foliage and rocks, Man with short dark hair, beard, white t-shirt

### Community 36 - "Item Data Model"
Cohesion: 0.67
Nodes (1): Item

### Community 37 - "DI Container"
Cohesion: 0.67
Nodes (1): DIContainer

### Community 38 - "AI Tool Definition"
Cohesion: 0.67
Nodes (2): RegisterableFunction, ToolDefinition

### Community 39 - "StoreKit Review Extension"
Cohesion: 0.67
Nodes (1): SKStoreReviewController

### Community 40 - "UINavigationController Extension"
Cohesion: 0.67
Nodes (1): UINavigationController

### Community 41 - "Unit Tests"
Cohesion: 0.67
Nodes (1): pokeTests

### Community 42 - "App Constants"
Cohesion: 1.0
Nodes (1): Constants

### Community 43 - "App Theme"
Cohesion: 1.0
Nodes (1): AppTheme

### Community 44 - "User Repository Protocol"
Cohesion: 1.0
Nodes (1): UserRepositoryProtocol

### Community 45 - "SwiftUI Font Extension"
Cohesion: 1.0
Nodes (1): SwiftUI.Font

### Community 46 - "TCG Scanner Plan & Risks"
Cohesion: 1.0
Nodes (2): TCG Scanner Implementation Plan, Risk Log

### Community 47 - "Pre-Onboarding Fixes"
Cohesion: 1.0
Nodes (1): Immediate Fixes Before New Onboarding

### Community 48 - "Search API Endpoint"
Cohesion: 1.0
Nodes (1): GET /v1/search endpoint

### Community 49 - "Sets Catalog Endpoint"
Cohesion: 1.0
Nodes (1): GET /v1/catalog/sets endpoint

### Community 50 - "Offline Card Autocomplete"
Cohesion: 1.0
Nodes (1): Local Card Index Offline Autocomplete

### Community 51 - "Grading API Docs"
Cohesion: 1.0
Nodes (1): Grading API Documentation

### Community 52 - "TCG Scanner Progress Log"
Cohesion: 1.0
Nodes (1): TCG Scanner Progress Log

### Community 53 - "App Icon Container"
Cohesion: 1.0
Nodes (1): PaperScan App Icon (1024x1024)

### Community 54 - "Logo Card Illustration"
Cohesion: 1.0
Nodes (1): TCG Card Illustration

### Community 55 - "Logo Pokeball Symbol"
Cohesion: 1.0
Nodes (1): Pokeball Symbol

### Community 56 - "Logo Scan Corners"
Cohesion: 1.0
Nodes (1): Scanner Corner Brackets

### Community 57 - "Logo Purple Backdrop"
Cohesion: 1.0
Nodes (1): Purple Rounded Background

### Community 58 - "Logo TCG Text Label"
Cohesion: 1.0
Nodes (1): TCG Text Label

### Community 59 - "Shield Checkmark Icon"
Cohesion: 1.0
Nodes (1): Metallic Shield with Checkmark

### Community 60 - "Red Padlock Icon"
Cohesion: 1.0
Nodes (1): 3D Red Padlock Icon

### Community 61 - "3D Camera Icon"
Cohesion: 1.0
Nodes (1): 3D Camera Icon

### Community 62 - "AppIcon Container"
Cohesion: 1.0
Nodes (1): PaperScan App Icon

### Community 63 - "AppIcon Card Illustration"
Cohesion: 1.0
Nodes (1): TCG Card Illustration

### Community 64 - "AppIcon Scan Corners"
Cohesion: 1.0
Nodes (1): Scan Frame Corners

### Community 65 - "AppIcon Pokeball Symbol"
Cohesion: 1.0
Nodes (1): Pokeball Symbol

### Community 66 - "AppIcon Purple Backdrop"
Cohesion: 1.0
Nodes (1): Purple Rounded Background

### Community 67 - "Magic Top Hat Icon"
Cohesion: 1.0
Nodes (1): Magic Top Hat with Wand

### Community 68 - "Magic Star Wand Icon"
Cohesion: 1.0
Nodes (1): Silver Star Magic Wand

### Community 69 - "Magic Red Band Icon"
Cohesion: 1.0
Nodes (1): Red Hat Band

### Community 70 - "Google Logo Asset"
Cohesion: 1.0
Nodes (1): Google Logo Icon

### Community 71 - "Cash Stack Icon"
Cohesion: 1.0
Nodes (1): Stack of Cash with Dollar Sign

### Community 72 - "Onboarding Paywall Mockup"
Cohesion: 1.0
Nodes (1): SwiftSail Pro Paywall Mockup

### Community 73 - "Pro Features Table"
Cohesion: 1.0
Nodes (1): Free vs Pro Features Table

### Community 74 - "Reviews Rating Badge"
Cohesion: 1.0
Nodes (1): 4.7 Star Rating 200+ Reviews

### Community 75 - "Testimonial Text"
Cohesion: 1.0
Nodes (1): Streamlined Trading Journal Testimonial

### Community 76 - "Paywall CTA Button"
Cohesion: 1.0
Nodes (1): Get SwiftSail Pro CTA

### Community 77 - "Xcode Navigator Screenshot"
Cohesion: 1.0
Nodes (1): Xcode Project Navigator - SwiftSail

### Community 78 - "Features Folder Structure"
Cohesion: 1.0
Nodes (1): Features Folder (Onboarding, Analytics, Settings, Purchases, Dashboard, Auth)

### Community 79 - "Architecture Folders Layout"
Cohesion: 1.0
Nodes (1): Architecture Folders (Domain, Data, Presentation)

### Community 80 - "Core Swift Files"
Cohesion: 1.0
Nodes (1): Swift Files (AppDependencies, ContentView, AppRouter, AppDelegate, SceneDelegate, Constants)

### Community 81 - "UI Components Screenshot"
Cohesion: 1.0
Nodes (1): Onboarding Screen 2 - UI Components Showcase

### Community 82 - "Sign-In Button Samples"
Cohesion: 1.0
Nodes (1): Button Component Samples (Sign in with Apple, I agree)

### Community 83 - "Account Form Card"
Cohesion: 1.0
Nodes (1): Card Component - Create Account Form

### Community 84 - "Dashboard Tab Bar"
Cohesion: 1.0
Nodes (1): Bottom Tab Bar - Dashboard / UI Components

### Community 85 - "iPhone Device Mockup"
Cohesion: 1.0
Nodes (1): iPhone Device Frame Mockup

## Knowledge Gaps
- **397 isolated node(s):** `Constants`, `AppTheme`, `onboarding`, `settings`, `paywall` (+392 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `App Constants`** (2 nodes): `Constants`, `Constants.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Theme`** (2 nodes): `Theme.swift`, `AppTheme`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `User Repository Protocol`** (2 nodes): `UserRepositoryProtocol.swift`, `UserRepositoryProtocol`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `SwiftUI Font Extension`** (2 nodes): `SwiftUI.Font`, `FontExtension.swift`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `TCG Scanner Plan & Risks`** (2 nodes): `TCG Scanner Implementation Plan`, `Risk Log`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Pre-Onboarding Fixes`** (1 nodes): `Immediate Fixes Before New Onboarding`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Search API Endpoint`** (1 nodes): `GET /v1/search endpoint`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sets Catalog Endpoint`** (1 nodes): `GET /v1/catalog/sets endpoint`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Offline Card Autocomplete`** (1 nodes): `Local Card Index Offline Autocomplete`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Grading API Docs`** (1 nodes): `Grading API Documentation`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `TCG Scanner Progress Log`** (1 nodes): `TCG Scanner Progress Log`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `App Icon Container`** (1 nodes): `PaperScan App Icon (1024x1024)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Logo Card Illustration`** (1 nodes): `TCG Card Illustration`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Logo Pokeball Symbol`** (1 nodes): `Pokeball Symbol`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Logo Scan Corners`** (1 nodes): `Scanner Corner Brackets`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Logo Purple Backdrop`** (1 nodes): `Purple Rounded Background`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Logo TCG Text Label`** (1 nodes): `TCG Text Label`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Shield Checkmark Icon`** (1 nodes): `Metallic Shield with Checkmark`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Red Padlock Icon`** (1 nodes): `3D Red Padlock Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `3D Camera Icon`** (1 nodes): `3D Camera Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `AppIcon Container`** (1 nodes): `PaperScan App Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `AppIcon Card Illustration`** (1 nodes): `TCG Card Illustration`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `AppIcon Scan Corners`** (1 nodes): `Scan Frame Corners`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `AppIcon Pokeball Symbol`** (1 nodes): `Pokeball Symbol`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `AppIcon Purple Backdrop`** (1 nodes): `Purple Rounded Background`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Magic Top Hat Icon`** (1 nodes): `Magic Top Hat with Wand`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Magic Star Wand Icon`** (1 nodes): `Silver Star Magic Wand`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Magic Red Band Icon`** (1 nodes): `Red Hat Band`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Google Logo Asset`** (1 nodes): `Google Logo Icon`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Cash Stack Icon`** (1 nodes): `Stack of Cash with Dollar Sign`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Onboarding Paywall Mockup`** (1 nodes): `SwiftSail Pro Paywall Mockup`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Pro Features Table`** (1 nodes): `Free vs Pro Features Table`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Reviews Rating Badge`** (1 nodes): `4.7 Star Rating 200+ Reviews`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Testimonial Text`** (1 nodes): `Streamlined Trading Journal Testimonial`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Paywall CTA Button`** (1 nodes): `Get SwiftSail Pro CTA`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Xcode Navigator Screenshot`** (1 nodes): `Xcode Project Navigator - SwiftSail`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Features Folder Structure`** (1 nodes): `Features Folder (Onboarding, Analytics, Settings, Purchases, Dashboard, Auth)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Architecture Folders Layout`** (1 nodes): `Architecture Folders (Domain, Data, Presentation)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Core Swift Files`** (1 nodes): `Swift Files (AppDependencies, ContentView, AppRouter, AppDelegate, SceneDelegate, Constants)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `UI Components Screenshot`** (1 nodes): `Onboarding Screen 2 - UI Components Showcase`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Sign-In Button Samples`** (1 nodes): `Button Component Samples (Sign in with Apple, I agree)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Account Form Card`** (1 nodes): `Card Component - Create Account Form`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Dashboard Tab Bar`** (1 nodes): `Bottom Tab Bar - Dashboard / UI Components`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `iPhone Device Mockup`** (1 nodes): `iPhone Device Frame Mockup`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `CodingKeys` connect `Card Model Coding Keys` to `AI Service Layer`, `Card API Models`, `App Bootstrap & Analytics`, `Collection Sorting & Filters`, `Grading API Models`, `Onboarding Welcome Flow`?**
  _High betweenness centrality (0.102) - this node is a cross-community bridge._
- **Why does `CodingKeys` connect `OpenAI Parser & Detection` to `AI Service Layer`, `Card API Models`, `Collection Sorting & Filters`, `Grading API Models`, `Generated Color Assets`?**
  _High betweenness centrality (0.081) - this node is a cross-community bridge._
- **Why does `url` connect `AI Service Layer` to `OpenAI Parser & Detection`, `Card Detail View`, `Paywall & Subscriptions`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **Are the 45 inferred relationships involving `text` (e.g. with `.scanRow()` and `.lastGradeCard()`) actually correct?**
  _`text` has 45 INFERRED edges - model-reasoned connections that need verification._
- **What connects `Constants`, `AppTheme`, `onboarding` to the rest of the system?**
  _397 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Shared UI Components` be split into smaller, more focused modules?**
  _Cohesion score 0.02 - nodes in this community are weakly interconnected._
- **Should `AI Service Layer` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._