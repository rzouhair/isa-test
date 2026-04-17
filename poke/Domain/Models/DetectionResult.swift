//
//  DetectionResult.swift
//  poke
//

import Foundation
import SwiftData

@Model
final class DetectionResult {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    var category: String
    var date: String
    var imageNames: [String]
    var rawJSON: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var details: [DetectionDetail]

    init(
        title: String,
        subtitle: String = "",
        category: String = "",
        date: String = "",
        imageNames: [String] = [],
        rawJSON: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.date = date
        self.imageNames = imageNames
        self.rawJSON = rawJSON
        self.createdAt = Date()
        self.details = []
    }
}

@Model
final class DetectionDetail {
    @Attribute(.unique) var id: UUID
    var key: String
    var value: String
    var result: DetectionResult?

    init(key: String, value: String) {
        self.id = UUID()
        self.key = key
        self.value = value
    }
}
