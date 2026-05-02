# Exam Prep Pivot — Cleanup & Feature Plan

## Context

Codebase currently ships as Poke — TCG card scanner (scan, grade, collect, watchlist). Pivoting to unified **DMV + CDL exam-prep app**. Single codebase, middleground schema covers both license types (Car, Motorcycle, CDL + CDL endorsements), bundled SQLite content DB, SwiftData for user progress. Keep working boilerplate (onboarding shell, paywall, router, DI, analytics, crash reporting, Swift 6 + SwiftUI + MVVM). Rip TCG features. Rebuild domain around license → state → category → question.

Best features distilled from DMV + CDL reference apps in screenshots:
- License type selector (Car / Motorcycle / CDL) + state selector (50 states)
- Category/endorsement selector (General Knowledge, Road Signs, Hazmat, School Bus, Passenger, Pre-Trip, Air Brakes…)
- Numbered practice tests (#1, #2, … w/ `failed`/`continue`/`start` status)
- Realistic exam simulator (timed, pass/fail gauge, time breakdown, review-all)
- Learn mode w/ level progression (Level 1…N) and Learning / Reviewing / Weak buckets
- Instant explanation per question ("why wrong") + image/diagram support
- Cheat sheets (road signs, top-N common Qs, motorcycle, hazmat, things-to-do-before-exam)
- Official handbook (state-specific, offline)
- Progress dashboard: average score per category, exam-date countdown (days/hours/min/sec), passing probability
- Bookmark / flag question, weak-questions mode ("strengthen skills")
- Optional AI tutor chat (reuses existing OpenAI infra as optional paid feature)
- Multi-language at content level (EN default, ES/ZH later)

---

## Phase 1 — Rebrand & Purge TCG (day 1)

### Goal
Strip all TCG domain code. Boot empty-shell app with working paywall, analytics, DI, onboarding skeleton, blank Home. No compile errors.

### Step-by-step

**1.1 Rebrand (`examprep/Constants.swift`)**
Edit these constant values:
```swift
static let appName = "CDL Prep"                               // was "Karten" / "Poke"
static let revenueCatProEntitlement = "ExamPrep Pro"          // rename entitlement in RevenueCat dashboard too
static let supportEmail = "<user email>"
static let privacyPolicyUrl = "<new URL>"
static let termsOfUseUrl = "<keep Apple EULA or replace>"
static let appStoreId = "<new ID or placeholder>"
static let posthogAPIKey = "<new key>"
static let sentryDSN = "<new DSN>"
// REMOVE: cardIdentifierBaseURL, instagram/twitter/twitch (or replace)
```
Update asset catalog `Colors.xcassets` accent color; replace `AppIcon` set; add new logo PNGs to `Presentation/Resources/`. Run `swiftgen` after asset changes.

**1.2 Delete feature folders** (Finder + Xcode: remove references, move-to-trash)
```
examprep/Features/CameraCapture/
examprep/Features/Scanner/
examprep/Features/Collection/
examprep/Features/Grading/
examprep/Features/Watchlist/
examprep/Features/Detection/
examprep/Features/Search/
```

**1.3 Delete domain/data files**
```
examprep/Domain/Models/CardRecord.swift
examprep/Domain/Models/CardCollection.swift
examprep/Domain/Models/GradeRecord.swift
examprep/Domain/Models/ScanRecord.swift
examprep/Domain/Models/WatchlistItem.swift
examprep/Domain/Models/CardAPIModels.swift
examprep/Domain/Models/GradingAPIModels.swift
examprep/Domain/Models/DetectionResult.swift
examprep/Domain/Enums/TCGType.swift
examprep/Data/Services/CardIdentifierService.swift
examprep/Data/Services/GradingService.swift
examprep/Data/Services/OpenAIProxiedService.swift
examprep/Data/Services/WatchlistPriceService.swift
examprep/Domain/Protocols/CardIdentifierServiceProtocol.swift
examprep/Domain/Protocols/GradingServiceProtocol.swift
examprep/Presentation/Components/PriceChartView.swift
```
Keep `OpenAIService.swift` but delete its `functionRegistry` property (unused).

**1.4 Rewrite `examprep/Core/Navigation/Router.swift`**
Replace entire `Route` enum with placeholder. Remove all imports of deleted types:
```swift
enum Route: Hashable {
    case onboarding
    case home
    case settings
    case paywall
    // Phase 3 will add: licensePicker, statePicker, categoryList(…), practiceTestList(…), quizSession(…), quizResult(…), reviewSession(…)
}

@MainActor
@Observable
final class Router {
    var path: [Route] = []
    func push(_ r: Route) { path.append(r) }
    func pop() { _ = path.popLast() }
    func popToRoot() { path.removeAll() }
}
```
Fix `RouterView` / `navigationDestination(for:)` switch to cover only remaining cases.

**1.5 Refactor `examprep/Application/AppMain.swift`**
- Remove from `ModelContainer(for:)`: `ScanRecord.self, CardRecord.self, CardCollection.self, WatchlistItem.self, GradeRecord.self`
- Replace with placeholder (will add real models in Phase 2): `ModelContainer(for: Item.self)` (temporary — keep existing `Item.swift` as placeholder)
- Delete `WatchlistPriceService` injection + its `.task { await WatchlistPriceService.shared.checkOnAppOpen() }` calls
- Keep RevenueCat `Purchases.configure`, PostHog init, Sentry init

**1.6 Refactor `examprep/Application/AppState.swift`**
Replace `SelectedTab` enum:
```swift
enum SelectedTab: Hashable { case home, practice, progress, settings }
```
Keep `isProUser`, `wasPaywallShown`, `showPaywall()`.

**1.7 Refactor `examprep/Application/RootView.swift`**
Replace TabView contents with 4 placeholder tabs:
```swift
TabView(selection: $appState.selectedTab) {
    HomeView().tag(SelectedTab.home)
    Text("Practice").tag(SelectedTab.practice)         // Phase 3
    Text("Progress").tag(SelectedTab.progress)         // Phase 4
    SettingsView().tag(SelectedTab.settings)
}
```
Keep `HighlightTabBar` if used; update its tab items.

**1.8 Refactor `examprep/Core/DI/DIContainer.swift`**
- Delete registrations for: `cardIdentifierService`, `gradingService`, any card/TCG service
- Keep: `userRepository`, `analyticsService`, `crashReportingService`, `subscriptionsRepository`, `authService`
- Resolve compile errors in callers

**1.9 Refactor `examprep/Domain/Enums/AnalyticsEvent.swift`**
Replace all TCG-related cases. New enum:
```swift
enum AnalyticsEvent: String {
    case onboardingStarted, onboardingStepCompleted, onboardingFinished
    case licenseSelected, stateSelected, examDateSet
    case quizStarted, questionAnswered, quizCompleted
    case examSimulatorStarted, examSimulatorCompleted
    case learnSessionStarted, weakQuestionMastered
    case cheatSheetViewed, handbookOpened
    case paywallShown, purchaseStarted, purchaseCompleted, purchaseRestored
    case settingsOpened
}
```
Fix all call sites (grep for removed cases).

**1.10 Refactor `examprep/Features/OnboardingFlow/`**
Delete files:
```
OnboardingCorrectionView.swift
OnboardingBulkScanView.swift
OnboardingPortfolioView.swift
OnboardingGradingView.swift
OnboardingWatchlistView.swift
OnboardingMultiGameView.swift
OnboardingCameraPermissionView.swift
OnboardingExportImportView.swift   (delete now, add back later if needed)
```
In `OnboardingFlowView.swift`, strip step list to:
```swift
WelcomeView → InstantValueView → RateUsView → TrialScreen1View → TrialScreen2View
```
Leave Phase 6 additions (license/state/exam-date/notif) as TODO comments.

**1.11 Refactor `examprep/Features/Home/HomeView.swift`**
Blank dashboard placeholder:
```swift
VStack { Text("Home"); Text("Coming soon") }
```
Delete ViewModel card/scan logic. Phase 3 fills this in.

**1.12 Delete graphify stale nodes**
Run `graphify update .` after cleanup to refresh the knowledge graph.

### Verify
- `⌘B` in Xcode → zero errors, zero warnings for deleted types
- Run on simulator → app launches to onboarding or home (no crash)
- Walk through trimmed onboarding flow to paywall
- Hit paywall, close it, confirm analytics events fire in PostHog debug console
- Commit: `chore: purge TCG modules, rebrand shell`

---

## Phase 2 — Data Foundation (day 2)

### Goal
Ship bundled read-only SQLite of questions/cheat-sheets/handbooks via GRDB. Set up SwiftData user-progress models. Wire repositories via DI. Seed sample data to verify round-trip.

### Step-by-step

**2.1 Add GRDB dependency**
Xcode → File → Add Package Dependencies → `https://github.com/groue/GRDB.swift` → "Up to Next Major" 6.x → add `GRDB` product to app target.

**2.2 Add SQLite content DB (bundled, read-only)**
- DB file: `examprep/Resources/exam_content.sqlite` (shipped in app bundle, copied to Caches on first launch for future updates)

**2.2 Schema — unified DMV + CDL**

```sql
-- Reference tables
CREATE TABLE licenses (
  id INTEGER PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,   -- 'car' | 'motorcycle' | 'cdl'
  name TEXT NOT NULL,
  icon TEXT
);

CREATE TABLE states (
  id INTEGER PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,   -- 'CA', 'TX', …
  name TEXT NOT NULL
);

CREATE TABLE categories (
  id INTEGER PRIMARY KEY,
  license_id INTEGER NOT NULL REFERENCES licenses(id),
  code TEXT NOT NULL,          -- 'general_knowledge', 'hazmat', 'road_signs', 'pre_trip'…
  name TEXT NOT NULL,
  kind TEXT NOT NULL,          -- 'core' | 'endorsement'
  sort_order INTEGER DEFAULT 0,
  UNIQUE(license_id, code)
);

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  license_id INTEGER NOT NULL REFERENCES licenses(id),
  category_id INTEGER NOT NULL REFERENCES categories(id),
  state_id INTEGER REFERENCES states(id),        -- NULL = federal/common
  text TEXT NOT NULL,
  explanation TEXT,                              -- shown after answer
  image_name TEXT,                               -- asset catalog key, optional
  difficulty INTEGER DEFAULT 1,                  -- 1–3
  lang TEXT NOT NULL DEFAULT 'en'                -- 'en' | 'es' | 'zh'
);
CREATE INDEX idx_q_lookup ON questions(license_id, category_id, state_id, lang);

CREATE TABLE answers (
  id INTEGER PRIMARY KEY,
  question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  is_correct INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER DEFAULT 0
);
CREATE INDEX idx_a_q ON answers(question_id);

CREATE TABLE cheat_sheets (
  id INTEGER PRIMARY KEY,
  license_id INTEGER NOT NULL REFERENCES licenses(id),
  state_id INTEGER REFERENCES states(id),
  title TEXT NOT NULL,
  body_md TEXT NOT NULL,
  cover_image TEXT,
  lang TEXT NOT NULL DEFAULT 'en'
);

CREATE TABLE handbooks (
  id INTEGER PRIMARY KEY,
  state_id INTEGER NOT NULL REFERENCES states(id),
  license_id INTEGER NOT NULL REFERENCES licenses(id),
  title TEXT NOT NULL,
  pdf_name TEXT,                                 -- bundle filename
  body_md TEXT,                                  -- fallback text
  version TEXT,
  lang TEXT NOT NULL DEFAULT 'en',
  UNIQUE(state_id, license_id, lang)
);

CREATE TABLE exam_specs (                        -- defines realistic exam simulators per state+license
  id INTEGER PRIMARY KEY,
  state_id INTEGER NOT NULL REFERENCES states(id),
  license_id INTEGER NOT NULL REFERENCES licenses(id),
  category_id INTEGER REFERENCES categories(id), -- NULL = mixed
  question_count INTEGER NOT NULL,
  pass_threshold REAL NOT NULL,                  -- 0.80 = 80%
  time_limit_sec INTEGER,                        -- NULL = untimed
  UNIQUE(state_id, license_id, category_id)
);
```

**2.3 SwiftData models** `examprep/Domain/Models/`

`UserExamProfile.swift`:
```swift
@Model final class UserExamProfile {
    var licenseCode: String          // 'car' | 'motorcycle' | 'cdl'
    var stateCode: String            // 'CA'
    var examDate: Date?
    var dailyGoalQuestions: Int = 20
    var preferredLang: String = "en"
    var createdAt: Date = Date()
    init(licenseCode: String, stateCode: String) {
        self.licenseCode = licenseCode; self.stateCode = stateCode
    }
}
```

`QuestionAttempt.swift`:
```swift
enum QuestionStatus: String, Codable { case new, learning, reviewing, weak, mastered }

@Model final class QuestionAttempt {
    @Attribute(.unique) var questionId: Int      // FK → SQLite questions.id
    var attemptCount: Int = 0
    var correctCount: Int = 0
    var lastAttemptedAt: Date?
    var lastCorrect: Bool = false
    var status: QuestionStatus = .new
    init(questionId: Int) { self.questionId = questionId }
}
```

`PracticeSession.swift`:
```swift
enum SessionKind: String, Codable { case practice, simulator, learn, weak, bookmark }

@Model final class PracticeSession {
    @Attribute(.unique) var id: UUID = UUID()
    var kind: SessionKind
    var licenseCode: String
    var stateCode: String
    var categoryCode: String?
    var startedAt: Date = Date()
    var endedAt: Date?
    var score: Double = 0              // 0.0 – 1.0
    var passThreshold: Double = 0.8
    var questionIdsJSON: Data          // [Int] JSON-encoded
    var timeLimitSec: Int?
    @Relationship(deleteRule: .cascade, inverse: \SessionAnswer.session)
    var answers: [SessionAnswer] = []
    init(kind: SessionKind, licenseCode: String, stateCode: String, questionIds: [Int]) {
        self.kind = kind; self.licenseCode = licenseCode; self.stateCode = stateCode
        self.questionIdsJSON = (try? JSONEncoder().encode(questionIds)) ?? Data()
    }
}
```

`SessionAnswer.swift`:
```swift
@Model final class SessionAnswer {
    var questionId: Int
    var selectedAnswerId: Int?
    var correct: Bool = false
    var timeMs: Int = 0
    var answeredAt: Date = Date()
    var session: PracticeSession?
    init(questionId: Int) { self.questionId = questionId }
}
```

`BookmarkedQuestion.swift`:
```swift
@Model final class BookmarkedQuestion {
    @Attribute(.unique) var questionId: Int
    var savedAt: Date = Date()
    init(questionId: Int) { self.questionId = questionId }
}
```

`StudyStreak.swift`:
```swift
@Model final class StudyStreak {
    @Attribute(.unique) var date: Date    // day-truncated
    var minutesStudied: Int = 0
    var questionsAnswered: Int = 0
    init(date: Date) { self.date = date }
}
```

Register all in `AppMain.swift`:
```swift
ModelContainer(for:
    UserExamProfile.self, QuestionAttempt.self, PracticeSession.self,
    SessionAnswer.self, BookmarkedQuestion.self, StudyStreak.self)
```
Delete `Item.swift` placeholder.

**2.4 GRDB content layer** `examprep/Data/DB/`

`GRDBContentDatabase.swift`:
```swift
import GRDB

final class GRDBContentDatabase {
    static let shared = GRDBContentDatabase()
    let queue: DatabaseQueue

    private init() {
        let fm = FileManager.default
        let cachesURL = try! fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dst = cachesURL.appendingPathComponent("exam_content.sqlite")
        if !fm.fileExists(atPath: dst.path) {
            let src = Bundle.main.url(forResource: "exam_content", withExtension: "sqlite")!
            try? fm.copyItem(at: src, to: dst)
        }
        var cfg = Configuration()
        cfg.readonly = true
        self.queue = try! DatabaseQueue(path: dst.path, configuration: cfg)
    }
}
```

**2.5 DTOs** `examprep/Domain/Models/Content/`

```swift
struct LicenseDTO: Codable, FetchableRecord { let id: Int; let code: String; let name: String; let icon: String? }
struct StateDTO: Codable, FetchableRecord { let id: Int; let code: String; let name: String }
struct CategoryDTO: Codable, FetchableRecord {
    let id: Int; let licenseId: Int; let code: String; let name: String; let kind: String; let sortOrder: Int
}
struct QuestionDTO: Codable, FetchableRecord {
    let id: Int; let licenseId: Int; let categoryId: Int; let stateId: Int?
    let text: String; let explanation: String?; let imageName: String?; let difficulty: Int; let lang: String
}
struct AnswerDTO: Codable, FetchableRecord {
    let id: Int; let questionId: Int; let text: String; let isCorrect: Int; let sortOrder: Int
}
struct CheatSheetDTO: Codable, FetchableRecord {
    let id: Int; let licenseId: Int; let stateId: Int?; let title: String; let bodyMd: String
    let coverImage: String?; let lang: String
}
struct HandbookDTO: Codable, FetchableRecord {
    let id: Int; let stateId: Int; let licenseId: Int; let title: String
    let pdfName: String?; let bodyMd: String?; let version: String?; let lang: String
}
struct ExamSpecDTO: Codable, FetchableRecord {
    let id: Int; let stateId: Int; let licenseId: Int; let categoryId: Int?
    let questionCount: Int; let passThreshold: Double; let timeLimitSec: Int?
}
```

**2.6 Repositories** `examprep/Data/Repositories/`

`ContentRepository.swift` — protocol + GRDB impl, all read-only:
```swift
protocol ContentRepositoryProtocol {
    func allLicenses() throws -> [LicenseDTO]
    func allStates() throws -> [StateDTO]
    func categories(licenseCode: String) throws -> [CategoryDTO]
    func questions(licenseCode: String, stateCode: String, categoryCode: String?, lang: String, limit: Int?) throws -> [(QuestionDTO, [AnswerDTO])]
    func question(id: Int) throws -> (QuestionDTO, [AnswerDTO])?
    func cheatSheets(licenseCode: String, stateCode: String?, lang: String) throws -> [CheatSheetDTO]
    func handbook(licenseCode: String, stateCode: String, lang: String) throws -> HandbookDTO?
    func examSpec(licenseCode: String, stateCode: String, categoryCode: String?) throws -> ExamSpecDTO?
}
```
Implement each via `GRDBContentDatabase.shared.queue.read { db in … }` with `QuestionDTO.fetchAll(db, sql: ..., arguments: ...)`.

`UserProgressRepository.swift` — SwiftData CRUD:
```swift
protocol UserProgressRepositoryProtocol {
    func profile() -> UserExamProfile?
    func setProfile(license: String, state: String, examDate: Date?) throws
    func attempt(for questionId: Int) -> QuestionAttempt?
    func recordAnswer(questionId: Int, correct: Bool, timeMs: Int) throws  // upsert + status transition
    func createSession(_ s: PracticeSession) throws
    func completeSession(id: UUID, score: Double) throws
    func toggleBookmark(questionId: Int) throws
    func bookmarks() -> [Int]
    func incrementStreak(minutes: Int, questions: Int) throws
}
```
Status transition rule in `recordAnswer`:
- `new` + correct → `mastered`; + wrong → `learning`
- `learning` + correct → `reviewing`; + wrong → stays `learning`
- `reviewing` + correct → `mastered`; + wrong → `weak`
- `weak` + correct → `reviewing`; + wrong → stays `weak`
- `mastered` + wrong → `reviewing`

`StatsRepository.swift`:
```swift
struct CategoryStats { let code: String; let name: String; let avgScore: Double; let attempts: Int; let lastAt: Date? }

protocol StatsRepositoryProtocol {
    func categoryStats(licenseCode: String, stateCode: String) -> [CategoryStats]
    func passingProbability(licenseCode: String, stateCode: String) -> Double
    func weakQuestionIds(limit: Int) -> [Int]
    func examCountdown() -> TimeInterval?     // seconds to examDate
    func currentStreak() -> Int                // consecutive days w/ activity
}
```

**2.7 Register in DI** `examprep/Core/DI/DIContainer.swift`
```swift
register(ContentRepositoryProtocol.self) { GRDBContentRepository() }
register(UserProgressRepositoryProtocol.self) { SwiftDataUserProgressRepository(context: modelContext) }
register(StatsRepositoryProtocol.self) { DefaultStatsRepository(content: resolve(), progress: resolve()) }
```

**2.8 Seed tooling** `tools/seed/`

`schema.sql` — the DDL block from the main schema section above.
`seed.py`:
```python
# Reads licenses.csv, states.csv, categories.csv, questions.csv, answers.csv,
#   cheat_sheets.csv, handbooks.csv, exam_specs.csv  →  writes exam_content.sqlite
# Usage: python tools/seed/seed.py --out examprep/Resources/exam_content.sqlite
```
CSV format (users fill these):
- `questions.csv`: `license_code,state_code,category_code,text,explanation,image_name,difficulty,lang`
- `answers.csv`: `question_external_id,text,is_correct,sort_order`  (groups by external_id)
- etc.

`tools/seed/README.md` documents CSV schema and invocation.

Ship a tiny sample: CA + Car + "General Knowledge" + 20 questions, plus CDL + CA + "Hazmat" + 10 questions, so Phase 3 demo works.

**2.9 Unit tests** `examprepTests/Data/`
- `ContentRepositoryTests.swift` — load test fixture DB, assert `questions(licenseCode: "car", stateCode: "CA", …)` returns 20 rows
- `UserProgressRepositoryTests.swift` — in-memory SwiftData container, assert status transitions, bookmark toggle, streak increment
- `StatsRepositoryTests.swift` — seed attempts, assert per-category averages + weak-Q list ordering

### Verify
- `⌘U` → all data tests pass
- Breakpoint in AppMain: inspect that `exam_content.sqlite` copies to Caches on first launch
- Commit: `feat(data): SQLite content DB + SwiftData progress models`

---

## Phase 3 — Core Loop: Practice Test (days 3–4)

### Goal
User picks license → state → category → takes numbered practice test → answers w/ instant explanation → sees score gauge → reviews. Thin vertical slice through whole stack.

### Step-by-step

**3.1 Extend Route enum** `examprep/Core/Navigation/Router.swift`
```swift
enum Route: Hashable {
    case onboarding, home, settings, paywall
    case licensePicker, statePicker
    case categoryList
    case practiceTestList(categoryCode: String)
    case quizSession(config: QuizConfig)
    case quizResult(sessionId: UUID)
    case reviewSession(sessionId: UUID)
}

struct QuizConfig: Hashable {
    let kind: SessionKind
    let licenseCode: String
    let stateCode: String
    let categoryCode: String?
    let questionIds: [Int]
    let passThreshold: Double
    let timeLimitSec: Int?
}
```
Update `navigationDestination(for: Route.self)` switch to route each case to its View.

**3.2 Feature: License select** `examprep/Features/LicenseSelect/`

`LicenseSelectView.swift`:
```swift
struct LicenseSelectView: View {
    @State var vm = LicenseSelectViewModel()
    @Environment(Router.self) var router
    var body: some View {
        VStack(spacing: 16) {
            Text("Which vehicle will you drive?").font(.title).bold()
            ForEach(vm.licenses, id: \.id) { lic in
                LicenseButton(icon: lic.icon, title: lic.name) {
                    vm.select(lic)
                    router.push(.statePicker)
                }
            }
        }.task { vm.load() }
    }
}
```
`LicenseSelectViewModel.swift` (@Observable): loads `contentRepo.allLicenses()`, persists pick via `userProgressRepo.setProfile(...)`.

**3.3 Feature: State select** `examprep/Features/StateSelect/`

`StateSelectView.swift`:
```swift
struct StateSelectView: View {
    @State var vm = StateSelectViewModel()
    @Environment(Router.self) var router
    var body: some View {
        List {
            ForEach(vm.filtered, id: \.id) { state in
                Button(state.name) {
                    vm.select(state)
                    router.popToRoot()
                    // AppState.selectedTab = .home
                }
            }
        }.searchable(text: $vm.query)
    }
}
```
ViewModel filters `contentRepo.allStates()` by query.

**3.4 Feature: Home dashboard** `examprep/Features/Home/`

`HomeView.swift` sections (mirrors CDL app reference):
```swift
ScrollView {
    CountdownCard(timeInterval: vm.countdown, date: vm.examDate)   // "Exam in Jan 22 — 8 days left"
    ProbabilityRing(value: vm.passingProbability)                   // big % ring
    ForEach(vm.categoryStats, id: \.code) { stat in
        CategoryProgressRow(name: stat.name, avgScore: stat.avgScore, attempts: stat.attempts)
    }
    CTAButton("Start Practice Test") { router.push(.categoryList) }
}
```
`HomeViewModel.swift`: depends on `StatsRepositoryProtocol`, `UserProgressRepositoryProtocol`. Computed: `countdown`, `passingProbability`, `categoryStats`.

**3.5 Feature: Category list** `examprep/Features/CategoryList/`

`CategoryListView.swift`:
```swift
LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
    ForEach(vm.categories, id: \.code) { cat in
        CategoryCard(
            title: cat.name,
            progress: vm.progressFor(cat.code),
            locked: cat.kind == "endorsement" && !appState.isProUser
        ) {
            if locked { appState.showPaywall() }
            else { router.push(.practiceTestList(categoryCode: cat.code)) }
        }
    }
}
```
ViewModel loads `contentRepo.categories(licenseCode:)` + joins progress from `StatsRepository`.

**3.6 Feature: Practice test list** `examprep/Features/PracticeTestList/`

Numbered tests (#1, #2, …). Algorithm: split available questions for category into groups of N (default 20 or `exam_specs.question_count`). Status per group:
- `✓ passed` (most-recent session passed)
- `continue` (in-progress session)
- `failed` (last attempt failed)
- `start` (never attempted)
- `locked` (prior test not yet passed — enforce sequential)

`PracticeTestListView.swift`:
```swift
LazyVGrid(columns: [.init(.adaptive(minimum: 80))]) {
    ForEach(vm.tests) { test in
        TestTile(number: test.number, status: test.status) { vm.tap(test, router: router) }
    }
}
```
On tap w/ `start` / `failed` / `continue`, router pushes `.quizSession(config:)` w/ `questionIds` for that batch.

**3.7 Feature: Quiz session** `examprep/Features/QuizSession/`

`QuizSessionViewModel.swift` (@Observable):
```swift
@Observable
final class QuizSessionViewModel {
    let config: QuizConfig
    var questions: [(QuestionDTO, [AnswerDTO])] = []
    var currentIndex: Int = 0
    var selectedAnswerId: Int?
    var revealed: Bool = false
    var startedAt: Date = Date()
    var questionStartedAt: Date = Date()
    var sessionId: UUID = UUID()
    var bookmarkedIds: Set<Int> = []
    var elapsed: TimeInterval = 0           // timer tick via .task
    var results: [(questionId: Int, correct: Bool, timeMs: Int)] = []

    private let content: ContentRepositoryProtocol
    private let progress: UserProgressRepositoryProtocol
    private let analytics: AnalyticsServiceProtocol

    init(config: QuizConfig, content: ContentRepositoryProtocol,
         progress: UserProgressRepositoryProtocol, analytics: AnalyticsServiceProtocol) { … }

    func load() async { /* fetch questions, persist PracticeSession stub */ }
    func select(_ answerId: Int) { selectedAnswerId = answerId; revealed = true; record() }
    func next() {
        if currentIndex + 1 < questions.count { currentIndex += 1; reset() }
        else { finish() }
    }
    func toggleBookmark() { /* progress.toggleBookmark(...) */ }
    private func record() { /* append to results, progress.recordAnswer(...) */ }
    private func finish() {
        let score = Double(results.filter(\.correct).count) / Double(results.count)
        try? progress.completeSession(id: sessionId, score: score)
        analytics.track(.quizCompleted, props: ["score": score])
    }
}
```

`QuizSessionView.swift`:
```swift
VStack {
    QuizHeader(progress: vm.currentIndex, total: vm.questions.count,
               elapsed: vm.elapsed, onBookmark: { vm.toggleBookmark() },
               onClose: { router.pop() })
    QuestionCard(question: vm.currentQ, imageName: vm.currentImage)
    ForEach(vm.currentAnswers, id: \.id) { ans in
        AnswerOptionButton(
            text: ans.text,
            state: vm.buttonState(for: ans),      // .idle/.selected/.correct/.wrong/.disabled
            action: { vm.select(ans.id) }
        )
    }
    if vm.revealed {
        ExplanationCard(text: vm.currentQ.explanation ?? "")
        PrimaryButton("Next") { vm.next() }
    }
}
.task { await vm.load() }
.onDisappear { /* save partial session */ }
```

**3.8 Feature: Quiz result** `examprep/Features/QuizResult/`

`QuizResultView.swift` mirrors DMV Permit Prep reference:
```swift
VStack(spacing: 24) {
    ScoreGauge(score: vm.scorePercent, passed: vm.passed)           // "100%" big gauge
    HStack {
        StatTile("Correct", "\(vm.correctCount)")
        StatTile("Answered", "\(vm.answeredCount)")
        StatTile("Time", vm.totalTimeString)                         // "9m 20s"
    }
    TimeBreakdown(avgPerQuestion: vm.avgPerQuestion, total: vm.totalTime)
    VStack(spacing: 12) {
        PrimaryButton("Review All Questions") { router.push(.reviewSession(sessionId: vm.sessionId)) }
        SecondaryButton("Try Again") { router.replaceTop(with: .quizSession(config: vm.retryConfig)) }
        TertiaryButton("Next Practice Test") { vm.goToNext(router: router) }
    }
}
```

**3.9 Feature: Review session** `examprep/Features/ReviewSession/`
List of answered questions w/ correct/wrong badge, tap to expand → show explanation + which option user chose vs correct option.

**3.10 New shared components** `examprep/Presentation/Components/`

- `QuestionCardView.swift` — text + optional `Image(vm.imageName)`
- `AnswerOptionButton.swift` — enum-driven state: `idle | selected | correct | incorrect | disabled`. Colors: green BG on correct, red on incorrect, subtle border on idle
- `ScoreGaugeView.swift` — SwiftUI `Canvas` or `Shape` arc, 0–100 animated
- `ProgressRingView.swift` — ring shape w/ percent label
- `CountdownView.swift` — four stat tiles (days / hrs / min / sec), updates via `Timer.publish`
- `CategoryProgressRow.swift` — icon + name + bar + avg score
- `LicenseButton.swift` — large rounded button w/ icon + title + chevron

**3.11 Tests** `examprepTests/Features/QuizSession/`
- `QuizSessionViewModelTests.swift`:
  - Scoring: 18/20 correct → 0.9 score
  - Timer accumulates correctly
  - `recordAnswer` persists to repo (use mock)
  - Status transitions for questions mid-session
  - Bookmark toggle idempotent

### Verify
- Happy path manual test:
  1. Launch app → onboarding → License = Car → State = CA → Home
  2. Home shows countdown (if exam date set) + 0% rings
  3. Start Practice Test → CategoryList → General Knowledge → Test #1
  4. Answer 20 questions (mix right/wrong) → instant explanation shows on each
  5. Result gauge renders → Review All shows per-Q breakdown → Try Again works
  6. Bookmark a question mid-test → Settings → Bookmarks shows it (if wired)
  7. Home now shows updated category progress + avg score
- Test #2 is locked until #1 is passed
- All analytics events fire (verify in PostHog)
- Commit: `feat: core practice test loop`

---

## Phase 4 — Learn & Mastery (day 5)

### Goal
Add learn-mode level progression, weak-questions mode, realistic exam simulator, and stats dashboard tab.

### Step-by-step

**4.1 Add Route cases**
```swift
case learnSession(licenseCode: String, stateCode: String, categoryCode: String, level: Int)
case learnLevelList(categoryCode: String)
case weakQuestions
case examSimulator(config: QuizConfig)
case statsDashboard
```

**4.2 Feature: Learn level list** `examprep/Features/LearnMode/`

Algorithm: split category questions into levels of N=10. Unlock level N+1 when level N has `mastered` ratio ≥ 0.8.

`LearnLevelListView.swift`:
```swift
List {
    ForEach(vm.levels) { lvl in
        LevelRow(number: lvl.number, progress: lvl.progress, locked: lvl.locked) {
            guard !lvl.locked else { return }
            router.push(.learnSession(licenseCode: vm.license, stateCode: vm.state,
                                      categoryCode: vm.category, level: lvl.number))
        }
    }
}
```

`LearnLevelListViewModel.swift`:
```swift
struct LearnLevel: Identifiable { let id = UUID(); let number: Int; let progress: Double; let locked: Bool; let questionIds: [Int] }
// computes from ContentRepository + UserProgressRepository: masteredRatio(prev) ≥ 0.8 → unlock
```

**4.3 Learn session** — reuses `QuizSession` w/ `SessionKind.learn`. Difference: on wrong answer, question re-queued to end of list (user must answer correctly before moving on). Small banner: "Learning" / "Reviewing" based on current question's `status`.

Adjust `QuizSessionViewModel.next()`:
```swift
func next() {
    if config.kind == .learn, let last = results.last, !last.correct {
        questions.append(questions[currentIndex])   // re-queue
    }
    if currentIndex + 1 < questions.count { currentIndex += 1; reset() }
    else { finish() }
}
```

**4.4 Weak questions mode** `examprep/Features/WeakQuestions/`

`WeakQuestionsView.swift` → `QuizSession` w/ `SessionKind.weak`. Questions fetched via `statsRepo.weakQuestionIds(limit: 20)`. UI tint = orange. Header label = "Strengthen skills — Weak Questions".

**4.5 Exam simulator** `examprep/Features/ExamSimulator/`

`ExamSimulatorIntroView.swift`: shows spec summary ("46 questions • 40 min • 83% to pass"), start button. Pulls from `contentRepo.examSpec(...)`.

`ExamSimulatorView.swift` = `QuizSession` w/ `SessionKind.simulator`:
- Timer visible at top, red when < 5 min remain
- No instant explanation reveal (collect all, show at end)
- No bookmark/skip (enforce realistic exam)
- Timer expires → auto-finish

In `QuizSessionViewModel`, gate behavior by `config.kind`:
```swift
var showsExplanationOnReveal: Bool { config.kind != .simulator }
var allowsSkip: Bool { config.kind != .simulator }
```

**4.6 Feature: Stats dashboard** `examprep/Features/Stats/`

Tab replaces placeholder "Progress" tab.

`StatsDashboardView.swift`:
```swift
ScrollView {
    VStack(alignment: .leading, spacing: 20) {
        SectionHeader("Exam Readiness")
        PassingProbabilityCard(value: vm.passingProbability)

        SectionHeader("Your Categories")
        ForEach(vm.categoryStats, id: \.code) { stat in
            CategoryProgressRow(stat: stat) {
                router.push(.practiceTestList(categoryCode: stat.code))
            }
        }

        SectionHeader("Focus Areas")
        WeakQuestionsCard(count: vm.weakQCount) { router.push(.weakQuestions) }

        SectionHeader("Activity")
        StreakCard(current: vm.currentStreak, longest: vm.longestStreak)
        StudyTimeCard(totalMinutes: vm.totalMinutesStudied)
    }
}
```

`StatsDashboardViewModel.swift`: pulls all from `StatsRepositoryProtocol`; refreshes via `.task` on appear.

**4.7 Passing-probability formula** (`DefaultStatsRepository`)
```swift
// Weighted average: last 5 completed simulator/practice sessions
// probability = clamp(score - (passThreshold - 0.05) + momentum, 0, 1)
// where momentum = +0.05 if last 3 improving, -0.05 if regressing
```
Simple, explainable. Keep in repo, unit-tested.

**4.8 Tests** `examprepTests/Features/`
- `LearnLevelUnlockTests.swift` — seed mastered ratios, assert unlock rules
- `ExamSimulatorTests.swift` — verify timer auto-finish, no-skip, no-explain gating
- `PassingProbabilityTests.swift` — several scenarios

### Verify
- Start Learn mode on CA / Car / Road Signs → Level 1 → answer all correct → Level 2 unlocks
- Exam Simulator → see correct Q count from `exam_specs`, timer ticks, finishes at expiry, result gauge
- Stats tab shows live categories, weak-Q count, streak increments after a session
- Commit: `feat: learn mode + exam simulator + stats`

---

## Phase 5 — Content Extras & Retention (day 6)

### Goal
Cheat sheets, offline handbook, exam-date countdown + daily reminders, bookmarks screen, optional pro AI tutor.

### Step-by-step

**5.1 Add Route cases**
```swift
case cheatSheetList
case cheatSheetDetail(id: Int)
case handbook
case examDatePicker
case bookmarks
case aiTutor(questionId: Int?)
```

**5.2 Feature: Cheat sheets** `examprep/Features/CheatSheet/`

`CheatSheetListView.swift`:
```swift
LazyVGrid(columns: [.init(.flexible()), .init(.flexible())]) {
    ForEach(vm.sheets) { sheet in
        CheatSheetCard(
            title: sheet.title, cover: sheet.coverImage,
            locked: sheet.index >= 2 && !appState.isProUser
        ) {
            if locked { appState.showPaywall() }
            else { router.push(.cheatSheetDetail(id: sheet.id)) }
        }
    }
}
```

`CheatSheetDetailView.swift`:
```swift
ScrollView {
    if let cover = sheet.coverImage { Image(cover).resizable().aspectRatio(contentMode: .fit) }
    MarkdownView(text: sheet.bodyMd)    // use swift-markdown-ui or AttributedString
}
```

Dep: add `MarkdownUI` (SPM: `https://github.com/gonzalezreal/swift-markdown-ui`) or render via `AttributedString(markdown:)` for simpler needs.

**5.3 Feature: Handbook** `examprep/Features/Handbook/`

`HandbookView.swift`:
```swift
if let pdfName = vm.handbook.pdfName,
   let url = Bundle.main.url(forResource: pdfName, withExtension: "pdf") {
    PDFKitView(url: url)
} else if let md = vm.handbook.bodyMd {
    ScrollView { MarkdownView(text: md) }
} else {
    ContentUnavailableView("Handbook unavailable for \(vm.handbook.stateCode)", systemImage: "book.closed")
}
```

`PDFKitView.swift` — UIViewRepresentable wrapping `PDFView`.

Handbook PDFs live in `examprep/Resources/Handbooks/<state>_<license>.pdf`. Pulled lazily by filename from DTO.

**5.4 Feature: Exam-date picker** `examprep/Features/ExamDatePicker/`

`ExamDatePickerView.swift`:
```swift
VStack {
    Text("When's your exam?").font(.title2).bold()
    DatePicker("", selection: $vm.date, in: Date()..., displayedComponents: .date)
        .datePickerStyle(.graphical)
    PrimaryButton("Save") { vm.save(); vm.scheduleReminder(); router.pop() }
}
```

`ExamDatePickerViewModel`:
```swift
func save() throws { try progress.updateExamDate(date) }
func scheduleReminder() {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
        guard granted else { return }
        for daysBefore in [30, 14, 7, 3, 1] {
            let fireDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: date)!
            var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
            components.hour = 8
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Exam in \(daysBefore) days"
            content.body = "Keep practicing to pass first try."
            center.add(UNNotificationRequest(identifier: "exam-\(daysBefore)", content: content, trigger: trigger))
        }
        // Plus daily nudge
        var daily = DateComponents(); daily.hour = 8
        let dailyTrigger = UNCalendarNotificationTrigger(dateMatching: daily, repeats: true)
        let dailyContent = UNMutableNotificationContent()
        dailyContent.title = "Today's practice"; dailyContent.body = "Quick 5-min study session?"
        center.add(UNNotificationRequest(identifier: "daily-study", content: dailyContent, trigger: dailyTrigger))
    }
}
```

Add `UNUserNotificationCenter.current().delegate = self` in `AppDelegate` to handle foreground presentation.

**5.5 Feature: Bookmarks** `examprep/Features/Bookmarks/`

`BookmarksView.swift`:
```swift
List {
    ForEach(vm.bookmarkedQuestions, id: \.id) { q in
        BookmarkRow(question: q) { router.push(.quizSession(config: .singleQuestion(q.id))) }
    }
    .onDelete(perform: vm.unbookmark)
}
.toolbar {
    Button("Study All") {
        router.push(.quizSession(config: .init(
            kind: .bookmark, licenseCode: vm.license, stateCode: vm.state,
            categoryCode: nil, questionIds: vm.bookmarkedIds,
            passThreshold: 0.8, timeLimitSec: nil
        )))
    }
}
```

**5.6 Feature: AI Tutor (optional, pro-only)** `examprep/Features/AITutor/`

Gate: `appState.isProUser`, else paywall.

`AITutorView.swift` — chat UI (reuse / build simple message list).

`AITutorViewModel`:
```swift
@Observable
final class AITutorViewModel {
    var messages: [Message] = []
    var input: String = ""
    let openAI: OpenAIService
    let contextQuestion: (QuestionDTO, [AnswerDTO])?

    func send() async {
        let system = """
        You are a DMV/CDL exam tutor. The user is studying for \(license) in \(state).
        Current question: \(contextQuestion?.0.text ?? "n/a")
        Correct answer: \(contextQuestion?.1.first { $0.isCorrect == 1 }?.text ?? "n/a")
        Be concise. Cite the rule.
        """
        messages.append(.user(input))
        let reply = try? await openAI.chat(system: system, user: input)
        messages.append(.assistant(reply ?? "…"))
        input = ""
    }
}
```
Entry point: button "Why am I wrong?" on `QuizSessionView` after a wrong answer → pushes `.aiTutor(questionId: currentId)`.

Caching: key = questionId, stored in UserDefaults or SwiftData `CachedExplanation` model. First request hits API, subsequent use cache.

Rate limit: ≤ 10 requests per user per day (free trial for pro), unlimited for pro.

**If time-boxed, skip AI Tutor — ship in v1.1.**

**5.7 Settings additions** `examprep/Features/Settings/`
Add rows:
- License — shows current, tap → `.licensePicker`
- State — tap → `.statePicker`
- Exam Date — tap → `.examDatePicker`
- Language — tap → picker (en/es/zh)
- Daily Goal — stepper for questions/day
- Bookmarks → `.bookmarks`
- Restore Purchases (existing)

**5.8 Tests**
- `ExamDatePickerViewModelTests.swift` — scheduling logic creates expected `UNNotificationRequest`s (mock center)
- `AITutorViewModelTests.swift` — caching behavior (mock OpenAIService)
- `BookmarksViewModelTests.swift` — add/remove/list

### Verify
- Cheat sheet renders markdown + embedded image. Pro gate triggers on 3rd sheet.
- Handbook opens PDF offline. Falls back to markdown for states w/o PDF.
- Setting exam date schedules 5 reminders + daily 8am nudge (check via Settings → Notifications).
- Bookmark 3 questions → Bookmarks screen lists them → "Study All" runs a session.
- AI tutor replies concisely (if shipped).
- Commit: `feat: cheat sheets + handbook + reminders + bookmarks`

---

## Phase 6 — Polish, Onboarding, Localization (day 7)

### Goal
Rebuild onboarding around exam-prep funnel, polish Home, scaffold i18n, wire full analytics funnel. Ship-ready.

### Step-by-step

**6.1 Onboarding rebuild** `examprep/Features/OnboardingFlow/`

New step list (in order):
1. `OnboardingWelcomeView` — existing, update copy + illustration ("Pass your DMV exam — first try")
2. `OnboardingValueProp1View` — "700+ state-specific questions"
3. `OnboardingValueProp2View` — "Realistic exam simulator"
4. `OnboardingValueProp3View` — "Track progress + weak spots"
5. **NEW** `OnboardingLicenseView` — wraps `LicenseSelectView` w/ "Next" styling
6. **NEW** `OnboardingStateView` — wraps `StateSelectView` w/ "Next" styling
7. **NEW** `OnboardingExamDateView` — optional, "Set exam date for countdown" + skip
8. **NEW** `OnboardingNotificationsView` — asks UN authorization ("Get reminders"), skippable
9. `OnboardingRateUsView` — existing
10. `TrialScreen1View` + `TrialScreen2View` — paywall gate

`OnboardingFlowView.swift` — step array:
```swift
enum OnboardingStep: Int, CaseIterable {
    case welcome, value1, value2, value3, license, state, examDate, notifications, rateUs, trial1, trial2
}
```

Persist completion via `UserRepository.markOnboardingComplete()`. `RootView` checks this flag to skip onboarding on relaunch.

**6.2 Home refinement** `examprep/Features/Home/HomeView.swift`

Final layout (mirrors CDL-Pass "Home" screen):
```swift
ScrollView {
    VStack(spacing: 20) {
        GreetingHeader(name: vm.name, stateName: vm.stateName)          // "Arizona ▾" top-left
        ExamCountdownCard(date: vm.examDate, secondsLeft: vm.countdown,
                          onTap: { router.push(.examDatePicker) })
        PassingProbabilityRing(value: vm.passingProbability, label: "\(Int(vm.passingProbability*100))%")
        QuickActionsRow(actions: [
            .practice → router.push(.categoryList),
            .simulator → router.push(.examSimulator(...)),
            .weakQs → router.push(.weakQuestions),
            .cheatSheets → router.push(.cheatSheetList)
        ])
        SectionHeader("Your Progress")
        ForEach(vm.categoryStats, id: \.code) { stat in
            CategoryProgressRow(stat: stat)
        }
        SectionHeader("Resources")
        NavigationLink("Handbook", destination: ...) 
        NavigationLink("Cheat Sheets", destination: ...)
    }
}
.refreshable { await vm.refresh() }
```

**6.3 Localization** `examprep/Presentation/Resources/`

Add `Localizable.xcstrings` (new iOS 17 catalog) with:
- `en.lproj/` — primary, fill all UI strings
- `es.lproj/` — scaffolded empty (add 10–20 critical strings, leave rest for later)
- `zh-Hans.lproj/` — scaffolded empty

Replace all user-facing strings with `String(localized: "key")`.

Content-level: `ContentRepository.questions(..., lang:)` already supports `lang` filter. User lang lives in `UserExamProfile.preferredLang`. Add Settings toggle:
```swift
Picker("Language", selection: $vm.preferredLang) {
    Text("English").tag("en"); Text("Español").tag("es"); Text("中文").tag("zh")
}
```

**6.4 Analytics funnel** `examprep/Data/Services/PostHogAnalyticsService.swift`

Wire events (call sites):
- `.onboardingStarted` in `OnboardingFlowView.onAppear`
- `.onboardingStepCompleted` on each step advance, prop `{ "step": "license" }`
- `.onboardingFinished` on completion
- `.licenseSelected`, `.stateSelected`, `.examDateSet` at source
- `.quizStarted` in `QuizSessionViewModel.load()`
- `.questionAnswered` in `QuizSessionViewModel.record()`, prop `{ "correct": true }`
- `.quizCompleted`, `.examSimulatorCompleted`, `.learnSessionStarted`, `.weakQuestionMastered`
- `.paywallShown`, `.purchaseStarted`, `.purchaseCompleted` in `Purchases` flow

PostHog dashboard: build funnel `onboardingStarted → licenseSelected → stateSelected → quizStarted → quizCompleted → paywallShown → purchaseCompleted`.

**6.5 App icon + store metadata**
- New `AppIcon` set in `Assets.xcassets`
- Update `Info.plist`: `CFBundleDisplayName`, privacy usage strings (drop camera, add notifications description)
- Fastlane metadata: update `fastlane/metadata/` (app name, subtitle, description, keywords, screenshots from skills `aso-appstore-screenshots`)

**6.6 Inject hot-reload check**
Verify `Inject` still works in new feature files. Add `@ObservedObject private var injectObserver = Inject.observer` + `.enableInjection()` to key views per existing pattern.

**6.7 Tests**
- End-to-end UI test (`examprepUITests/`): fresh install → onboarding → license → state → paywall → skip → take one quiz → see result → open cheat sheets → close
- Snapshot tests for Home, QuizSession, QuizResult in light/dark mode

### Verify
- Fresh install → onboarding full flow → skip paywall → Home → take practice test → next day reminder fires
- Dark mode + Dynamic Type (XXL) look correct across all screens
- Switch language to ES (w/ partial strings) → falls back to EN for missing keys gracefully
- PostHog dashboard shows full funnel
- Run `swiftgen` for updated assets, `graphify update .` for final graph
- Commit: `feat: onboarding rebuild + home polish + i18n scaffold + funnel analytics`

---

## Per-phase exit criteria (MVP gate)

Minimum to ship v1.0 to TestFlight: Phases 1 + 2 + 3 complete, w/ sample seed covering CA (car + CDL) to prove multi-license. Phases 4–6 land as weekly TF builds.

## First implementation action on approval
Copy this plan file to `tasks/CLEANUP_AND_FEATURES_PLAN.md` in the repo so it's checked in for future reference. Also create `tasks/todo.md` with phase-1 checklist per CLAUDE.md convention.

---

## Critical files / paths

**Delete (Phase 1)**
- `examprep/Features/{CameraCapture,Scanner,Collection,Grading,Watchlist,Detection,Search}/`
- `examprep/Domain/Models/{CardRecord,CardCollection,GradeRecord,ScanRecord,WatchlistItem,CardAPIModels,GradingAPIModels,DetectionResult}.swift`
- `examprep/Domain/Enums/TCGType.swift`
- `examprep/Data/Services/{CardIdentifierService,GradingService,OpenAIProxiedService,WatchlistPriceService}.swift`
- `examprep/Domain/Protocols/{CardIdentifierServiceProtocol,GradingServiceProtocol}.swift`
- `examprep/Presentation/Components/PriceChartView.swift`

**Refactor**
- `examprep/Constants.swift` — rebrand
- `examprep/Core/Navigation/Router.swift` — new Route enum
- `examprep/Application/AppMain.swift` — drop TCG models, add GRDB bootstrap + content DB copy
- `examprep/Application/AppState.swift` — new tab enum
- `examprep/Core/DI/DIContainer.swift` — register `ContentRepository`, `UserProgressRepository`, `StatsRepository`
- `examprep/Features/OnboardingFlow/OnboardingFlowView.swift` — trim + add license/state/exam-date steps
- `examprep/Application/RootView.swift` — new tab set
- `examprep/Domain/Enums/AnalyticsEvent.swift` — new events

**Add**
- `examprep/Data/DB/GRDBContentDatabase.swift`
- `examprep/Data/Repositories/{ContentRepository,UserProgressRepository,StatsRepository}.swift`
- `examprep/Domain/Models/{UserExamProfile,QuestionAttempt,PracticeSession,SessionAnswer,BookmarkedQuestion,StudyStreak}.swift`
- `examprep/Features/{LicenseSelect,StateSelect,CategoryList,PracticeTestList,QuizSession,QuizResult,LearnSession,ExamSimulator,CheatSheet,Handbook,Bookmarks,Stats,AITutor}/`
- `examprep/Presentation/Components/{QuestionCardView,AnswerOptionButton,ScoreGaugeView,ProgressRingView,CountdownView}.swift`
- `examprep/Resources/exam_content.sqlite`
- `tools/seed/` — schema DDL + Python/Node seed script + sample CSV

---

## Dependencies to add
- `GRDB.swift` (SPM)
- Remove (if unused after purge): any TCG-specific SDKs

## Dependencies kept
- RevenueCat, SwiftData, PostHog, Sentry, SwiftGen, Inject

---

## Verification end-to-end
- `swift build` / Xcode build clean
- Unit tests: `ContentRepository` fetch, `QuizSessionViewModel` scoring, `StatsRepository` passing probability
- Manual: fresh install → onboarding → CA / Car → Practice Test #1 → 20 Qs → result screen → review → bookmarks → learn mode → simulator → paywall opens on gated cheat sheet → restore purchases works
- Analytics: events fire in PostHog dashboard
- Notifications: exam countdown reminder fires at set time

## Rollout / risk
- Keep same bundle ID + entitlement rename in RevenueCat dashboard (zero subscriber churn)
- Ship Phase 1–3 first as MVP (usable app w/ core loop)
- Phase 4–6 iterative releases
- Content seeding decoupled from app build — can ship expanded question banks via SQLite replacement (future: remote download)

---

## Unresolved questions

1. **App name / branding** — keep "Poke" rebranded or rename (e.g., `DriveTest Prep`, `CDL Prep`, `Permit Ace`)? Affects Constants, icon, App Store listing.
2. **Bundle ID / RevenueCat** — reuse current app record (rename entitlement) or start fresh?
3. **SQLite library** — GRDB.swift (recommended) or SQLite.swift / raw sqlite3?
4. **Content seeding source** — do you have a question bank already (CSV/JSON), or should the seed script start empty and you fill manually?
5. **AI Tutor** — ship in MVP (Phase 5) or defer to v2? Adds OpenAI infra cost/complexity.
6. **Localization priority** — EN only at launch, or ES/ZH from day 1?
7. **Handbooks** — ship PDFs in bundle (larger binary) or lazy-download from server (needs hosting)?
8. **Exam countdown notifications** — opt-in during onboarding or post-install prompt?
