//
//  Banknote.swift
//  paperscan
//
//  Created by user on 27/3/2025.
//

import SwiftUI
import SwiftData

@Model
final class Banknote {
    @Attribute(.unique) var id: UUID
    var country: String
    var title: String
    var serialNumber: String
    var issueDate: String
    var rarity: String
    var uncirculatedPriceRange: String
    var circulatedPriceRange: String
    var designElements: [String]
    var imageNames: [String]
    
    var sources: [String: [URLCitation]] = [:]
    
    var grade: [String: String] = [:]
    
    // Collection Management
    var isCollected: Bool = false
    var collectionEntryDate: Date? = nil
    var collectionNotes: String = ""
    
    // Sales data for detailed display
    var salesData: String? = nil
    
    var fullName: String {
        return "\(title), \(issueDate)"
    }
    
    var rarityProgress: CGFloat {
        guard rarity != "n/a",
              let rarityValue = Int(rarity) else {
            return 0
        }
        return CGFloat(rarityValue) / 100
    }

    @Relationship(deleteRule: .cascade)
    var specifications: [Specification]
    
    init(
        country: String,
        title: String,
        serialNumber: String,
        issueDate: String,
        rarity: String,
        uncirculatedPriceRange: String,
        circulatedPriceRange: String,
        designElements: [String],
        imageNames: [String],
        specifications: [Specification] = [],
        isCollected: Bool = false,
        collectionEntryDate: Date? = nil,
        collectionNotes: String = "",
        sources: [String: [URLCitation]]? = [:],
        grade: [String: String]? = [:],
        salesData: String? = nil
    ) {
        self.id = UUID()
        self.country = country
        self.title = title
        self.serialNumber = serialNumber
        self.issueDate = issueDate
        self.rarity = rarity
        self.uncirculatedPriceRange = uncirculatedPriceRange
        self.circulatedPriceRange = circulatedPriceRange
        self.designElements = designElements
        self.imageNames = imageNames
        self.specifications = specifications
        self.isCollected = isCollected
        self.collectionEntryDate = collectionEntryDate
        self.collectionNotes = collectionNotes
        self.sources = sources ?? [:]
        self.grade = grade ?? [:]
        self.salesData = salesData
    }
}

@Model
final class Specification {
    @Attribute(.unique) var id: UUID
    var title: String
    var value: String
    var banknote: Banknote?
    
    init(title: String, value: String) {
        self.id = UUID()
        self.title = title
        self.value = value
    }
}
