import Foundation

// MARK: - Request

struct GradeImagePayload: Codable {
    let base64: String
}

struct GradeRequest: Codable {
    let frontFlat: GradeImagePayload
    let backFlat: GradeImagePayload
    let frontAngled: GradeImagePayload?
    let cornersTop: GradeImagePayload?
    let cornersBottom: GradeImagePayload?
    let edges: GradeImagePayload?

    enum CodingKeys: String, CodingKey {
        case frontFlat = "front_flat"
        case backFlat = "back_flat"
        case frontAngled = "front_angled"
        case cornersTop = "corners_top"
        case cornersBottom = "corners_bottom"
        case edges
    }
}

// MARK: - Response

struct GradeResponse: Codable {
    let centering: CenteringResult
    let corners: SubgradeResult
    let edges: SubgradeResult
    let surface: SubgradeResult
    let estimatedGrade: EstimatedGrade
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

struct SubgradeResult: Codable {
    let score: Double
    let notes: String
    let defects: [String]
}

struct CenteringResult: Codable {
    let score: Double
    let notes: String
    let defects: [String]
    let front: CenteringMeasurement?
    let back: CenteringMeasurement?
}

struct CenteringMeasurement: Codable {
    let leftRight: String?
    let topBottom: String?

    enum CodingKeys: String, CodingKey {
        case leftRight = "left_right"
        case topBottom = "top_bottom"
    }
}

struct EstimatedGrade: Codable {
    let psaRange: String
    let bgsRange: String?
    let confidence: String

    enum CodingKeys: String, CodingKey {
        case psaRange = "psa_range"
        case bgsRange = "bgs_range"
        case confidence
    }
}
