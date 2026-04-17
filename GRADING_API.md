# Grading API

AI-powered card condition grading. Analyzes centering, corners, edges, and surface to estimate PSA/BGS grade range.

## Endpoint

```
POST /grade
```

## Request

Content-Type: `application/json`

### Payload

```json
{
  "front_flat": { "base64": "<base64-encoded image>" },
  "back_flat": { "base64": "<base64-encoded image>" },
  "front_angled": { "base64": "<base64-encoded image>" },
  "corners_top": { "base64": "<base64-encoded image>" },
  "corners_bottom": { "base64": "<base64-encoded image>" },
  "edges": { "base64": "<base64-encoded image>" }
}
```

### Image Fields

| Field | Required | Description |
|-------|----------|-------------|
| `front_flat` | **Yes** | Front of card, phone held parallel above, card flat on dark surface |
| `back_flat` | **Yes** | Back of card, same position as front |
| `front_angled` | No | Front at ~45° angle so light catches surface scratches/indentations |
| `corners_top` | No | Close-up of top-left and top-right corners |
| `corners_bottom` | No | Close-up of bottom-left and bottom-right corners |
| `edges` | No | Close-up of card edges, card slightly tilted to show edge thickness |

### Photo Capture Guide (for iOS app)

#### 1. Front Flat (required)
- Place card on **dark, non-reflective surface**
- Hold phone **directly above**, parallel to card
- Ensure **even lighting**, no shadows or glare
- Card should fill ~80% of frame
- **Enables:** centering, corners, edges, surface (basic), print defects

#### 2. Back Flat (required)
- Flip card, same position
- Same lighting/distance as front
- **Enables:** back centering measurement

#### 3. Front Angled (optional, improves surface score)
- Keep card flat on surface
- Tilt phone to ~45° angle OR tilt card slightly
- Goal: light should **glance across surface** to reveal scratches
- **Enables:** scratch detection, indentation detection, fingerprint oils

#### 4. Corners Top (optional, improves corner score)
- Move phone close to top edge of card
- Both top-left and top-right corners should be visible
- Focus should be sharp on corner tips
- **Enables:** micro-fuzzing detection, corner whitening, dings

#### 5. Corners Bottom (optional, improves corner score)
- Same as above for bottom-left and bottom-right
- **Enables:** same as corners top

#### 6. Edges (optional, improves edge score)
- Tilt card slightly to show the **edge thickness**
- Capture at least 2 edges (top+bottom or left+right)
- **Enables:** edge whitening, chipping, rough cuts, peeling

## Response

