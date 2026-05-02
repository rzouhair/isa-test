# TCGPlayer Scanner — MVP PRD

**Version:** 1.0 MVP  
**Last updated:** April 2026  

> Only scanner built on TCGPlayer pricing data. Core job: *"Tell me what my cards are worth, fast."*

---

## Milestones

| Milestone | Focus | Ship criteria |
|---|---|---|
| M1 | Core scan-price-collect loop | User can scan 1 card, see price, add to collection |
| M2 | Batch + Search | User can scan N cards at once, search by name, quick-add |
| M3 | Polish + Retention | Filters, export, offline, notifications, deep-links |

---

## M1 — Core Loop

### 1.1 Scanner Screen (Continuous Scan + Recent Scans Sheet)

Single unified screen — camera + draggable bottom sheet. No separate scan result screen. User can bulk-scan cards without leaving.

#### Layout (top → bottom)

- **Top bar**: × close button (left, 44×44pt tap target), ⚡ flash/torch toggle (right, 44×44pt). Dark semi-transparent bg.
- **Viewfinder** (~65% of screen): live camera feed, 4 corner bracket guides (L-shaped, 22×22pt, `#7DD3FC`) frame the card. "Tap Anywhere to Scan" hint centered in viewfinder (14pt, white, semi-transparent bg pill).
- **Zoom controls**: 1×, 2×, 3× horizontal pill row centered below viewfinder. Selected pill highlighted (white bg), others dimmed (dark bg). Default 1×.
- **Recent Scans sheet**: draggable bottom sheet overlaying lower portion of screen.

#### Capture Behavior

- Tap anywhere on viewfinder to capture (no shutter button)
- On capture: haptic feedback (`.medium`) + brief white flash overlay (100ms fade)
- Captured image saved locally, ScanRecord inserted into ScanStore (SwiftData), `POST /identify` dispatched in background
- New row appears immediately at top of sheet list in "Identifying Card..." state
- User stays on camera — can scan next card immediately. No navigation on capture.
- Single-sided capture only (no front/back)
- Cap: 50 scans per session. After 50 → alert "Add or clear cards before scanning more"
- Camera permission denied → prompt UI w/ "Open Settings" CTA
- Camera live ≤400ms of screen active
- Variant/holo detection handled server-side by API. Client sends raw image only.

#### Recent Scans Bottom Sheet (LLD)

**Presentation**: SwiftUI `.presentationDetents` with 3 stops:
- Collapsed peek (~120pt): header row + top 1 card row visible. Default on scanner open.
- Half (.medium): header + ~4 card rows visible. Camera still visible above.
- Full (.large): sheet covers entire screen. Camera hidden behind.
- Drag handle (pill, 36×5pt, `#555`) visible at top of sheet. Dark bg (`#0F172A` 95% opacity).

**Header row**:
- Left side: "Recent scans" (17pt, bold, white) + "CLEAR" pill button (caps, 11pt, rounded outline, white border, 6pt horizontal padding)
- Right side: "$X.XX total" (17pt, bold, green `#16A34A`) — sum of `marketPrice` for all identified cards in queue
- CLEAR button: tap → confirmation alert "Clear all N scanned cards?" → deletes all ScanRecords from current session

**Bulk action row** (visible when ≥2 identified cards):
- "Add all to Collection" full-width button (green `#16A34A` fill, white text, 14pt semibold, 48pt height, 12pt corner radius)
- Tap → adds all identified cards to collection as CardRecords (§1.6), shows success toast "Added N cards!"

**Card row spec** (scrollable list, newest first, each row ~80pt height):

