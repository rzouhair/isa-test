import SwiftUI
import Inject
import SwiftData

struct CreateCollectionView: View {
    @ObserveInjection var inject
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let onCreate: (CardCollection) -> Void

    @State private var name = ""
    @State private var selectedType: TCGType = .pokemon

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        Form {
            Section("Collection Name") {
                TextField("e.g. My Pokemon Binder", text: $name)
                    .textInputAutocapitalization(.words)
            }

            Section("Type of Card Collection") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 12)], spacing: 12) {
                    ForEach(TCGType.allCases) { type in
                        tcgTypeButton(type)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("Create Set")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
            }
        }
        .enableInjection()
    }

    private func tcgTypeButton(_ type: TCGType) -> some View {
        Button {
            selectedType = type
        } label: {
            VStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.title2)
                Text(type.displayName)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selectedType == type ? theme.accent.opacity(0.15) : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(selectedType == type ? theme.accent : .clear, lineWidth: 1.5)
            )
        }
        .foregroundStyle(selectedType == type ? .primary : .secondary)
        .buttonStyle(.plain)
    }

    private func save() {
        let collection = CardCollection(name: name.trimmingCharacters(in: .whitespaces), tcgType: selectedType)
        modelContext.insert(collection)
        try? modelContext.save()
        onCreate(collection)
        dismiss()
    }
}