```json
{
  "centering": {
    "score": 8.0,
    "notes": "Slightly off-center to the left on front",
    "defects": ["Front left/right: 58/42"],
    "front": { "left_right": "58/42", "top_bottom": "51/49" },
    "back": { "left_right": "52/48", "top_bottom": "50/50" }
  },
  "corners": {
    "score": 7.5,
    "notes": "Minor wear on top-left corner, others sharp",
    "defects": ["Light whitening on top-left corner"]
  },
  "edges": {
    "score": 9.0,
    "notes": "Clean edges, no whitening or chipping",
    "defects": []
  },
  "surface": {
    "score": 7.0,
    "notes": "Light scratch visible across center under angled light",
    "defects": ["Horizontal scratch across center", "Minor print line near bottom"]
  },
  "estimated_grade": {
    "psa_range": "6-8",
    "bgs_range": "7.4-8.4",
    "confidence": "medium"
  },
  "photos_provided": ["front_flat", "back_flat", "front_angled"],
  "photos_missing": ["corners_top", "corners_bottom", "edges"],
  "tips": [
    "Add corner close-ups for more accurate corner grading",
    "Add edge close-ups to detect whitening and chipping"
  ],
  "disclaimer": "AI estimate only. Submit to PSA/BGS for official grade."
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `centering` | CenteringScore | Centering analysis with front/back ratios |
| `corners` | CategoryScore | Corner sharpness and wear analysis |
| `edges` | CategoryScore | Edge whitening and chipping analysis |
| `surface` | CategoryScore | Surface scratches, print defects, staining |
| `estimated_grade.psa_range` | string | Estimated PSA grade range (e.g. "7-8") |
| `estimated_grade.bgs_range` | string | Estimated BGS grade range (e.g. "7.5-8.5") |
| `estimated_grade.confidence` | string | `low` (2 photos) / `medium` (3-4) / `high` (5-6) |
| `photos_provided` | string[] | Which photos were submitted |
| `photos_missing` | string[] | Which optional photos were not submitted |
| `tips` | string[] | Suggestions to improve grading accuracy |

### Confidence Levels

| Photos | Confidence | What's assessed |
|--------|-----------|-----------------|
| 2 (front + back only) | **low** | Centering (reliable), corners/edges/surface (from full card only) |
| 3-4 (+ angled or corners) | **medium** | Better surface or corner assessment |
| 5-6 (all photos) | **high** | All categories assessed with close-up detail |

### Grading Categories (1-10 scale)

Each category scored independently, matching PSA/BGS subcategories:

- **Centering:** Border ratio measurement. PSA 10 requires ≤60/40 front, ≤75/25 back.
- **Corners:** Sharpness, whitening, fuzzing, dings at all 4 corners.
- **Edges:** Whitening, chipping, rough cuts along all 4 edges.
- **Surface:** Scratches, print defects, staining, indentations, creases.

### Grade Calculation

- **PSA estimate:** Based on lowest subcategory score (PSA grades by weakest attribute)
- **BGS estimate:** Average of all 4 subcategory scores (BGS uses weighted average)
- Range of ±1 applied to account for AI assessment limitations

## Limitations

- Cannot detect micro-defects requiring 10x loupe magnification
- Surface scratch detection depends heavily on lighting in user's photo
- Indentation detection unreliable without controlled angled lighting
- Cannot distinguish PSA 9 from PSA 10 reliably
- Grading is an **estimate** — professional graders use controlled environments

## iOS Integration

### Swift Request Model

```swift
struct GradeImage: Codable {
    let base64: String
}

struct GradeRequest: Codable {
    let frontFlat: GradeImage
    let backFlat: GradeImage
    let frontAngled: GradeImage?
    let cornersTop: GradeImage?
    let cornersBottom: GradeImage?
    let edges: GradeImage?

    enum CodingKeys: String, CodingKey {
        case frontFlat = "front_flat"
        case backFlat = "back_flat"
        case frontAngled = "front_angled"
        case cornersTop = "corners_top"
        case cornersBottom = "corners_bottom"
        case edges
    }
}
```

### Swift Response Model

```swift
struct CategoryScore: Codable {
    let score: Double
    let notes: String
    let defects: [String]
}

struct CenteringDetail: Codable {
    let leftRight: String?
    let topBottom: String?

    enum CodingKeys: String, CodingKey {
        case leftRight = "left_right"
        case topBottom = "top_bottom"
    }
}

struct CenteringScore: Codable {
    let score: Double
    let notes: String
    let defects: [String]
    let front: CenteringDetail?
    let back: CenteringDetail?
}

struct GradeEstimate: Codable {
    let psaRange: String
    let bgsRange: String?
    let confidence: String

    enum CodingKeys: String, CodingKey {
        case psaRange = "psa_range"
        case bgsRange = "bgs_range"
        case confidence
    }
}

struct GradeResponse: Codable {
    let centering: CenteringScore
    let corners: CategoryScore
    let edges: CategoryScore
    let surface: CategoryScore
    let estimatedGrade: GradeEstimate
    let photosProvided: [String]
    let photosMissing: [String]
    let tips: [String]
    let disclaimer: String

    enum CodingKeys: String, CodingKey {
        case centering, corners, edges, surface
        case estimatedGrade = "estimated_grade"
        case photosProvided = "photos_provided"
        case photosMissing = "photos_missing"
        case tips, disclaimer
    }
}
```
