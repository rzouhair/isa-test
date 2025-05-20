//
//  BanknoteExtension.swift
//  paperscan
//
//  Created by user on 2/4/2025.
//
import Foundation

extension Banknote {
    static let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: Date.now)!
    static let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date.now)!
    
    static var sampleData: [Banknote] = [
        Banknote(
            country: "Venezuela",
            title: "bolívares",
            serialNumber: "N50778546",
            issueDate: "2018",
            rarity: "27",
            uncirculatedPriceRange: "$2-$5",
            circulatedPriceRange: "$1-$3",
            designElements: ["Simon Bolivar portrait", "National coat of arms"],
            imageNames: ["venezuela1", "venezuela2"],
            isCollected: true,
            collectionEntryDate: Date.now,
            collectionNotes: "Purchased at local market"
        ),
        Banknote(
            country: "Taiwan",
            title: "100 yuan",
            serialNumber: "SY58825IDT",
            issueDate: "2018",
            rarity: "45",
            uncirculatedPriceRange: "$10-$20",
            circulatedPriceRange: "$5-$15",
            designElements: ["Dr. Sun Yat-sen portrait", "Chiang Kai-shek Memorial Hall"],
            imageNames: ["taiwan1"],
            isCollected: true,
            collectionEntryDate: lastWeek,
            collectionNotes: "Found in circulation"
        ),
        Banknote(
            country: "United States",
            title: "1 dollar",
            serialNumber: "L32513006T",
            issueDate: "2018",
            rarity: "n/a",
            uncirculatedPriceRange: "$1.50-$3",
            circulatedPriceRange: "$1-$1.50",
            designElements: ["George Washington portrait", "Great Seal"],
            imageNames: ["usd1"],
            isCollected: true,
            collectionEntryDate: lastMonth,
            collectionNotes: "From my childhood collection"
        )
    ]
}
