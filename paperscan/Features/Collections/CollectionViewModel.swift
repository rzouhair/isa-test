//
//  CollectionsViewModel.swift
//  paperscan
//
//  Created by user on 26/3/2025.
//

import SwiftUI
import Foundation
import Observation
import SwiftData

extension CollectionView {
    @Observable
    @MainActor
    class ViewModel {
        var context: ModelContext
        
        // MARK: - State
        var items: [Banknote] = []
        var selectedFilter: CollectionFilter = .collected
        
        var errorMessage: String? = nil
        
        var filteredItems: [Banknote] {
            switch selectedFilter {
            case .all:
                return items
            case .collected:
                return items.filter { $0.isCollected == true }
            }
        }
        
        public var itemsData: [String: Int] {
            var data = [String: Int]()
            let uniqueCountriesCount = Set(filteredItems.map { $0.country }).count
            data["banknotes"] = filteredItems.count
            data["countries"] = uniqueCountriesCount
            return data
        }
        
        var totalItems: Int { items.count }
        
        init(context: ModelContext) {
            self.context = context
            print("Fetching banknote")
            fetchBanknotes()
        }
        
        func fetchBanknotes() {
            let descriptor = FetchDescriptor<Banknote>(sortBy: [SortDescriptor(\.id, order: .reverse)])
            
            do {
                items = try context.fetch(descriptor)
            } catch {
                print("Failed to fetch tasks: \(error.localizedDescription)")
                self.errorMessage = "Failed to fetch tasks: \(error.localizedDescription)"
            }
        }
        
        private func loadSampleData() {
            items = [
                Banknote(
                    country: "Venezuela",
                    title: "bolívares",
                    serialNumber: "N50778546",
                    issueDate: "2018",
                    rarity: "Common",
                    uncirculatedPriceRange: "$2-$5",
                    circulatedPriceRange: "$1-$3",
                    designElements: ["Simon Bolivar portrait", "National coat of arms"],
                    imageNames: ["venezuela1", "venezuela2"],
                    isCollected: true,
                    collectionEntryDate: Date(),
                    collectionNotes: "Purchased at local market"
                ),
                Banknote(
                    country: "Taiwan",
                    title: "100 yuan",
                    serialNumber: "SY58825IDT",
                    issueDate: "2018",
                    rarity: "Uncommon",
                    uncirculatedPriceRange: "$10-$20",
                    circulatedPriceRange: "$5-$15",
                    designElements: ["Dr. Sun Yat-sen portrait", "Chiang Kai-shek Memorial Hall"],
                    imageNames: ["taiwan1"],
                    isCollected: true,
                    collectionEntryDate: Date(),
                    collectionNotes: "Found in circulation"
                ),
                Banknote(
                    country: "United States",
                    title: "1 dollar",
                    serialNumber: "L32513006T",
                    issueDate: "2018",
                    rarity: "Common",
                    uncirculatedPriceRange: "$1.50-$3",
                    circulatedPriceRange: "$1-$1.50",
                    designElements: ["George Washington portrait", "Great Seal"],
                    imageNames: ["usd1"],
                    isCollected: true,
                    collectionEntryDate: Date(),
                    collectionNotes: "From my childhood collection"
                )
            ]
        }
    }
}

enum CollectionFilter {
    case all
    case collected
}
