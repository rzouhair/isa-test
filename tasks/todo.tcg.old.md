# TCG Scanner MVP — Implementation Plan

## Phase 0: Foundation (API + Data Layer)

> Validate API round-trip, establish data models. No UI changes.

- [x] **0.1** Create `Domain/Models/CardAPIModels.swift` — all Codable structs from API_SWIFT_MODEL.md (`JobSubmitResponse`, `JobStatusResponse`, `CardResponse`, `CardData`, `Product`, `CardImages`, `CardIdentity`, `CardAttributes`, `Pricing`, `CardMetadata`, `ConfidenceBreakdown`, `Candidate`)
- [x] **0.2** Create `Domain/Protocols/CardIdentifierServiceProtocol.swift` — `submitJob(imageData:)`, `checkStatus(jobId:)`
- [x] **0.3** Create `Data/Services/CardIdentifierService.swift` — URLSession impl + `CardIdentifierError` enum
- [x] **0.4** Create `Domain/Models/ScanRecord.swift` — @Model, fields from PRD §1.5a + `ScanStatus` enum (pending/processing/complete/failed mapping 8 API statuses → 4)
- [x] **0.5** Create `Domain/Models/CardRecord.swift` — @Model, fields from PRD §1.6 + `init(from: ScanRecord)`
- [x] **0.6** Update `Constants.swift` — add `cardIdentifierBaseURL`
- [x] **0.7** Update `AppMain.swift` — register ScanRecord + CardRecord in ModelContainer
- [x] **0.8** Update `DIContainer.swift` — add `CardIdentifierServiceProtocol` lazy property
- [x] **0.9** Validate: `#if DEBUG` button → POST /identify → poll /status → print CardResponse

**Done when**: API round-trip works end-to-end from a debug button.

---

## Phase 1: Scanner Core Loop

> Camera + bottom sheet + background processing + add to collection.

- [x] **1.1** Create `Features/Scanner/CameraService.swift` — extract `CameraPreviewView` (UIViewRepresentable) + `PhotoCaptureDelegate` from existing CameraView.swift. Remove two-sided capture, crop frame, shutter.
- [x] **1.2** Create `Features/Scanner/ScanStore.swift` — @Observable singleton backed by SwiftData
  - `capture(image:)` — save image, insert ScanRecord, POST /identify, begin poll
  - `pollJob(_:)` — poll every 2s, update ScanRecord on complete/fail
  - `retryFailed(_:)` — re-submit captured image
  - `addToCollection(_:context:)` — ScanRecord → CardRecord
  - `addAllToCollection(context:)` — bulk add
  - `clearSession()` — delete all current session ScanRecords
  - `loadRecent()` — last 3 from SwiftData
  - `Dictionary<UUID, Task>` for active poll tasks, cancellation
  - 50-scan cap enforcement
- [x] **1.3** Create `Features/Scanner/ScannerViewModel.swift` — camera state (session, flash, zoom, isCapturing)
- [x] **1.4** Create `Features/Scanner/ScanRecordRow.swift` — 3 visual states (pending/identified/failed) per PRD §1.1 card row spec
- [x] **1.5** Create `Features/Scanner/RecentScansSheet.swift` — header (Recent scans + CLEAR + $total), bulk "Add all", ScrollView of ScanRecordRow, empty state, pagination
- [x] **1.6** Create `Features/Scanner/ScannerView.swift` — fullscreen camera + top bar (×, ⚡) + viewfinder guides + zoom pills + .sheet with RecentScansSheet
- [x] **1.7** Update `Router.swift` — add `.scanner`, `.cardDetail(CardRecord)`, `.collection` routes
- [x] **1.8** Update `RootView.swift` — center tab button → `.scanner` fullscreen cover, Tab 0 = placeholder
- [ ] **1.9** Verify: scan 3 cards → see results in sheet → add to collection → clear → retry failed

**Done when**: User can continuously scan cards, see them identified in the bottom sheet, and add to collection.

---

## Phase 2: Collection Dashboard + Card Detail

> Browse saved cards, portfolio value, card detail with prices.

- [ ] **2.1** Create `Features/Collection/CollectionViewModel.swift` — sort logic, portfolio computation
- [ ] **2.2** Create `Features/Collection/CollectionView.swift` — @Query CardRecord, portfolio strip (total cards/value/sets), LazyVStack card rows, sort action sheet (value/date/name/set), sort pref in UserDefaults
- [ ] **2.3** Create `Features/Collection/CardDetailView.swift` — full card image (AsyncImage), name/set/rarity/variant badge, price rows (market/lowest/median + "LIVE" pill), confidence badge, "View on TCGPlayer ↗" (SFSafariViewController), "+Collection" toggle
- [ ] **2.4** Update `RootView.swift` — Tab 0 = CollectionView, wire cardDetail navigation
- [ ] **2.5** Update `UserDefaultsDatasource.swift` — add `collectionSortOrder` key
- [ ] **2.6** Verify: scan → add → dismiss scanner → collection shows cards → tap → detail → TCGPlayer link → sort works

