//
//  CollectionsView.swift
//  notescan
//
//  Created by user on 26/3/2025.
//

import SwiftUI
import SwiftData

struct CollectionView: View {
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(Router.self) private var router: Router
    @State var viewModel: ViewModel?
    
    @State private var selectedFilter: CollectionFilter = .all

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // filterSection
                collectionStats
                collectionItems
            }
            .padding(.horizontal)
        }
        .onAppear {
            self.viewModel = ViewModel(context: modelContext)
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
            Spacer()
            StatItem(count: viewModel?.itemsData["banknotes"] ?? 0, label: "Banknotes")
                .foregroundStyle(.white)
            Spacer()
            Spacer()
            StatItem(count: viewModel?.itemsData["countries"] ?? 0, label: "Countries")
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.appPrimary.gradient)
        )
    }
    
    private var collectionItems: some View {
        VStack(spacing: 0) {
            ForEach(viewModel?.filteredItems ?? [], id: \.id) { banknote in
                CollectionItemView(banknote: banknote)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.presentFullscreenCover(.banknoteDetails(banknote: banknote))
                    }
                
                if banknote.id != viewModel?.items.last?.id {
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
        }
    }
}

private struct CollectionItemView: View {
    let banknote: Banknote
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .center) {
                Text("Image")
                    .frame(minWidth: 120, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(banknote.title)
                    .font(.headline)
                
                Text(banknote.country)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("#\(banknote.serialNumber)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Group {
                    if let entryDate = banknote.collectionEntryDate {
                        Text(entryDate.formatted(date: .abbreviated, time: .omitted))
                    } else {
                        Text("Not collected")
                    }
                }
                .font(.caption)
                .foregroundStyle(.appPrimary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    let preview = Preview(Banknote.self)
    preview.addExamples(Banknote.sampleData)
    
    let router = Router()
    
    return CollectionView(
        viewModel: CollectionView.ViewModel(
            context: preview.container.mainContext
        )
    )
    .environment(router)
    .modelContainer(preview.container)
}