| State | Thumbnail (left) | Info (center) | Action (right) |
|---|---|---|---|
| Pending / Processing | 48×64pt blurred captured image, rounded 4pt corners | "Identifying Card..." (14pt, gray `#9CA3AF`, italic). Subtle pulsing opacity animation (0.4–1.0, 1.5s cycle). | — |
| Identified | 48×64pt card image (from API `images.small`, rounded 4pt). Variant-count badge bottom-left (e.g. "1/2", "1/6" — blue `#3B82F6` bg, white text, 9pt, rounded). | **Line 1**: SET NAME • LANG (9pt, caps, gray `#9CA3AF`, e.g. "PALDEAN FATES • EN") | **Line 2**: Year CardName #Number (11pt, white, semibold, e.g. "2024 Charizard ex #234") | **Line 3**: "EST VALUE" label (9pt, gray) + **$X.XX** (12pt, bold, green `#16A34A` — from `pricing.marketPrice`) | "＋ADD" button (green `#16A34A` outline border, "+" icon + "ADD" label, 44×44pt tap target) |
| Failed | 48×64pt captured image (dimmed, 50% opacity, rounded 4pt) | "Could not identify — tap to retry" (14pt, amber `#F59E0B`) | Tap entire row → re-submit to `POST /identify` |

**ADD button behavior**:
- Tap → tooltip bubble "Add to Collection" appears above button (white bg, dark text, arrow pointing down, auto-dismiss 2s)
- Card converted to CardRecord (§1.6) and inserted into collection
- Button becomes "✓" (green `#16A34A` filled, disabled)
- If card already in collection → alert "Already in collection — add duplicate?" w/ "Add duplicate" / "Cancel"

**Tap on identified row** (not on ADD button): Navigate to Card Detail (§1.4).

**Pagination**: When >4 rows, show "Tap to see more ▼" pill button at bottom (outline, centered, 13pt). Tap expands sheet to .large and scrolls to reveal all.

**On scanner open**: Load last 3 ScanRecords from SwiftData (any status). Allows user to see results from previous session or retry failed items.

**Empty state** (no ScanRecords):
- "Scanned cards will appear here" (13pt, gray `#9CA3AF`, centered)
- "Tap to load previous scans." (13pt, blue `#3B82F6` link — loads full ScanRecord history from SwiftData)

### 1.3 Collection Dashboard

- Scrollable card list (virtualised, 60fps up to 5k cards)
- Each row: 28×38pt color thumbnail, name (11pt/500), set+rarity (9pt), price (12pt/600, green)
- Tap row → card detail
- Real-time update when card added via scan
- **Portfolio summary strip**: total cards, total value (sum TCGPlayer prices), distinct sets
- Recompute on foreground + each list load
- **Sort** (action sheet): Value high→low (default), Value low→high, Date added new→old, Date added old→new, Name A-Z, Set
  - Sort preference persists locally
  - Client-side, no network call

### 1.4 Card Detail Screen

- Card image full-width (140pt, dark bg)
- Name, set, number, rarity, variant badge
- Prices tab (default): rows for `marketPrice`, `lowestPrice`, `medianPrice` from API. TCGPlayer row highlighted w/ "LIVE" green pill.
- Prices fetched fresh; cached <15min shown w/ "Last updated X min ago"
- Confidence from `metadata.confidence` — shown as badge if <80% (amber)
- "View on TCGPlayer ↗" opens SFSafariViewController w/ `product.url` from API response
  - Unavailable → button greyed out
- "+Collection" / "In collection ✓" toggle (same logic as §1.1 ADD button)

### 1.5 Scan Job State Machine

**API job statuses** (server-side): `pending` → `intake` → `vision` → `search` → `comparison` → `verifying` → `sweeping` → `complete` | `failed`

**Client-side simplified mapping**:
- `pending` / `intake` → UI: "Identifying Card..." (pending state)
- `vision` / `search` / `comparison` / `verifying` / `sweeping` → UI: "Identifying Card..." (processing, pulsing animation)
- `complete` → UI: identified card row with price + ADD button
- `failed` → UI: error row with tap-to-retry

**Polling**: Client polls `GET /status/{job_id}` every 2s until `complete` or `failed`.
**Concurrency**: Multiple jobs process simultaneously (no single-job restriction).
**Background**: Polling continues even if user leaves scanner screen (managed by ScanStore singleton).
- UI reflects state change ≤500ms
- Job state persisted in SwiftData; survives app kill
- Jobs >24h auto-expired

### 1.5a ScanStore (Shared Singleton)

