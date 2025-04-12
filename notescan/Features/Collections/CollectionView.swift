//
//  CollectionsView.swift
//  notescan
//
//  Created by user on 26/3/2025.
//


import SwiftUI

struct CollectionView: View {
    var viewModel: ViewModel
    @State private var selectedFilter: CollectionFilter = .all
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                filterSection
                collectionStats
                collectionItems
            }
            .padding(.horizontal)
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Organize Your Collection")
                .font(.largeTitle.bold())
            
            Text("19:24")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var filterSection: some View {
        Picker("Filter", selection: $selectedFilter) {
            Text("All").tag(CollectionFilter.all)
            Text("Custom set").tag(CollectionFilter.custom)
        }
        .pickerStyle(.segmented)
    }
    
    private var collectionStats: some View {
        HStack {
            StatItem(count: 3, label: "Banknotes")
            Spacer()
            StatItem(count: 3, label: "Countries")
        }
        .padding(.vertical)
    }
    
    private var collectionItems: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.filteredItems(filter: selectedFilter)) { item in
                CollectionItemView(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleItem(item.id)
                    }
                
                if item.id != viewModel.items.last?.id {
                    Divider().padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Subviews
private struct StatItem: View {
    let count: Int
    let label: String
    
    var body: some View {
        VStack {
            Text("\(count)")
                .font(.title2.bold())
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CollectionItemView: View {
    let item: CollectionItem
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.country)
                    .font(.headline)
                
                Text("\(item.denomination), \(item.year)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("#\(item.serialNumber)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                if let date = item.entryDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
            
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isChecked ? .green : .secondary)
                .imageScale(.large)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Model
import Observation

@Observable
class CollectionViewModel {
    var items: [CollectionItem] = [
        CollectionItem(
            country: "Venezuela",
            denomination: "bolívares",
            year: "2018",
            serialNumber: "N50778546",
            entryDate: DateComponents(
                calendar: .current,
                year: 2023, month: 12, day: 14
            ).date!
        ),
        CollectionItem(
            country: "Taiwan",
            denomination: "100 yuan",
            year: "2000",
            serialNumber: "SY58825IDT",
            entryDate: DateComponents(
                calendar: .current,
                year: 2023, month: 12, day: 14
            ).date!
        ),
        CollectionItem(
            country: "United States",
            denomination: "1 dollar",
            year: "1963-2021",
            serialNumber: "L32513006T",
            entryDate: DateComponents(
                calendar: .current,
                year: 2023, month: 12, day: 14
            ).date!
        )
    ]
    
    func toggleItem(_ id: UUID) {
        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index].isChecked.toggle()
        }
    }
    
    func filteredItems(filter: CollectionFilter) -> [CollectionItem] {
        switch filter {
        case .all: return items
        case .custom: return items.filter { $0.isChecked }
        }
    }
}

// MARK: - Model
struct CollectionItem: Identifiable {
    let id = UUID()
    let country: String
    let denomination: String
    let year: String
    let serialNumber: String
    let entryDate: Date
    var isChecked = false
}

enum CollectionFilter {
    case all
    case custom
}

// MARK: - Preview
#Preview {
    CollectionView()
}
