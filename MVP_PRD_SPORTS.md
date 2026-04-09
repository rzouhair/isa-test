# SportScan — MVP PRD

**Version:** 1.0 MVP  
**Last updated:** April 2026  

> Only scanner built on multi-source sports card pricing. Core job: *"Tell me what my sports cards are worth, fast."*

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
- Variant/parallel detection (RC, auto, patch, prizm, numbered, etc.) handled server-side by API. Client sends raw image only.

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
| Identified | 48×64pt card image (from API `images.small`, rounded 4pt). Variant-count badge bottom-left (e.g. "1/2", "1/6" — blue `#3B82F6` bg, white text, 9pt, rounded). | **Line 1**: SET NAME (9pt, caps, gray `#9CA3AF`, e.g. "PANINI PRIZM") | **Line 2**: Year PlayerName #Number (11pt, white, semibold, e.g. "2024 LeBron James #1") | **Line 3**: "EST VALUE" label (9pt, gray) + **$X.XX** (12pt, bold, green `#16A34A` — from `pricing.marketPrice`) | "＋ADD" button (green `#16A34A` outline border, "+" icon + "ADD" label, 44×44pt tap target) |
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
- Each row: 28×38pt color thumbnail, player name (11pt/500), year+set+parallel (9pt), price (12pt/600, green)
- Tap row → card detail
- Real-time update when card added via scan
- **Portfolio summary strip**: total cards, total value (sum eBay sold avg), distinct sets
- Recompute on foreground + each list load
- **Sort** (action sheet): Value high→low (default), Value low→high, Date added new→old, Date added old→new, Player A-Z, Set, Sport
  - Sort preference persists locally
  - Client-side, no network call

### 1.4 Card Detail Screen

- Card image full-width (140pt, dark bg)
- Player name, year, set, number, parallel, variant badge
- Prices tab (default): rows for `marketPrice`, `lowestPrice`, `medianPrice` from API. eBay row highlighted w/ "LIVE" green pill.
- Prices fetched fresh; cached <15min shown w/ "Last updated X min ago"
- Confidence from `metadata.confidence` — shown as badge if <80% (amber)
- "View on eBay ↗" opens SFSafariViewController w/ pre-filled search for exact card
- "View on COMC ↗" opens product page via `product.url` if platform=buysportscards
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
  game:              String?
  sport:             String?         // basketball | football | baseball | hockey | soccer
  playerName:        String?
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
  player_name:          String        // "LeBron James"
  year:                 String        // "2023"
  set_name:             String        // "Panini Prizm"
  set_code:             String        // "PRIZM23"
  number:               String        // "1"
  sport:                String        // basketball | football | baseball | hockey | soccer
  brand:                String        // panini | topps | upper_deck | bowman
  parallel:             String        // "Silver Prizm" | "Base" | "Gold /10" | etc
  variant:              String        // BASE | RC | AUTO | PATCH | NUMBERED | REFRACTOR | etc
  is_rookie:            Boolean       // true if rookie card
  is_auto:              Boolean       // true if autographed
  is_memorabilia:       Boolean       // true if patch/jersey/relic
  serial_numbered:      Int?          // /25, /50, /99, null if unnumbered
  ebay_sold_price:      Decimal       // avg last 10 eBay sold (authoritative)
  comc_price:           Decimal?      // COMC market price
  price_updated_at:     Timestamp
  added_at:             Timestamp
  scan_image_url:       String?
  confidence_score:     Float         // 0.0–1.0
  is_graded:            Boolean
  grade_company:        String?       // PSA | BGS | SGC | CGC
  grade_value:          String?       // "PSA 10" | "BGS 9.5" | null
  notes:                String?
}
```

- Stored in local DB (SwiftData)
- `ebay_sold_price` updated on collection load + detail view (background, non-blocking)
- Multiple copies of same card supported (separate records)

### 1.7 Price Data

- eBay sold avg: last 10 sold listings (same card+year+set+parallel, 30 days) — primary/authoritative
- COMC: market price via COMC product ID when available
- 130point.com data as supplemental blended estimate
- Cache: 15min per card per variant, key `{card_hash}:{parallel_code}`
- Always show timestamp: "Updated just now" / "Updated N min ago"
- Graded vs raw price distinction: if card detected as graded, fetch graded comps separately

---

## M2 — Search

> Batch scanning is built into the main scanner (§1.1). No separate batch screen needed.

### 2.1 Search Screen

- Search bar: 34pt pill, placeholder "Search players, sets, years…", magnifying glass icon
- Cancel button when focused
- **Sport filter chips**: All (default), Basketball, Football, Baseball, Hockey, Soccer (single-select)
- **Recent searches** (unfocused state): up to 5, clock icon + query + price + × dismiss
  - Stored locally, cleared only by user
- **Browse sets**: 2-col grid, 52pt tiles, dominant color bg, set name + year label
  - Sorted by release date (newest first), max 8 shown + "See all sets"
- **Autocomplete**: ≤200ms after keystroke (150ms debounce), up to 6 suggestions
  - Player name + year + set per row, top result highlighted blue
  - Local card name index first → API fallback
- **Results list**: thumbnail + player name + year/set + parallel + price + "+Add" button
  - Top result highlighted `#EEF6FF`
  - Result count label above list
  - Sort: relevance default, Price High/Low via chip