`ScanStore`: @Observable singleton backed by SwiftData. Holds scan queue, accessible app-wide (scanner sheet, collection, home).

```
ScanRecord (@Model) {
  id:                UUID (unique)
  jobId:             String?         // from POST /identify response
  status:            String          // pending | processing | complete | failed
  capturedImagePath: String          // local file path of captured photo

  // Populated on complete (from CardResponse)
  productId:         String?
  productName:       String?
  platform:          String?         // "tcgplayer" | "buysportscards"
  productUrl:        String?

  // Images (from API)
  imageSmall:        String?
  imageMedium:       String?

  // Identity
  cardNumber:        String?
  setName:           String?
  setCode:           String?
  rarity:            String?
  year:              String?
  language:          String?
  game:              String?         // examprepmon | mtg | yugioh | lorcana
  variant:           String?
  variantName:       String?

  // Pricing
  marketPrice:       Double?
  lowestPrice:       Double?
  medianPrice:       Double?
  currency:          String?

  // Metadata
  confidence:        Double?
  candidatesCount:   Int?
  cardTypeDetected:  String?         // "tcg" | "sports"

  errorMessage:      String?
  createdAt:         Date
  updatedAt:         Date
}
```

**Lifecycle**:
1. On capture → insert ScanRecord (`status=pending`, `capturedImagePath` set)
2. `POST /identify` with base64 image → store `jobId` from `JobSubmitResponse`
3. Poll `GET /status/{jobId}` every 2s in background
4. On `complete` → populate all fields from `CardResponse`, set `status=complete`
5. On `failed` → set `errorMessage` from response, set `status=failed`
6. "Add to Collection" → convert ScanRecord fields → new CardRecord (§1.6), optionally remove from scan queue
7. CLEAR → delete all ScanRecords from current session

**Persistence**: SwiftData. On scanner open, last 3 ScanRecords loaded regardless of session.

### 1.6 Collection Data Model

```
CardRecord {
  id:                   UUID
  tcgplayer_product_id: String
  name:                 String
  set_name:             String
  set_code:             String
  number:               String
  rarity:               String
  variant:              String    // HOLO | FULL_ART | ALT_ART | STANDARD | etc
  game:                 String    // examprepmon | mtg | yugioh | lorcana
  tcgplayer_price:      Decimal
  ebay_price:           Decimal?
  price_updated_at:     Timestamp
  added_at:             Timestamp
  scan_image_url:       String?
  confidence_score:     Float     // 0.0–1.0
  is_graded:            Boolean
  grade_company:        String?
  grade_value:          String?
  notes:                String?
}
```

- Stored in local DB (SwiftData)
- `tcgplayer_price` updated on collection load + detail view (background, non-blocking)
- Multiple copies of same card supported (separate records)

### 1.7 Price Data

- TCGPlayer price via TCGPlayer Pricing API (product ID from identification)
- eBay: avg last 10 sold listings (same card+set+variant, 30 days)
- Cache: 15min per card per variant, key `{product_id}:{variant_code}`
- Always show timestamp: "Updated just now" / "Updated N min ago"

---

## M2 — Search

> Batch scanning is built into the main scanner (§1.1). No separate batch screen needed.

### 2.1 Search Screen

- Search bar: 34pt pill, placeholder "Search cards, sets, artists…", magnifying glass icon
- Cancel button when focused
- **Game filter chips**: All (default), Pokémon, MTG, YuGiOh, Lorcana (single-select)
- **Recent searches** (unfocused state): up to 5, clock icon + query + price + × dismiss
  - Stored locally, cleared only by user
- **Browse sets**: 2-col grid, 52pt tiles, dominant color bg, set name label
  - Sorted by release date (newest first), max 8 shown + "See all sets"
- **Autocomplete**: ≤200ms after keystroke (150ms debounce), up to 6 suggestions
  - Card name + set per row, top result highlighted blue
  - Local card name index first → API fallback
- **Results list**: thumbnail + name + set + rarity + price + "+Add" button
  - Top result highlighted `#EEF6FF`
  - Result count label above list
  - Sort: relevance default, Price High/Low via chip
