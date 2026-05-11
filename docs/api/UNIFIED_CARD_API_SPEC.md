# Unified Card Identification & API Spec

**Version:** 1.0  
**Last updated:** April 2026  
**Audience:** API team, ML team, iOS engineers  

> One API, two apps. TCG Scanner + SportScan share the same identification pipeline, data models, and endpoints. This doc defines the common models, Vision LLM extraction strategy, and API contract.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Common iOS Models](#2-common-ios-models)
3. [Vision LLM Identification Strategy](#3-vision-llm-identification-strategy)
4. [Card Characteristics Taxonomy](#4-card-characteristics-taxonomy)
5. [API Contract](#5-api-contract)
6. [Pricing Abstraction](#6-pricing-abstraction)
7. [Search & Catalog](#7-search--catalog)

---

## 1. Architecture Overview

```
┌──────────────┐     ┌──────────────┐
│  TCG Scanner │     │  SportScan   │
│   (iOS app)  │     │   (iOS app)  │
└──────┬───────┘     └──────┬───────┘
       │                    │
       └────────┬───────────┘
                │
         ┌──────▼──────┐
         │ Unified API  │
         │  /v1/scan    │
         │  /v1/price   │
         │  /v1/search  │
         │  /v1/catalog │
         └──────┬───────┘
                │
       ┌────────┼────────┐
       ▼        ▼        ▼
   ┌───────┐ ┌──────┐ ┌───────┐
   │Vision │ │Price │ │Card   │
   │LLM    │ │Agg.  │ │Catalog│
   └───────┘ └──────┘ └───────┘
```

Both apps send the same scan request. The API detects card domain (TCG vs Sports) automatically from the image, then routes to domain-specific enrichment. Response shape is identical — apps render domain-specific fields conditionally.

---

## 2. Common iOS Models

### 2.1 CardDomain (enum)

The top-level domain classifier. Detected by Vision LLM in first pass.

```swift
enum CardDomain: String, Codable {
    // TCG
    case isaprepmon
    case mtg
    case yugioh
    case lorcana
    case onepiece
    case digimon
    // Sports
    case basketball
    case football
    case baseball
    case hockey
    case soccer
    case mma
    case wrestling
    // Meta
    case unknown
}
```

### 2.2 CardCategory (enum)

```swift
enum CardCategory: String, Codable {
    case tcg
    case sports
    case unknown
}
```

### 2.3 UnifiedCard (core model — shared by both apps)

```swift
@Model
final class UnifiedCard {
    // === Identity ===
    var id: UUID
    var category: CardCategory          // tcg | sports
    var domain: CardDomain              // isaprepmon | basketball | etc
    
    // === Core fields (all cards) ===
    var name: String                    // Card title or player name
    var setName: String                 // "Scarlet & Violet 151" or "Panini Prizm"
    var setCode: String                 // "SV151" or "PRIZM23"
    var number: String                  // Card number in set
    var year: String                    // Release year
    var rarity: CardRarity
    var variant: CardVariant            // Structured variant info
    var language: CardLanguage
    var condition: CardCondition?       // If detectable
    
    // === Visual fingerprint ===
    var dominantColor: String?          // Hex, extracted from card art
    var layoutType: CardLayout          // portrait | landscape | oversized
    
    // === Pricing ===
    var prices: [PriceEntry]
    var priceUpdatedAt: Date?
    
    // === Grading ===
    var grading: GradingInfo?
    
    // === TCG-specific (nil for sports) ===
    var tcgMeta: TCGMetadata?
    
    // === Sports-specific (nil for TCG) ===
    var sportsMeta: SportsMetadata?
    
    // === Scan metadata ===
    var confidenceScore: Float          // 0.0–1.0
    var scanImageURL: String?
    var addedAt: Date
    var notes: String?
    
    // === External IDs (for marketplace linking) ===
    var externalIDs: [ExternalID]
}
```

### 2.4 CardRarity (enum)

```swift
enum CardRarity: String, Codable {
    // Common across TCG
    case common, uncommon, rare
    case holoRare, ultraRare, secretRare, specialArtRare
    case illustrationRare, hyperRare, trainerGallery
    // MTG-specific
    case mythicRare
    // Sports
    case base, insert, parallel, shortPrint, superShortPrint
    // Universal
    case promo
    case unknown
}
```

### 2.5 CardVariant (structured)

```swift
struct CardVariant: Codable {
    var type: VariantType
    var name: String                    // Human-readable: "Silver Prizm", "Full Art"
    var isNumbered: Bool                // /25, /99 etc
    var serialLimit: Int?               // 25, 99, null if unnumbered
    var isFirstEdition: Bool            // YuGiOh, some vintage
    var isReverseHolo: Bool
    var foilType: FoilType?
}

enum VariantType: String, Codable {
    // TCG variants
    case standard, holo, reverseHolo
    case fullArt, altArt, specialArtRare, goldRare
    case rainbowRare, texturedRare
    case vmax, vstar, ex, gx          // Pokemon mechanics
    // Sports variants
    case baseParallel, silverPrizm, goldPrizm
    case colorMatch, tiedye, shimmer
    case laserPrizm, neonGreen
    case camo, mojo, scope
    // Universal
    case numbered
    case promo
    case custom                        // Fallback w/ name field
    case unknown
}

enum FoilType: String, Codable {
    case none, standard, holo, reverseHolo, etched
    case prismatic, refractor, speckle, wave
    case cracked_ice, mosaic, shimmer
}
```

### 2.6 TCGMetadata (TCG-only fields)

```swift
struct TCGMetadata: Codable {
    var game: TCGGame                   // isaprepmon | mtg | yugioh | lorcana
    var cardType: TCGCardType           // creature | spell | trainer | etc
    var energyTypes: [String]?          // ["Fire", "Water"] for Pokemon
    var hp: Int?
    var stage: String?                  // "Stage 2", "VSTAR"
    var abilities: [String]?
    var weakness: String?
    var resistance: String?
    var retreatCost: Int?
    var artist: String?
    var flavorText: String?
    // MTG
    var manaCost: String?               // "{2}{R}{R}"
    var colors: [String]?              // ["Red"]
    var power: String?                  // "4"
    var toughness: String?              // "5"
    var typeLine: String?               // "Creature — Dragon"
    // YuGiOh
    var attribute: String?              // DARK, LIGHT, etc
    var level: Int?
    var attack: Int?
    var defense: Int?
}

enum TCGGame: String, Codable {
    case isaprepmon, mtg, yugioh, lorcana, onepiece, digimon
}

enum TCGCardType: String, Codable {
    case creature, spell, trainer, supporter, item, stadium, tool
    case monster, trap                  // YuGiOh
    case character, action, song        // Lorcana
    case unknown
}
```

### 2.7 SportsMetadata (Sports-only fields)

```swift
struct SportsMetadata: Codable {
    var sport: Sport
    var playerName: String
    var teamName: String?
    var position: String?               // "PG", "QB", "CF"
    var brand: CardBrand                // panini | topps | upper_deck
    var isRookie: Bool                  // RC designation
    var isAutograph: Bool               // Sticker auto, on-card auto
    var autographType: AutoType?
    var isMemorabilia: Bool             // Patch, jersey, relic
    var memorabiliaType: MemoType?
    var jerseyNumber: String?           // If visible on card
    var draftYear: String?
    var draftPick: String?
}

enum Sport: String, Codable {
    case basketball, football, baseball, hockey, soccer, mma, wrestling
}

enum CardBrand: String, Codable {
    case panini, topps, upperDeck, bowman, leaf, sage, futera, fanatics
}

enum AutoType: String, Codable {
    case stickerAuto, onCardAuto, cutSignature, unknown
}

enum MemoType: String, Codable {
    case jerseyPatch, playerWornJersey, eventUsedBall
    case multiColorPatch, logoPatch, tagPatch
    case relic, unknown
}
```

### 2.8 PriceEntry (unified pricing)

```swift
struct PriceEntry: Codable {
    var source: PriceSource
    var value: Decimal
    var currency: String                // "USD"
    var label: String                   // "Market", "Low", "Mid"
    var tier: PriceTier                 // raw | graded
    var gradeLabel: String?             // "PSA 10" if tier == graded
    var updatedAt: Date
    var sourceURL: String?              // Deep-link to listing
}

enum PriceSource: String, Codable {
    // TCG
    case tcgplayer, cardmarket
    // Sports
    case comc, oneThirtyPoint
    // Shared
    case ebay
    // Blended
    case marketEstimate
}

enum PriceTier: String, Codable {
    case raw, graded
}
```

### 2.9 GradingInfo

```swift
struct GradingInfo: Codable {
    var isGraded: Bool
    var company: GradeCompany?
    var grade: String?                  // "10", "9.5"
    var certNumber: String?             // PSA cert # (scannable)
    var subgrades: [String: String]?    // BGS: {"centering": "9.5", "edges": "10"}
}

enum GradeCompany: String, Codable {
    case psa, bgs, sgc, cgc, ace, unknown
}
```

### 2.10 ExternalID (marketplace linking)

```swift
struct ExternalID: Codable {
    var source: String                  // "tcgplayer", "comc", "ebay", "cardmarket"
    var productID: String               // External product/listing ID
    var url: String?                    // Direct product URL
}
```

---

## 3. Vision LLM Identification Strategy

### 3.1 Two-Pass Architecture

The Vision LLM runs two passes on every scanned image. This ensures domain detection happens first, then domain-specific extraction follows with a tailored prompt.

```
Image → Pass 1 (Classification) → Pass 2 (Extraction) → Structured Output
         ~200ms                     ~1.5s
```

**Pass 1 — Classification (fast, cheap model)**

Determines: category (TCG vs Sports), domain (isaprepmon vs basketball), and basic card orientation. This routes the image to the correct Pass 2 prompt.

**Pass 2 — Full Extraction (capable model)**

Extracts all metadata fields using a domain-specific prompt. Returns structured JSON matching `UnifiedCard`.

### 3.2 Pass 1 — Classification Prompt

```
You are a trading card classifier. Given this image of a card, determine:

1. category: "tcg" or "sports" or "unknown"
2. domain: one of [isaprepmon, mtg, yugioh, lorcana, onepiece, digimon, 
   basketball, football, baseball, hockey, soccer, mma, wrestling, unknown]
3. orientation: "portrait" or "landscape"
4. is_graded: true/false (is the card in a grading slab?)
5. confidence: 0.0–1.0

Classification signals:
- TCG cards have game logos (Pokéball, MTG planeswalker symbol, YuGiOh eye)
- Sports cards show real human athletes in team uniforms
- Pokemon: yellow border (vintage), silver/black border (modern), HP top-right
- MTG: black border, mana symbols, type line below art
- YuGiOh: eye of Anubis hologram, ATK/DEF bottom, attribute icon top-right
- Sports: player photo, team logo, brand logo (Panini, Topps), stats on back
- Graded: card enclosed in hard plastic slab w/ label at top

Return JSON only.
```

### 3.3 Pass 2 — TCG Extraction Prompt

```
You are a TCG card identification expert. Extract ALL metadata from this 
{domain} card image. Be extremely precise about variant/rarity — price 
differences between variants can be 100x.

Extract:
{
  "name": "Card name exactly as printed",
  "set_name": "Full set name",
  "set_code": "Set abbreviation/code if visible",
  "number": "Card number (e.g. '006/165', 'SV049')",
  "year": "Release year",
  "rarity": "See rarity list below",
  "language": "en/ja/ko/zh/fr/de/es/it/pt",
  
  "variant": {
    "type": "See variant type list",
    "name": "Human-readable variant name",
    "is_numbered": true/false,
    "serial_limit": null or number,
    "is_first_edition": true/false,
    "is_reverse_holo": true/false,
    "foil_type": "See foil list"
  },

  "tcg_meta": {
    "card_type": "creature|spell|trainer|supporter|item|stadium|monster|trap",
    "energy_types": ["Fire"] or null,
    "hp": 330 or null,
    "stage": "Basic|Stage 1|Stage 2|VSTAR|VMAX|ex" or null,
    "artist": "Artist name if visible",
    "mana_cost": "{2}{R}" (MTG only),
    "colors": ["Red"] (MTG only),
    "attribute": "DARK" (YuGiOh only),
    "level": 8 (YuGiOh only),
    "attack": 3000 (YuGiOh only),
    "defense": 2500 (YuGiOh only)
  },

  "grading": {
    "is_graded": true/false,
    "company": "psa|bgs|sgc|cgc" or null,
    "grade": "10" or null,
    "cert_number": "12345678" or null
  },

  "confidence": 0.0–1.0,
  "confidence_breakdown": {
    "name": 0.95,
    "set": 0.90,
    "variant": 0.85,
    "number": 0.92
  }
}

=== CRITICAL VISUAL SIGNALS (TCG) ===

POKEMON variant detection:
- Standard: solid color border, no special texture
- Holo: art area has holographic shimmer/rainbow reflection
- Reverse holo: card FRAME (not art) has holo pattern, art is flat
- Full Art: art extends to card edges, no standard border
- Alt Art: alternate illustration, usually extends to edges, unique composition
- Special Art Rare (SAR): textured, extends to edges, premium illustration
- Gold Rare: gold-colored card border and body
- Rainbow Rare: rainbow gradient across entire card
- Textured: visible texture/embossing (zoom artifacts in photo)
- VMAX/VSTAR/ex: labeled on card, specific border treatments
- Trainer Gallery: "TG" prefix in card number

MTG variant detection:
- Regular: standard black border
- Foil: rainbow light reflection across card face
- Etched foil: subtle, matte holographic on art only
- Extended art: art bleeds to left/right edges
- Borderless: no black border, art fills entire card
- Showcase: alternate frame treatment (varies by set)
- Retro frame: old-style frame on modern card

YUGIOH variant detection:
- Common/Rare: name in black/silver/gold text
- Super Rare: holo art
- Ultra Rare: gold name + holo art  
- Secret Rare: prismatic/diagonal pattern on entire card
- Ghost Rare: faint 3D-effect art
- Starlight Rare: subtle prismatic across full card, very distinct
- 1st Edition: "1st Edition" text below-left of art box
- Limited Edition: "Limited Edition" text

RARITY SYMBOLS (bottom-right of Pokemon cards):
- Circle = Common
- Diamond = Uncommon  
- Star = Rare
- Star + H = Holo Rare
- Multiple stars = Ultra Rare+

Return JSON only. If uncertain about any field, include it with your best 
guess and set the per-field confidence accordingly.
```

### 3.4 Pass 2 — Sports Extraction Prompt

```
You are a sports card identification expert. Extract ALL metadata from this 
{sport} card image. Be extremely precise about parallel/variant — a base 
card might be $0.50 while a Gold /10 parallel is $500.

Extract:
{
  "name": "Card title as printed (may differ from player name)",
  "player_name": "Athlete full name",
  "team_name": "Team name if visible",
  "position": "Position abbreviation",
  "set_name": "Full product name (e.g. '2023-24 Panini Prizm')",
  "set_code": "Abbreviated code",
  "number": "Card number",
  "year": "Product release year",
  "sport": "basketball|football|baseball|hockey|soccer|mma|wrestling",
  "brand": "panini|topps|upper_deck|bowman|leaf|sage|fanatics",
  "rarity": "base|insert|parallel|short_print|super_short_print",
  "language": "en|ja|etc",

  "variant": {
    "type": "See parallel type list",
    "name": "Human-readable: 'Silver Prizm', 'Gold /10'",
    "is_numbered": true/false,
    "serial_limit": null or number,
    "foil_type": "See foil list"
  },

  "sports_meta": {
    "is_rookie": true/false,
    "is_autograph": true/false,
    "autograph_type": "sticker_auto|on_card_auto|cut_signature" or null,
    "is_memorabilia": true/false,
    "memorabilia_type": "jersey_patch|player_worn_jersey|logo_patch|relic" or null,
    "jersey_number": "23" or null,
    "draft_year": "2003" or null,
    "draft_pick": "1" or null
  },

  "grading": {
    "is_graded": true/false,
    "company": "psa|bgs|sgc|cgc" or null,
    "grade": "10" or null,
    "cert_number": "12345678" or null,
    "subgrades": {"centering": "9.5", "edges": "10"} or null
  },

  "confidence": 0.0–1.0,
  "confidence_breakdown": {
    "player": 0.95,
    "set": 0.88,
    "parallel": 0.82,
    "number": 0.90
  }
}

=== CRITICAL VISUAL SIGNALS (SPORTS) ===

ROOKIE DETECTION:
- "RC" logo/badge printed on card face (usually bottom-left or top-right)
- "Rookie" text in card title or designation area
- First-year player appearance in a major product
- Rookie cards are 10-100x more valuable — MUST detect accurately

AUTOGRAPH DETECTION:
- Sticker auto: small signed sticker affixed to card surface (visible edges)
- On-card auto: signature written directly on card surface (no sticker edges)
- Cut signature: vintage/deceased player signature on paper piece embedded in card
- "AUTO" or "Autograph" text often printed on card
- Ink color varies: blue, black, gold, red, green

MEMORABILIA/PATCH DETECTION:
- Rectangular window cut into card with fabric/material visible
- Single-color jersey: solid color swatch
- Multi-color patch: multiple fabric colors visible
- Logo patch: team logo or part of logo visible in swatch
- Tag patch: manufacturer tag visible
- "PATCH", "JERSEY", "RELIC", "MEMORABILIA" text on card

PARALLEL DETECTION (critical — look at card BORDER and BACKGROUND):

Panini Prizm parallels:
- Base: standard silver/white border
- Silver Prizm: subtle silver refractor shimmer
- Red/White/Blue: colored border bands
- Gold Prizm: gold border, usually /10
- Green Prizm: green-tinted border
- Black Prizm: black border, usually /1
- Neon Green: bright neon green border
- Tiger Stripe: orange/black striped pattern
- Mojo: pixelated/mosaic refractor pattern
- Camo: camouflage pattern on border
- Snakeskin: snakeskin texture pattern
- Color Blast: rainbow splatter pattern (extremely rare)

Topps Chrome parallels:
- Base: standard chrome finish
- Refractor: rainbow refraction on surface
- Gold Refractor: gold-tinted, /50
- Red Refractor: red-tinted
- Superfractor: gold mirror, /1
- Xfractor: X-pattern refractor
- Prism Refractor: prismatic pattern
- Speckle Refractor: speckled pattern

Numbered cards:
- Look for "/ XX" stamped on card (e.g., "12/25" means card 12 of 25 made)
- Common serial limits: /1, /5, /10, /25, /35, /50, /75, /99, /149, /199, /299, /499

BRAND IDENTIFICATION:
- Panini: "PANINI" text, shield logo, Prizm/Select/Mosaic/Optic product lines
- Topps: "TOPPS" text, Topps logo, Chrome/Heritage/Stadium Club lines
- Upper Deck: "UPPER DECK" text, UD logo, SP Authentic/Exquisite lines
- Bowman: "BOWMAN" text (Topps subsidiary, primarily baseball prospects)
- Fanatics: "FANATICS" (new, taking over from Topps/Panini for some leagues)

Return JSON only. If uncertain about any field, include it with your best 
guess and set the per-field confidence accordingly.
```

### 3.5 Confidence Scoring Strategy

```
Overall confidence = weighted avg of per-field confidences:

TCG weights:
  name:    0.30   (wrong name = completely wrong card)
  set:     0.25   (wrong set = wrong price)
  variant: 0.25   (wrong variant = wrong price tier)
  number:  0.20   (confirms identity)

Sports weights:
  player:   0.30
  set:      0.20
  parallel: 0.30  (higher weight — parallels drive most price variance)
  number:   0.20

Threshold: <0.80 overall → flag for review
Per-field: any field <0.60 → flag that specific field
```

### 3.6 Difficult Cases & Disambiguation

| Scenario | Strategy |
|---|---|
| Card in sleeve/toploader | Glare detection → ask user to remove or reposition |
| Card in grading slab | Detect slab first → read label for metadata → fall back to card image |
| Foreign language card | Detect language in Pass 1 → use language-specific prompt variant |
| Same player, multiple years | Extract year from set name, copyright line, or card design era |
| Same card, different parallel | Compare border color/pattern against known parallel color map |
| Damaged/worn card | Lower confidence, still attempt ID → flag condition |
| Token/promo/misprint | Detect non-standard layout → flag as "custom" variant |
| Card back only | Detect back → return domain only (Pokemon/MTG/etc), prompt to flip |
| Multiple cards in frame | Detect most centered card, ignore others (single scan mode) |
| Counterfeit signals | NOT in scope for v1 — do not flag, do not claim auth |

---

## 4. Card Characteristics Taxonomy

### 4.1 Universal Characteristics (all cards)

| Characteristic | Where to look | Why it matters |
|---|---|---|
| Card name/title | Top of card face | Primary identity |
| Set name | Bottom, logo, or border design | Determines price pool |
| Card number | Bottom-left/right | Confirms exact card |
| Year | Copyright line, set context | Disambiguates reprints |
| Rarity | Symbol (TCG) or print run (Sports) | Affects price 10-100x |
| Variant/parallel | Border color, texture, foil pattern | Affects price 10-1000x |
| Language | Text, set symbol region variant | Different markets |
| Condition | Surface wear, whitening, centering | Affects price 2-10x |
| Grading slab | Plastic enclosure, label | Confirms grade, affects price |
| Numbering | Stamped serial (e.g. /99) | Scarcity = value |
| First edition | Stamp/text | Vintage premium |

### 4.2 TCG-Specific Characteristics

| Characteristic | Where to look | Games |
|---|---|---|
| HP / Power-Toughness / ATK-DEF | Top-right or bottom | All TCGs |
| Energy/Mana/Attribute type | Symbols on card | Pokemon/MTG/YuGiOh |
| Card type (creature/spell/etc) | Type line | All TCGs |
| Stage/evolution | Above card name | Pokemon |
| Artist name | Bottom of card | Pokemon/MTG |
| Holo pattern type | Art area reflection | Pokemon/MTG/YuGiOh |
| Reverse holo | Frame reflection (not art) | Pokemon |
| Texture/embossing | Surface relief | Premium Pokemon/MTG |
| Set symbol | Right of type line (MTG), bottom (Pokemon) | All TCGs |
| Collector number format | Bottom, e.g. "SV049/SV050" | All TCGs |
| Regulation mark | Bottom-left letter (D, E, F, G, H) | Pokemon (era indicator) |

### 4.3 Sports-Specific Characteristics

| Characteristic | Where to look | Why it matters |
|---|---|---|
| Player name | Card face, usually prominent | Primary identity |
| Team name/logo | Jersey, card design, text | Confirms player era |
| Jersey number | Player photo or card text | Cross-reference |
| Position | Card text, usually abbreviated | Metadata |
| Brand/manufacturer | Logo, text, card back | Determines product line |
| Product line | Card design (Prizm vs Select vs Mosaic) | Determines parallel map |
| Rookie designation (RC) | RC logo/badge on card | 10-100x price multiplier |
| Autograph | Sticker or on-card signature | 5-50x price multiplier |
| Auto ink color | Signature color | Some colors rarer |
| Memorabilia window | Fabric/material visible in card | 3-20x price multiplier |
| Patch quality | Single-color vs multi-color vs logo | Logo patches 5-10x multi-color |
| Serial number | Stamped /XX | Scarcity multiplier |
| Parallel border color | Card border/frame color | Determines exact parallel |
| Refractor pattern | Light reflection pattern | Distinguishes chrome variants |
| Case hit indicator | "CASE HIT", "SSP" text | Extreme rarity |
| Draft class info | Text on card | Confirms player timeline |

---

## 5. API Contract

### 5.1 POST /v1/scan

Submit an image for identification.

**Request:**
```json
{
  "image": "<base64 or multipart>",
  "hint_category": "tcg" | "sports" | null,
  "hint_domain": "isaprepmon" | "basketball" | null,
  "mode": "single" | "batch",
  "client": "tcg_scanner" | "sport_scan"
}
```

`hint_category` and `hint_domain` are optional. If the user is in TCG Scanner app, pass `hint_category: "tcg"` to skip Pass 1 classification and save ~200ms.

**Response:**
```json
{
  "job_id": "uuid",
  "status": "processing" | "done" | "needs_review" | "failed",
  "cards": [
    {
      "card_id": "uuid",
      "category": "tcg",
      "domain": "isaprepmon",
      "name": "Charizard ex",
      "set_name": "Scarlet & Violet 151",
      "set_code": "SV151",
      "number": "006/165",
      "year": "2023",
      "rarity": "ultra_rare",
      "language": "en",
      "variant": {
        "type": "special_art_rare",
        "name": "Special Art Rare",
        "is_numbered": false,
        "serial_limit": null,
        "is_first_edition": false,
        "is_reverse_holo": false,
        "foil_type": "standard"
      },
      "tcg_meta": { ... },
      "sports_meta": null,
      "grading": null,
      "confidence": 0.93,
      "confidence_breakdown": {
        "name": 0.97,
        "set": 0.95,
        "variant": 0.88,
        "number": 0.92
      },
      "external_ids": [
        { "source": "tcgplayer", "product_id": "489201", "url": "https://..." }
      ],
      "candidates": []
    }
  ]
}
```

When `confidence < 0.80`, `candidates` is populated with up to 4 alternatives:

```json
"candidates": [
  {
    "name": "Charizard ex",
    "set_name": "Scarlet & Violet 151",
    "variant": { "type": "holo", "name": "Holo" },
    "confidence": 0.72,
    "external_ids": [...]
  },
  { ... }
]
```

### 5.2 GET /v1/scan/{job_id}

Poll job status (or use WebSocket at `wss://api/v1/scan/{job_id}/ws`).

**Response:** same shape as POST /v1/scan response, with updated `status` and `cards` array.

### 5.3 POST /v1/price

Fetch prices for a card.

**Request:**
```json
{
  "external_ids": [
    { "source": "tcgplayer", "product_id": "489201" }
  ],
  "name": "Charizard ex",
  "set_code": "SV151",
  "variant_type": "special_art_rare",
  "category": "tcg",
  "domain": "isaprepmon",
  "include_graded": false
}
```

**Response:**
```json
{
  "prices": [
    {
      "source": "tcgplayer",
      "value": 84.50,
      "currency": "USD",
      "label": "Market",
      "tier": "raw",
      "grade_label": null,
      "updated_at": "2026-04-04T12:00:00Z",
      "source_url": "https://..."
    },
    {
      "source": "ebay",
      "value": 79.00,
      "currency": "USD",
      "label": "Sold Avg (30d)",
      "tier": "raw",
      "updated_at": "2026-04-04T12:00:00Z"
    },
    {
      "source": "market_estimate",
      "value": 82.00,
      "currency": "USD",
      "label": "Blended Estimate",
      "tier": "raw",
      "updated_at": "2026-04-04T12:00:00Z"
    }
  ],
  "cache_ttl_seconds": 900
}
```

Price sources by app:

| Source | TCG Scanner | SportScan |
|---|---|---|
| TCGPlayer | Primary | — |
| eBay sold avg | Secondary | Primary |
| Cardmarket | Supplemental (EU) | — |
| COMC | — | Secondary |
| 130point | — | Supplemental |
| Blended estimate | Always | Always |

### 5.4 GET /v1/search

**Request:**
```
GET /v1/search?q=charizard&category=tcg&domain=isaprepmon&limit=20&offset=0
    &sort=relevance&rarity=ultra_rare&price_min=10&price_max=500
```

**Response:**
```json
{
  "total": 142,
  "results": [
    {
      "name": "Charizard ex",
      "set_name": "Scarlet & Violet 151",
      "set_code": "SV151",
      "number": "006/165",
      "year": "2023",
      "rarity": "ultra_rare",
      "variant": { ... },
      "category": "tcg",
      "domain": "isaprepmon",
      "price_snapshot": {
        "value": 84.50,
        "source": "tcgplayer",
        "updated_at": "2026-04-04T12:00:00Z"
      },
      "external_ids": [...]
    }
  ]
}
```

### 5.5 GET /v1/search/autocomplete

**Request:**
```
GET /v1/search/autocomplete?q=chariz&category=tcg&limit=6
```

**Response:**
```json
{
  "suggestions": [
    { "text": "Charizard ex", "set": "SV151", "domain": "isaprepmon" },
    { "text": "Charizard VMAX", "set": "SWSH04", "domain": "isaprepmon" },
    ...
  ]
}
```

### 5.6 GET /v1/catalog/sets

```
GET /v1/catalog/sets?category=tcg&domain=isaprepmon&sort=release_date&limit=20
```

**Response:**
```json
{
  "sets": [
    {
      "set_code": "SV151",
      "set_name": "Scarlet & Violet 151",
      "year": "2023",
      "domain": "isaprepmon",
      "category": "tcg",
      "card_count": 207,
      "dominant_color": "#E53E3E",
      "release_date": "2023-09-22"
    }
  ]
}
```

---

## 6. Pricing Abstraction

Both apps use the same `PriceEntry` model. The API handles source routing internally:

```
Client sends: category + domain + external_ids
API resolves: which price sources to query
API returns:  unified PriceEntry[] regardless of source
```

Price source priority by domain:

| Domain | Primary | Secondary | Supplemental |
|---|---|---|---|
| isaprepmon | TCGPlayer | eBay | Cardmarket |
| mtg | TCGPlayer | Cardmarket | eBay |
| yugioh | TCGPlayer | eBay | Cardmarket |
| lorcana | TCGPlayer | eBay | Cardmarket |
| basketball | eBay | COMC | 130point |
| football | eBay | COMC | 130point |
| baseball | eBay | COMC | 130point |
| hockey | eBay | COMC | 130point |
| soccer | eBay | COMC | Cardmarket |

The client never decides which source to call — the API does. Client just renders whatever `PriceEntry[]` comes back, highlighting the first entry as authoritative.

---

## 7. Search & Catalog

### 7.1 Unified Card Catalog

The backend maintains a single card catalog indexed for search. Structure:

```
catalog_card {
  catalog_id:     UUID
  category:       tcg | sports
  domain:         isaprepmon | basketball | ...
  name:           String (searchable)
  player_name:    String? (sports, searchable)
  set_name:       String (searchable)
  set_code:       String
  number:         String
  year:           String
  rarity:         String
  variant_type:   String
  variant_name:   String
  brand:          String? (sports)
  external_ids:   JSONB
  search_vector:  tsvector (full-text)
}
```

Both apps query the same `/v1/search` endpoint. The `category` param filters to the relevant domain.

### 7.2 Local Card Index (Offline Autocomplete)

Each app ships a bundled SQLite DB of card names for offline autocomplete:

- **TCG Scanner**: ~500k cards (all Pokemon + MTG + YuGiOh + Lorcana)
- **SportScan**: ~800k cards (all major sports, 2000–present)

Index schema (minimal, for name matching only):
```
local_card_index {
  name:       TEXT
  set_code:   TEXT
  domain:     TEXT
  year:       TEXT
}
```

Updated monthly via background app refresh.

---

## Open Questions

| # | Question | Affects |
|---|---|---|
| 1 | Which Vision LLM? (GPT-4o, Claude, Gemini, custom fine-tune) | Latency, cost, accuracy |
| 2 | On-device vs cloud inference for Pass 1 classification? | Offline capability, latency |
| 3 | How to handle cards not yet in catalog (new releases)? | Search, ID |
| 4 | Rate limits per price source API? | Pricing |
| 5 | WebSocket vs polling for job status? | Real-time UX |
| 6 | Card catalog update frequency? | Data freshness |
| 7 | Image preprocessing (crop, deskew, enhance) before LLM? | Accuracy |
| 8 | Batch scan: server-side multi-card detection or client-side crop? | Architecture |
