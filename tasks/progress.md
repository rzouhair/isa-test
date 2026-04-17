# TCG Scanner MVP — Progress Log

**Last updated:** 2026-04-05

---

## Phase 0: Foundation ✅

All 9 tasks complete. API data layer established.

### New Files
| File | Path | Purpose |
|---|---|---|
| CardAPIModels.swift | `Domain/Models/` | 12 Codable structs (JobSubmitResponse, JobStatusResponse, CardResponse, CardData, Product, CardImages, CardIdentity, CardAttributes, Pricing, CardMetadata, ConfidenceBreakdown, Candidate). All `Sendable`. |
| CardIdentifierServiceProtocol.swift | `Domain/Protocols/` | `submitJob(imageData:)` + `checkStatus(jobId:)` |
| CardIdentifierService.swift | `Data/Services/` | URLSession implementation + `CardIdentifierError` enum (invalidURL, invalidResponse, noResult, jobFailed, decodingFailed) |
| ScanRecord.swift | `Domain/Models/` | SwiftData `@Model`. Fields from PRD §1.5a. `ScanStatus` enum maps 8 API statuses → 4 client states (pending/processing/complete/failed). `update(from: CardResponse)` populates all fields on complete. |
| CardRecord.swift | `Domain/Models/` | SwiftData `@Model`. Fields from PRD §1.6. `init(from: ScanRecord)` convenience initializer. |

### Modified Files
| File | Change |
|---|---|
| Constants.swift | Added `cardIdentifierBaseURL` (currently `http://localhost:8000`) |
| AppMain.swift | Added `import SwiftData`, `ModelContainer(for: ScanRecord.self, CardRecord.self)`, `.modelContainer()` modifier on RootView |
| DIContainer.swift | Added `lazy var cardIdentifierService: CardIdentifierServiceProtocol` |
| RootView.swift | Added `#if DEBUG` "API Test" toolbar button for end-to-end API validation |

---

## Phase 1: Scanner Core Loop ✅ (pending verification)

All 8 implementation tasks complete. Manual verification (1.9) pending.

### New Files
| File | Path | Purpose |
|---|---|---|
| CameraService.swift | `Features/Scanner/` | `@Observable @MainActor` AVCaptureSession manager. Start/stop, photo capture, flash toggle, zoom (1x/2x/3x). Custom `PreviewContainerView` (UIView subclass) that sizes AVCaptureVideoPreviewLayer in `layoutSubviews`. `ScannerPhotoCaptureDelegate` for capture callbacks. |
| ScanStore.swift | `Features/Scanner/` | `@Observable @MainActor` singleton. Core scan queue manager backed by SwiftData. Key methods: `capture(image:)` — saves JPEG to disk, inserts ScanRecord, POSTs `/identify/async`, starts polling. `startPolling(_:)` — polls `/status/{jobId}` every 2s, max 60 attempts. `retryFailed(_:)` — re-submits captured image. `addToCollection(_:)` / `addAllToCollection()` — ScanRecord → CardRecord. `deleteRecord(_:)` — removes single scan + cancels polling + deletes image from disk. `clearSession()` — bulk delete all. `loadRecent()` — last 3 from SwiftData, resumes polling for in-progress records. 50-scan cap enforcement. `Dictionary<UUID, Task>` for active poll tasks. |
| ScannerViewModel.swift | `Features/Scanner/` | Bridges CameraService + ScanStore. Stores `cropRect` + `screenSize` from viewfinder guides. On capture: haptic feedback → crop image to viewfinder area → resize to 768px max (LLM vision optimized) → JPEG 0.6 quality → pass to ScanStore. Crop math handles `resizeAspectFill` coordinate mapping (screen → image pixels). |
| ScanRecordRow.swift | `Features/Scanner/` | 3 visual states per PRD §1.1: **Pending/Processing** — blurred thumbnail + "Identifying Card..." with pulsing opacity animation. **Identified** — API card image, SET NAME • LANG, Year Name #Number, EST VALUE $X.XX, +ADD button (turns ✓ on add). **Failed** — dimmed thumbnail + "Could not identify — tap to retry" in amber. Includes `Color(hex:)` extension. |
| RecentScansSheet.swift | `Features/Scanner/` | Bottom sheet content: header ("Recent scans" + CLEAR pill + "$X.XX total"), bulk "Add all to Collection" button (visible when ≥2 identified), List with swipe-to-delete on each row, empty state with "load previous scans" link, success toast on bulk add. |
| ScannerView.swift | `Features/Scanner/` | Fullscreen camera screen. Top bar (× close, ⚡ flash). Dark overlay (50% black) with rounded-rect cutout over card area. L-shaped corner brackets (`#7DD3FC`). Zoom pills (1×/2×/3×). "Tap Anywhere to Scan" hint. Bottom sheet with `.presentationDetents([.height(120), .medium, .large])` and `.presentationBackgroundInteraction(.enabled(upThrough: .medium))`. Permission denied overlay with "Open Settings" CTA. 50-scan capacity alert. |