**Done when**: Full M1 loop — scan → identify → add → browse collection → card detail.

---

## Phase 3: Search (M2)

> Search cards by name, autocomplete, quick-add, error correction.

- [ ] **3.1** Create `Features/Search/SearchViewModel.swift` — debounced search, game filter state, recent searches (UserDefaults), quick-add
- [ ] **3.2** Create `Features/Search/SearchView.swift` — search bar (34pt pill), cancel, game filter chips (All/Pokémon/MTG/YuGiOh/Lorcana), recent searches list, browse sets grid, autocomplete (150ms debounce, 6 results), results list with "+Add"
- [ ] **3.3** Create `Features/Scanner/ErrorCorrectionView.swift` — captured photo + 4 candidates from CardMetadata.candidates, radio select, "Confirm" updates ScanRecord, "search manually" link
- [ ] **3.4** Update `Router.swift` — add `.search` route
- [ ] **3.5** Update `RootView.swift` — Tab 1 = SearchView
- [ ] **3.6** Verify: search "Charizard" → autocomplete → results → quick-add → appears in collection. Low-confidence scan → error correction → select correct card.

**Done when**: Search + error correction working. M2 complete.

**Note**: Search API endpoint TBD — may need backend endpoint or bundled local card name index for autocomplete.

---

## Phase 4: Polish & Retention (M3) + Cleanup

> Production quality, offline, export, notifications, dead code removal.

### Features
- [ ] **4.1** Create `Presentation/Components/JobLoadingTile.swift` — reusable 4-state component (pending/processing/complete/failed)
- [ ] **4.2** CSV Export — `exportCSV() -> URL` in CollectionViewModel, ShareLink, background thread + progress for >1k cards
- [ ] **4.3** Search Filters — bottom sheet (game/rarity chips, price slider, sort), active filter badge
- [ ] **4.4** Create `Data/Services/NetworkMonitor.swift` — NWPathMonitor, offline banner in scanner, offline scan queue (auto-submit on reconnect)
- [ ] **4.5** Push Notifications — permission on first scan, local notifs when backgrounded + job completes, deep-links

### Dead Code Removal
- [ ] **4.6** Delete replaced files:
  - `Features/Detection/DetectionView.swift` + `DetectionViewModel.swift`
  - `Domain/Models/DetectionResult.swift` + `DetectionDetail.swift`
  - `Data/Services/OpenAIProxiedService.swift` + `OpenAIService.swift`
  - `Domain/Protocols/AIServiceProvider.swift`
  - `Domain/Functions/ToolDefinition.swift`
  - `Domain/Utilities/OpenAIParser.swift`
  - `Features/CameraCapture/CameraView.swift`, `CameraCaptureView.swift`, `ResizableCropFrameView.swift`, `PhotoView.swift`
  - `Features/Home/HomeView.swift` + `HomeViewModel.swift`
  - `Item.swift`
- [ ] **4.7** Remove `.detection(images:)` from Router, DetectionResult from ModelContainer
- [ ] **4.8** SwiftData migration — pre-launch: drop old schema. Post-launch: lightweight SchemaMigrationPlan.
- [ ] **4.9** Full regression test: onboarding → scan 5 cards → add all → collection → detail → TCGPlayer → search → add → CSV export → offline banner → reconnect

**Done when**: M3 complete, no dead code, production-ready.

---

## Risk Log

| Risk | Impact | Mitigation |
|---|---|---|
| API shape differs from docs | Blocks everything | Validate in Phase 0 before any UI |
| Bottom sheet over camera tricky | Scanner UX broken | Prototype `.presentationDetents` early in Phase 1 |
| Swift 6 concurrency + poll task dict | Crashes / data races | Use @MainActor for SwiftData, structured concurrency |
| Search API not available | M2 search broken | Fallback: bundled local card name index JSON |
| SwiftData migration (old → new models) | Crash on update | Pre-launch = drop. Post-launch = migration plan |

---

## File Map

| Phase | New Files | Modified |
|---|---|---|
| 0 | `CardAPIModels.swift`, `CardIdentifierServiceProtocol.swift`, `CardIdentifierService.swift`, `ScanRecord.swift`, `CardRecord.swift` | `Constants`, `AppMain`, `DIContainer` |
| 1 | `CameraService.swift`, `ScanStore.swift`, `ScannerViewModel.swift`, `ScanRecordRow.swift`, `RecentScansSheet.swift`, `ScannerView.swift` | `Router`, `RootView`, `HighlightTabBar` |
| 2 | `CollectionViewModel.swift`, `CollectionView.swift`, `CardDetailView.swift` | `RootView`, `UserDefaultsDatasource` |
| 3 | `SearchViewModel.swift`, `SearchView.swift`, `ErrorCorrectionView.swift` | `Router`, `RootView` |
| 4 | `JobLoadingTile.swift`, `NetworkMonitor.swift` | Cleanup across app |
