//
//  BanknoteRowView.swift
//  notescan
//
//  Created by user on 5/4/2025.
//

import SwiftUI
import Foundation

struct BanknoteRowView: View {
    let banknote: Banknote
    @State private var image: UIImage?
    
    private var rarityColor: Color {
        let rarityValue = Int(banknote.rarity) ?? 0
        switch rarityValue {
        case 0...20: return .gray
        case 21...40: return .green
        case 41...60: return .blue
        case 61...80: return .purple
        case 81...: return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 60)
                    .overlay {
                        Image(systemName: "banknote")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(banknote.fullName)
                    .font(.headline)
                
                Text(banknote.country)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 12) {
                    // Serial number badge
                    Text("#\(banknote.serialNumber)")
                        .font(.caption.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .foregroundStyle(.appPrimary)
                        .background(Color.appPrimary.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text("RARITY")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(banknote.rarity)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background(
                        Circle()
                            .fill(rarityColor.gradient)
                    )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            loadFirstImage()
        }
    }
    
    private func loadFirstImage() {
        guard let firstImageName = banknote.imageNames.first else { return }
        
        // Get the documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        
        // Create the full URL for the image
        let imageUrl = documentsDirectory.appendingPathComponent(firstImageName)
        
        // Load the image
        if let imageData = try? Data(contentsOf: imageUrl),
           let loadedImage = UIImage(data: imageData) {
            self.image = loadedImage
        }
    }
}

#Preview {
    BanknoteRowView(banknote: Banknote.sampleData.first!)
}