### Modified Files
| File | Change |
|---|---|
| Router.swift | Added `.scanner`, `.collection`, `.cardDetail(CardRecord)` routes with titles + icons |
| HighlightTabBar.swift | Center camera button now opens `.scanner` instead of `.camera` |
| RootView.swift | Added `ScannerView()` routing for `.scanner`. Placeholder stubs for `.collection` and `.cardDetail`. |

### Bug Fixes Applied
| Issue | Root Cause | Fix |
|---|---|---|
| Black camera screen | `ScannerCameraPreview` UIView had zero-frame preview layer on initial layout | Replaced with `PreviewContainerView` subclass overriding `layoutSubviews()` |
| "Failed to identify" on every scan | Image exceeded 5MB API limit (full-res uncropped photo) | Added viewfinder crop + resize to 768px + JPEG 0.6 compression |
| Crop coordinates mismatched | Viewfinder GeometryReader used safe-area coords, camera was edge-to-edge | Added `.ignoresSafeArea()` to viewfinder GeometryReader |
| Sheet padding too tight | Header/rows had 16pt horizontal padding | Increased to 20pt horizontal, 16pt top |

### Image Pipeline
```
Raw capture (12MP, ~4032x3024)
  → Crop to viewfinder card area (screen coords → pixel coords, resizeAspectFill mapping)
  → Resize to 768px long edge (LLM vision token-optimized, ~1100 tokens)
  → JPEG compress at 0.6 quality
  → Result: ~50-100KB per card image
```

### Architecture Decisions
- **ScanStore as singleton** — accessible from scanner, collection, home. Manages poll lifecycle independently of view hierarchy.
- **CameraService separate from ViewModel** — reusable, testable AVFoundation wrapper. ViewModel owns the crop/optimize/capture logic.
- **SwipeActions for delete** — switched from ScrollView+LazyVStack to List for native swipe gesture support.
- **Dark overlay with Canvas** — uses `destinationOut` blend mode for cutout, avoids complex path math.

---

## Phase 2: Collection Dashboard + Card Detail — Not Started

## Phase 3: Search (M2) — Not Started

## Phase 4: Polish & Retention (M3) + Cleanup — Not Started

---

## Current File Map

```
poke/
├── Application/
│   ├── AppMain.swift              ← modified (SwiftData ModelContainer)
│   └── RootView.swift             ← modified (scanner routing, debug button)
├── Core/
│   ├── DI/DIContainer.swift       ← modified (cardIdentifierService)
│   └── Navigation/Router.swift    ← modified (scanner/collection/cardDetail routes)
├── Data/Services/
│   └── CardIdentifierService.swift ← NEW
├── Domain/
│   ├── Models/
│   │   ├── CardAPIModels.swift     ← NEW (12 Codable structs)
│   │   ├── ScanRecord.swift        ← NEW (@Model + ScanStatus)
│   │   └── CardRecord.swift        ← NEW (@Model)
│   └── Protocols/
│       └── CardIdentifierServiceProtocol.swift ← NEW
├── Features/Scanner/               ← NEW directory
│   ├── CameraService.swift
│   ├── ScanStore.swift
│   ├── ScannerViewModel.swift
│   ├── ScanRecordRow.swift
│   ├── RecentScansSheet.swift
│   └── ScannerView.swift
├── Presentation/Components/
│   └── HighlightTabBar.swift      ← modified (.scanner route)
└── Constants.swift                ← modified (cardIdentifierBaseURL)
```
