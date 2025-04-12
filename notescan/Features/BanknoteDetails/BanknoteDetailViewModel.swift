//
//  BanknoteDetailsView.swift
//  notescan
//
//  Created by user on 27/3/2025.
//

import SwiftUI
import Observation
import SwiftData

extension BanknoteDetailView {

    @Observable
    class ViewModel {
        var context: ModelContext
        var banknote: Banknote
        
        var images: [UIImage] {
            let imageNames = banknote.imageNames
            return imageNames.compactMap { fetchImage(name: $0) }
        }
        
        init (banknote: Banknote, context: ModelContext) {
            self.context = context
            self.banknote = banknote
            
            print("=== Banknote ===")
            print(banknote.rarity)
        }

        func addToCollection(banknote: Banknote) throws {
            banknote.collectionEntryDate = banknote.isCollected ? nil : Date.now
            banknote.isCollected.toggle()
            try self.context.save()
        }
        
        func fetchImage(name imageName: String) -> UIImage? {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imageUrl = documentsDirectory.appendingPathComponent(imageName)
            
            if let imageData = try? Data(contentsOf: imageUrl) {
                return UIImage(data: imageData)
            }
            
            return nil
        }
    }
}
