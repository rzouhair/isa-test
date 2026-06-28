# Codebase Cleansing Plan — Poke → Generic Boilerplate

**Goal**: Strip all ISA exam-specific features, leaving only core boilerplate (paywall, onboarding skeleton, auth, analytics, crash reporting, DI, router, generic UI components) ready for another app implementation.

---

## Phase 1: Remove ISA Exam Feature Modules

- [x] Delete `Features/Home/`
- [x] Delete `Features/QuizSession/`
- [x] Delete `Features/QuizResult/`
- [x] Delete `Features/ReviewSession/`
- [x] Delete `Features/PracticeTestList/`
- [x] Delete `Features/CategoryList/`
- [x] Delete `Features/Flashcards/`
- [x] Delete `Features/LearnMode/`
- [x] Delete `Features/Stats/`
- [x] Delete `Features/Bookmarks/`
- [x] Delete `Features/WeakQuestions/`
- [x] Delete `Features/AITutor/`
- [x] Delete `Features/ExamDatePicker/`

## Phase 2: Remove Exam-Specific Data Layer

- [x] Delete `Data/DB/GRDBContentDatabase.swift`
- [x] Delete `Data/Repositories/GRDBContentRepository.swift`
- [x] Delete `Data/Repositories/SwiftDataUserProgressRepository.swift`
- [x] Delete `Data/Repositories/DefaultStatsRepository.swift`
- [x] Delete `Data/Services/DemoDataSeeder.swift`
- [x] Delete `Domain/Models/Content/ContentDTOs.swift`
- [x] Delete `Domain/Models/Content/` (empty dir)
- [x] Delete `Domain/Models/QuestionAttempt.swift`
- [x] Delete `Domain/Models/PracticeSession.swift`
- [x] Delete `Domain/Models/SessionAnswer.swift`
- [x] Delete `Domain/Models/BookmarkedQuestion.swift`
- [x] Delete `Domain/Models/BookmarkedFlashcard.swift`
- [x] Delete `Domain/Models/FlashcardReview.swift`
- [x] Delete `Domain/Models/StudyStreak.swift`
- [x] Delete `Domain/Models/UserExamProfile.swift`
- [x] Delete `Domain/Protocols/ContentRepositoryProtocol.swift`
- [x] Delete `Domain/Protocols/UserProgressRepositoryProtocol.swift`
- [x] Delete `Domain/Protocols/StatsRepositoryProtocol.swift`

## Phase 3: Clean OnboardingFlow (keep skeleton + TrialClose)

- [x] Delete `OnboardingExamDateStepView.swift`
- [x] Delete `OnboardingValueProp1View.swift`
- [x] Delete `OnboardingValueProp2View.swift`
- [x] Rewrite `OnboardingFlowView.swift` — remove ISA step references, add generic placeholder steps
- [x] Keep `OnboardingNotificationsStepView.swift` (generic) — fixed `ExamReminderScheduler` dangling ref → direct `UNUserNotificationCenter`
- [x] Keep `OnboardingRateUsView.swift` (generic)
- [x] Keep `TrialClose/` entire folder (trial-to-paid pattern)
- [x] Create `OnboardingPlaceholderStepView.swift` — reusable value prop step with configurable title/subtitle/icon
- [x] Update `OnboardingHeroView.swift` — generic placeholder copy

## Phase 4: Remove ISA-Specific UI Components

- [x] Delete `Presentation/Components/AnswerOptionButton.swift`
- [x] Delete `Presentation/Components/QuestionCardView.swift`
- [x] Delete `Presentation/Components/CategoryProgressCard.swift`
- [x] Delete `Presentation/Components/CategoryProgressRow.swift`
- [x] Delete `Presentation/Components/ExamCountdownPill.swift`
- [x] Delete `Presentation/Components/ProgressRingView.swift`
- [x] Delete `Presentation/Components/ScoreGaugeView.swift`
- [x] Delete `Presentation/Components/ReadinessDonutWithLegend.swift`
- [ ] Delete `Presentation/Components/FeaturesList.swift` — KEPT: still used by PaywallView.swift (defer to Phase 5)
- [x] Delete `Presentation/Components/LearningPathView.swift`

## Phase 5: Wire-up & Bootstrap Cleanup

- [ ] Clean `AppMain.swift` — remove exam models from ModelContainer, remove DemoDataSeeder
- [ ] Clean `RootView.swift` — remove deleted feature destinations, wire placeholder Home
- [ ] Clean `Router.swift` — remove deleted route cases, remove QuizConfig/FlashcardDeckConfig
- [ ] Clean `DIContainer.swift` — remove contentRepository, statsRepository, userProgressRepository
- [ ] Clean `Constants.swift` — strip ISA-specific strings, keep service keys
- [ ] Clean `AnalyticsEvent.swift` — strip exam events, keep generic app events
- [ ] Clean `UserRepository.swift` — remove ISA-specific UserDefaults keys
- [ ] Clean `SettingsView.swift` + `SettingsViewModel.swift` — remove ISA-specific settings
- [ ] Clean `ReviewPromptService.swift` — verify no ISA references
- [ ] Check `Domain/Models/Preview.swift` — remove if exam-only

## Phase 6: Cross-Reference & Build Verification

- [ ] Grep remaining codebase for references to deleted files/types
- [ ] Fix any dangling imports or broken references
- [ ] Verify Xcode build compiles (or `swift build` / static analysis)
- [ ] Run `graphify update .` to refresh knowledge graph

---

## What Stays Intact

- RevenueCat / Purchases (full paywall flow)
- Authentication (AuthService, AuthStore, Apple/Google sign-in)
- Onboarding skeleton + TrialClose pattern
- Settings shell
- DI container (trimmed)
- Router (trimmed)
- Analytics (PostHog) + Crash reporting (Sentry)
- SwiftData + UserDefaults datasources
- Generic UI components (Badge, Banner, Button, Card, Checkbox, etc.)
- Theme, Constants (service keys), AppDelegate
- External dirs (docs, ASO, fastlane, scripts, tools) — untouched
