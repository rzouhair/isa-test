import SwiftUI
import Inject
import SwiftData

struct AddToCollectionSheet: View {
    @ObserveInjection var inject
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CardCollection.updatedAt, order: .reverse) private var collections: [CardCollection]

    let onSelect: (CardCollection) -> Void
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(collections) { collection in
                        Button {
                            onSelect(collection)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: collection.tcgType.iconName)
                                    .font(.title3)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 32)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collection.name)
                                        .font(.body.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("\(collection.cardCount) cards")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    if !collections.isEmpty {
                        Text("Your Collections")
                    }
                }

                Section {
                    Button {
                        showCreate = true
                    } label: {
                        Label("Create New Collection", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(isPresented: $showCreate) {
                CreateCollectionView { collection in
                    onSelect(collection)
                    dismiss()
                }
            }
            .overlay {
                if collections.isEmpty {
                    ContentUnavailableView {
                        Label("No Collections", systemImage: "square.stack")
                    } description: {
                        Text("Create your first collection to get started.")
                    } actions: {
                        Button("Create Collection") { showCreate = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .enableInjection()
    }
}
