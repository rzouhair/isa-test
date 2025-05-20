//
//  HomeView.swift
//  paperscan
//
//  Created by user on 26/3/2025.
//

import SwiftUI
import Inject
import SwiftData

struct HomeView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(Router.self) private var router: Router
    @Environment(AppState.self) private var appState: AppState
    @State private var viewModel: HomeViewModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Scan CTA Button
                Button {
                    viewModel?.scanBanknote()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Scan Banknote")
                            .font(.title3.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.appPrimary.gradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)
                
                // Recent Identifications
                if let viewModel = viewModel {
                    // Most Rare
                    if let rarest = viewModel.rarestBanknote {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Most Rare")
                                .font(.title2.bold())
                            
                            BanknoteRowView(banknote: rarest)
                                .background(Color(.secondarySystemBackground))
                                .contentShape(Rectangle())
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .onTapGesture {
                                    viewModel.showBanknoteDetails(rarest)
                                }
                        }
                        .padding(.horizontal)
                    }
                    
                    if viewModel.uncollectedBanknotes.isEmpty && viewModel.recentBanknotes.isEmpty {
                        VStack {
                            Spacer()
                            
                            ContentUnavailableView {
                                Label("Empty list", systemImage: "camera.viewfinder")
                            } description: {
                                Text("Click on the \"Scan Banknote\" button to start scanning")
                            } actions: {
                                Button("Get Started") {
                                    viewModel.scanBanknote()
                                }.tint(Asset.Colors.appPrimary.swiftUIColor)
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    
                    if !viewModel.recentBanknotes.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            Text("Recent Identifications")
                                .font(.title2.bold())
                            
                            VStack(spacing: 0) {
                                ForEach(viewModel.recentBanknotes) { banknote in
                                    BanknoteRowView(banknote: banknote)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.showBanknoteDetails(banknote)
                                        }
                                    
                                    if banknote.id != viewModel.recentBanknotes.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Uncollected Banknotes Section
                    if !viewModel.uncollectedBanknotes.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Uncollected Banknotes")
                                .font(.title2.bold())
                            
                            VStack(spacing: 0) {
                                ForEach(viewModel.uncollectedBanknotes) { banknote in
                                    BanknoteRowView(banknote: banknote)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            viewModel.showBanknoteDetails(banknote)
                                        }
                                    
                                    if banknote.id != viewModel.uncollectedBanknotes.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.automatic)
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(context: modelContext, router: router, appState: appState)
            }
        }
        .onChange(of: router.presentedSheet) { oldVal, newVal in
            Task {
                await self.viewModel?.fetchData()
            }
        }
        .onChange(of: router.presentedFullscreenCover) { oldVal, newVal in
            Task {
                await self.viewModel?.fetchData()
            }
        }
        .enableInjection()
    }
}

#Preview {
    let preview = Preview(Banknote.self)
    // preview.addExamples(Banknote.sampleData)
    let router = Router()
    let appState = AppState()
    
    return NavigationStack {
        HomeView()
            .environment(router)
            .environment(appState)
            .modelContainer(preview.container)
    }
}
