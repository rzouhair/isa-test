import SwiftUI
import Inject

struct CheatSheetDetailView: View {
    @ObserveInjection var inject
    let id: Int

    @State private var title: String = ""
    @State private var body_: String = ""
    @State private var coverImage: String?
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let coverImage, !coverImage.isEmpty, UIImage(named: coverImage) != nil {
                    Image(coverImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                if !title.isEmpty {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                }
                if !body_.isEmpty {
                    MarkdownText(source: body_)
                }
                if let error {
                    Text(error).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .enableInjection()
    }

    private func load() {
        // Cheat sheets aren't indexed by ID in the current protocol; fetch the
        // list and filter. Tiny list size keeps this effectively O(1).
        do {
            let all = try DIContainer.shared.contentRepository.cheatSheets(
                licenseCode: "cdl", stateCode: nil, lang: "en"
            )
            guard let match = all.first(where: { $0.id == id }) else {
                error = "Cheat sheet not found."
                return
            }
            title = match.title
            body_ = match.bodyMd
            coverImage = match.coverImage
        } catch {
            self.error = "Couldn't load cheat sheet: \(error.localizedDescription)"
        }
    }
}

private extension ContentRepositoryProtocol {
    /// Swallow errors and return an empty list — used when fanning out
    /// cheat-sheet lookups across all licenses from the detail screen.
    func maybeCheatSheets(licenseCode: String) -> [CheatSheetDTO] {
        (try? cheatSheets(licenseCode: licenseCode, stateCode: nil, lang: "en")) ?? []
    }
}
