//
//  HomeViewModel.swift
//  notescan
//
//  Created by user on 26/3/2025.
//

import SwiftUI
import SwiftData
import Foundation
import Observation

@Observable
class HomeViewModel {
    private var context: ModelContext
    private var router: Router
    private var appState: AppState
    
    // MARK: - State
    var recentBanknotes: [Banknote] = []
    var rarestBanknote: Banknote?
    var uncollectedBanknotes: [Banknote] = []
    var isLoading = false
    var errorMessage: String?
    
    init(context: ModelContext, router: Router, appState: AppState) {
        self.context = context
        self.router = router
        self.appState = appState
        
        Task { @MainActor in
            await fetchData()
        }
    }
    
    @MainActor
    func fetchData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch recent banknotes
            var recentDescriptor = FetchDescriptor<Banknote>(
                sortBy: [SortDescriptor(\.collectionEntryDate, order: .reverse)]
            )
            recentDescriptor.fetchLimit = 3
            recentBanknotes = try context.fetch(recentDescriptor)
            
            // Fetch all banknotes and sort by rarity manually since we need custom comparison
            var allBanknotesDescriptor = FetchDescriptor<Banknote>()
            let allBanknotes = try context.fetch(allBanknotesDescriptor)
            
            // Sort banknotes by rarity, handling "n/a" and numeric values
            rarestBanknote = allBanknotes.sorted { banknote1, banknote2 in
                let rarity1 = Int(banknote1.rarity) ?? (banknote1.rarity.lowercased() == "n/a" ? -1 : 0)
                let rarity2 = Int(banknote2.rarity) ?? (banknote2.rarity.lowercased() == "n/a" ? -1 : 0)
                return rarity1 > rarity2
            }.first
            
            // Fetch uncollected banknotes
            uncollectedBanknotes = allBanknotes.filter { banknote in
                !banknote.isCollected &&
                !self.recentBanknotes.contains { $0.id == banknote.id } &&
                banknote.id != self.rarestBanknote?.id
            }
            
        } catch {
            errorMessage = "Failed to fetch banknotes: \(error.localizedDescription)"
        }
    }
    
    func scanBanknote() {
        if appState.isProUser {
            router.presentFullscreenCover(.camera)
        } else {
            appState.showPaywall()
        }
    }
    
    func showBanknoteDetails(_ banknote: Banknote) {
        router.presentFullscreenCover(.banknoteDetails(banknote: banknote))
    }
}
