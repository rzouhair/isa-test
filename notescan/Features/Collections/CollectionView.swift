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
    
    var body: some View {
        VStack(spacing: 24) {
            // Stats Card
            statsCard
            
            // Filter Section
            if let vm = viewModel {
                filterSection(viewModel: vm)
            }
            
            // Collection Items
            collectionItemsSection
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            self.viewModel = ViewModel(context: modelContext)
        }
        .onChange(of: router.presentedSheet) { oldVal, newVal in
            self.viewModel?.fetchBanknotes()
        }
        .onChange(of: router.presentedFullscreenCover) { oldVal, newVal in
            self.viewModel?.fetchBanknotes()
        }
    }
    private var statsCard: some View {
        HStack(spacing: 32) {
            // Banknotes stat
            VStack(spacing: 8) {
                Image(systemName: "banknote")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text("\(viewModel?.itemsData["banknotes"] ?? 0)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("Banknotes")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            // Divider
            Rectangle()
                .fill(.white.opacity(0.3))
                .frame(width: 1, height: 40)
            
            // Countries stat
            VStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.title2)
                    .foregroundStyle(.white)
                
                Text("\(viewModel?.itemsData["countries"] ?? 0)")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                
                Text("Countries")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.appPrimary.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
    
    private func filterSection(viewModel: ViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(title: "All", isSelected: viewModel.selectedFilter == .all)
                    .onTapGesture { viewModel.selectedFilter = .all }
                FilterChip(title: "Collected", isSelected: viewModel.selectedFilter == .collected)
                    .onTapGesture { viewModel.selectedFilter = .collected }
            }
            .padding(.horizontal)
        }
    }
    
    private var collectionItemsSection: some View {
        LazyVStack(spacing: 16) {
            ForEach(viewModel?.filteredItems ?? [], id: \.id) { banknote in
                BanknoteRowView(banknote: banknote)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        router.presentFullscreenCover(.banknoteDetails(banknote: banknote))
                    }
            }
        }
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.appPrimary : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
    }
}

// MARK: - Preview
#Preview {
    let preview = Preview(Banknote.self)
    preview.addExamples(Banknote.sampleData)
    
    let router = Router()
    
    return NavigationStack {
        ScrollView {
            CollectionView(
                viewModel: CollectionView.ViewModel(
                    context: preview.container.mainContext
                )
            )
        }
        .navigationTitle("My Collection")
    }
    .environment(router)
    .modelContainer(preview.container)
}