- **Quick-add**: "+Add" per row → green ✓ for 1.5s → resets
  - Already in collection → "In collection ✓" (no-op)

### 2.2 Error Correction Screen

- Captured photo upper area
- "SELECT CORRECT CARD" section
- Up to 4 candidates ranked by confidence
  - Radio button + player name + year/set/parallel + price
  - Top candidate pre-selected
- "Confirm → [Card name]" → back to batch review w/ updated row
- "or search manually" link → search screen w/ scan image ref

---

## M3 — Polish & Retention

### 3.1 Search Filters

- Filter button opens bottom sheet
- Sections: Sport (chips), Brand (Panini, Topps, Upper Deck, Bowman), Parallel type (Base, Silver, Gold, Numbered), Rookie only toggle, Auto only toggle, Price range ($0–$500+ dual slider), Year range, Sort by
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
- Columns: Player, Year, Set, Number, Sport, Brand, Parallel, Variant, Rookie, Auto, Memo, Serial #, eBay Price, COMC Price, Grade, Date Added
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
| Single done | "Card identified" | "[Player name] · $[price] — tap to add" |

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
| ID accuracy (auto/patch) | ≥88% |
| Parallel detection | ≥90% |
| Low-confidence threshold | <80% |
| Crash rate | <0.1% sessions |
| Min tap target | 44×44pt |
| WCAG AA contrast | required |
| VoiceOver | all elements |
| Dynamic Type | supported |

---

## Sports Card–Specific Considerations

- **Parallel complexity**: sports cards have 20-50+ parallels per set (base, silver, gold, red, blue, green, numbered /25 /10 /5 /1, etc.) — AI model must distinguish color borders and numbering
- **Rookie detection critical**: RC designation dramatically affects price (10-100x). Must detect RC logo/badge on card face
- **Auto/Memo detection**: autograph cards and memorabilia/patch cards have distinct visual patterns (sticker auto, on-card auto, jersey swatch, patch swatch) — each priced differently
- **Multi-sport sets**: some sets (e.g. Leaf, Sage) span multiple sports — sport classification must be per-card not per-set
- **Grading premium**: graded sports cards (PSA 10, BGS 9.5) command massive premiums — show raw vs graded price when detected
- **Year matters**: unlike TCG, a 2023 vs 2024 version of the same player in the same set line are completely different products

---

## Out of Scope (v1)

Price alerts/watchlist, portfolio value-over-time chart, marketplace account sync, quick-sell flow, full graded pricing tiers (PSA 1-10), price history tab, sales history tab, Android, multi-language, dark mode, collection sharing, duplicate detection alerts, wax/box break tracking, player performance correlation.

---

## Open Questions

| # | Question | Affects |
|---|---|---|
| 1 | eBay API rate limits / affiliate access for sold data? | Prices |
| 2 | COMC API availability / partnership? | Prices |
| 3 | Confidence threshold 80% confirmed for sports cards? (more parallels = harder) | Flagging |
| 4 | Store scan image permanently or discard? | Storage/privacy |
| 5 | Max batch size? | Batch scan |
| 6 | Offline queue auto-submit or manual? | Offline |
| 7 | CSV include purchase price / cost basis for tax? | Export |
| 8 | Which sports card DB for base catalog? (e.g. Beckett, CardboardConnection, custom) | Search/ID |
| 9 | How to handle same-player same-set different-year disambiguation? | AI model |
| 10 | Panini losing NBA/NFL licenses 2025+ — how to handle brand transitions? | Catalog |
