import Foundation
import SwiftData

@Model
final class GradeRecord {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    // Sub-grades (1-10)
    var centeringScore: Double
    var cornersScore: Double
    var edgesScore: Double
    var surfaceScore: Double

    // Notes per category
    var centeringNotes: String?
    var cornersNotes: String?
    var edgesNotes: String?
    var surfaceNotes: String?

    // Defects JSON per category
    var centeringDefectsJSON: Data?
    var cornersDefectsJSON: Data?
    var edgesDefectsJSON: Data?
    var surfaceDefectsJSON: Data?

    // Centering ratios
    var frontCenteringLR: String?
    var frontCenteringTB: String?
    var backCenteringLR: String?
    var backCenteringTB: String?

    // Estimated grades
    var psaRange: String?
    var bgsRange: String?
    var confidence: String

    // Tips & disclaimer
    var tipsJSON: Data?
    var disclaimer: String?

    // Photos
    var photosProvidedJSON: Data?
    var capturedImagePathsJSON: Data?

    // Link to card
    var cardRecordId: UUID?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        centeringScore: Double = 0,
        cornersScore: Double = 0,
        edgesScore: Double = 0,
        surfaceScore: Double = 0,
        confidence: String = "low"
    ) {
        self.id = id
        self.createdAt = createdAt
        self.centeringScore = centeringScore
        self.cornersScore = cornersScore
        self.edgesScore = edgesScore
        self.surfaceScore = surfaceScore
        self.confidence = confidence
    }

    /// Populate from API response
    func update(from response: GradeResponse) {
        centeringScore = response.centering.score
        cornersScore = response.corners.score
        edgesScore = response.edges.score
        surfaceScore = response.surface.score

        centeringNotes = response.centering.notes
        cornersNotes = response.corners.notes
        edgesNotes = response.edges.notes
        surfaceNotes = response.surface.notes

        centeringDefectsJSON = try? JSONEncoder().encode(response.centering.defects)
        cornersDefectsJSON = try? JSONEncoder().encode(response.corners.defects)
        edgesDefectsJSON = try? JSONEncoder().encode(response.edges.defects)
        surfaceDefectsJSON = try? JSONEncoder().encode(response.surface.defects)

        frontCenteringLR = response.centering.front?.leftRight
        frontCenteringTB = response.centering.front?.topBottom
        backCenteringLR = response.centering.back?.leftRight
        backCenteringTB = response.centering.back?.topBottom

        psaRange = response.estimatedGrade.psaRange
        bgsRange = response.estimatedGrade.bgsRange
        confidence = response.estimatedGrade.confidence

        tipsJSON = try? JSONEncoder().encode(response.tips)
        disclaimer = response.disclaimer
        photosProvidedJSON = try? JSONEncoder().encode(response.photosProvided)
    }

    // MARK: - Computed

    var tips: [String] {
        guard let data = tipsJSON else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    var centeringDefects: [String] {
        guard let data = centeringDefectsJSON else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    var cornersDefects: [String] {
        guard let data = cornersDefectsJSON else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    var edgesDefects: [String] {
        guard let data = edgesDefectsJSON else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    var surfaceDefects: [String] {
        guard let data = surfaceDefectsJSON else { return [] }
        return (try? JSONDecoder().decode([String].self, from: data)) ?? []
    }

    var averageScore: Double {
        (centeringScore + cornersScore + edgesScore + surfaceScore) / 4.0
    }

    /// Returns absolute paths resolved from stored relative paths
    var capturedImagePaths: [String: String] {
        guard let data = capturedImagePathsJSON else { return [:] }
        let stored = (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        guard let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return [:]
        }
        var resolved: [String: String] = [:]
        for (key, path) in stored {
            if path.hasPrefix("/") {
                // Legacy absolute path — use as-is
                resolved[key] = path
            } else {
                // Relative path — resolve against current Documents dir
                resolved[key] = docsURL.appendingPathComponent(path).path
            }
        }
        return resolved
    }

    func storeCapturedImagePaths(_ paths: [String: String]) {
        capturedImagePathsJSON = try? JSONEncoder().encode(paths)
    }
}
