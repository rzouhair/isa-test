# Exam Prep Pivot — todo

Full plan: `tasks/CLEANUP_AND_FEATURES_PLAN.md`

## Phase 1 — Rebrand & Purge TCG — ✅ DONE (build passes)

### Completed
- [x] `Constants.swift` — rebrand to `CDL Prep`, `ExamPrep Pro` entitlement, cleared TCG URLs
- [x] `AnalyticsEvent.swift` — exam-prep events (quizStarted, licenseSelected, examDateSet, etc.)
- [x] `Router.swift` — small Route enum (onboarding, home, progress, settings, paywall)
- [x] `AppState.swift` — 2 tabs (home, progress); settings via sheet
- [x] `AppMain.swift` — drop TCG models; temporary `Item.self` placeholder (Phase 2 replaces)
- [x] `DIContainer.swift` — drop card/grading/AI services
- [x] `RootView.swift` — standard TabView (Home + Progress placeholder); gear + crown toolbar
- [x] `HomeView.swift` — placeholder dashboard
- [x] `OnboardingFlowView.swift` — trimmed to 5 steps (hero → value → rate-us → trial1 → trial2)
- [x] `TrialScreen1View.swift` — copy updated to exam-prep
- [x] `SettingsView` + `SettingsViewModel` — stripped watchlist/import sections
- [x] Deleted feature folders: `CameraCapture`, `Scanner`, `Collection`, `Grading`, `Watchlist`, `Detection`, `Search`
- [x] Deleted domain: `CardRecord`, `CardCollection`, `GradeRecord`, `ScanRecord`, `WatchlistItem`, `CardAPIModels`, `GradingAPIModels`, `DetectionResult`, `TCGType`, `ToolDefinition`, `OpenAIParser`, `CardIdentifierServiceProtocol`, `GradingServiceProtocol`, `AIServiceProvider`
- [x] Deleted services: `CardIdentifierService`, `GradingService`, `OpenAIService`, `OpenAIProxiedService`, `WatchlistPriceService`, `CSVService`
- [x] Deleted UI: `PriceChartView`, `HighlightTabBar`, `ImportExportView`, `AboutAuthorView`, `HomeViewModel`
- [x] Deleted onboarding step files: Correction, BulkScan, Portfolio, Grading, Watchlist, MultiGame, ExportImport, CameraPermission, Features, Components/CameraView
- [x] Cleaned `examprep.xcodeproj/project.pbxproj` via `scripts/clean_pbxproj.py` (67 file refs + 195 build refs stripped)
- [x] Added `Color(hex: Int)` overload in `OnboardingFlowView.swift` (Theme.swift used Int form)
- [x] `xcodebuild` — **BUILD SUCCEEDED**

### Known follow-ups (not Phase 1 blockers)
- App icon still shows old Poke branding — update in Phase 6 polish
- Theme palette still "animeTCG" purple — acceptable interim; user may swap in Phase 6
- `paperscan.xcodeproj` (legacy second project) still present — user can delete
- PostHog key + Sentry DSN + RevenueCat SDK key still point at Poke — user to rotate on new app submission
- `ja-JP/`, `sc/`, docs (`MVP_PRD_SPORTS.md`, `API_SWIFT_MODEL.md`, etc.), graphify snapshot, `fastlane/` metadata — all TCG-era artifacts user can prune later
- `Preview.swift` in `Domain/Models/` kept as generic SwiftData preview helper

---

## Phase 2 — Data Foundation — NEXT

See `tasks/CLEANUP_AND_FEATURES_PLAN.md` §Phase 2 for full detail.

- [ ] Add GRDB.swift SPM dependency
- [ ] Create `GRDBContentDatabase.swift`
- [ ] Create SwiftData user-progress models: `UserExamProfile`, `QuestionAttempt`, `PracticeSession`, `SessionAnswer`, `BookmarkedQuestion`, `StudyStreak`
- [ ] Register new models in `AppMain.swift` (replace `Item.self`); delete `Item.swift`
- [ ] Create DTOs in `Domain/Models/Content/`
- [ ] Create `ContentRepository`, `UserProgressRepository`, `StatsRepository`
- [ ] Create `tools/seed/` scripts + sample CSVs
- [ ] Ship tiny sample SQLite (CA / Car / GK — 20 questions) for smoke test
- [ ] Unit tests for each repository
- [ ] Wire repositories into `DIContainer`

---

## Phases 3–6 — See CLEANUP_AND_FEATURES_PLAN.md