- **Quick-add**: "+Add" per row → green ✓ for 1.5s → resets
  - Already in collection → "In collection ✓" (no-op)

### 2.2 Error Correction Screen

- Captured photo upper area
- "SELECT CORRECT CARD" section
- Up to 4 candidates ranked by confidence
  - Radio button + name + set/variant + price
  - Top candidate pre-selected
- "Confirm → [Card name]" → back to batch review w/ updated row
- "or search manually" link → search screen w/ scan image ref

---

## M3 — Polish & Retention

### 3.1 Search Filters

- Filter button opens bottom sheet
- Sections: Game (chips), Rarity (chips), Price range ($0–$500+ dual slider), Sort by
- "Apply filters" primary CTA, "Reset" clears all
- Active filter count badge on button

### 3.2 Job Loading Tiles

Reusable component, states matching §1.5 state machine:

| State | Icon | Pill | Key actions |
|---|---|---|---|
| Pending | clock | "Pending" | Cancel |
| Processing | spinner | "Processing" (pulsing) | — |
| Complete | check | "Done" | View detail, +Add |
| Failed | exclamation | "Failed" | Retry, Search manually |

- Compact (44pt) inline on collection screen
- Collection tile auto-dismiss 3s after Complete
- Multiple concurrent jobs supported

### 3.3 CSV Export

- "Export collection" via … overflow on collection screen
- Columns: Name, Set, Number, Rarity, Variant, Game, TCGPlayer Price, eBay Price, Date Added
- Native share sheet on iOS
- Free (not paywalled)
- Background thread for >1k cards w/ progress indicator

### 3.4 Offline Behaviour

- Collection readable offline (local cache)
- Scanning requires network; offline → banner "You're offline. Scans will queue when connection returns." + shutter disabled
- Offline scan queue: photos stored locally, auto-submit on reconnect
- Card name index bundled for offline autocomplete

### 3.5 Push Notifications

Permission prompt on first batch job submit. Only sent when app backgrounded (in-app banners otherwise).

| Trigger | Title | Body |
|---|---|---|
| Batch done | "Scan complete" | "10 cards · $286 total — tap to add" |
| Batch needs review | "1 card needs your help" | "Low confidence match · tap to fix" |
| Batch interrupted | "Scan interrupted" | "4 cards saved · 6 lost · tap to resume" |
| Single done | "Card identified" | "[Card name] · $[price] — tap to add" |

Deep-links open directly to relevant screen.

### 3.6 Barcode Scan + Torch

- Barcode scanning: "Coming soon" — not in v1
- Torch toggle (⚡) in scanner top bar (§1.1), persists per session, resets on background

---

## Non-Functional (All Milestones)

| Metric | Target |
|---|---|
| Camera live | ≤400ms |
| Card ID P50/P95 | ≤2s / ≤5s |
| Price fetch P50 | ≤1.5s |
| Collection render | ≤300ms (5k cards) |
| Autocomplete | ≤200ms |
| Cold start | ≤2s |
| ID accuracy (standard) | ≥95% |
| ID accuracy (holo) | ≥88% |
| Variant detection | ≥90% |
| Low-confidence threshold | <80% |
| Crash rate | <0.1% sessions |
| Min tap target | 44×44pt |
| WCAG AA contrast | required |
| VoiceOver | all elements |
| Dynamic Type | supported |

---

## Out of Scope (v1)

Price alerts, portfolio chart, TCGPlayer account sync, quick-sell flow, graded pricing, price/sales history tabs, Android, multi-language, dark mode, collection sharing, duplicate detection alerts.

---

## Open Questions

| # | Question | Affects |
|---|---|---|
| 1 | TCGPlayer API rate limit / allocation? | Prices |
| 2 | Confidence threshold 80% confirmed? | Flagging |
| 3 | Store scan image permanently or discard? | Storage/privacy |
| 4 | eBay sold avg server-side or client-side? | Price fetch |
| 5 | Max batch size? | Batch scan |
| 6 | Offline queue auto-submit or manual? | Offline |
| 7 | CSV include purchase price / cost basis? | Export |
