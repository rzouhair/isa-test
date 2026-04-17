import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Inject

struct ImportExportView: View {
    @ObserveInjection var inject
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Query var collections: [CardCollection]
    @Query(filter: #Predicate<CardRecord> { $0.collection == nil })
    var uncollectedCards: [CardRecord]
    @Query var watchlistItems: [WatchlistItem]
    @Query(sort: \GradeRecord.createdAt, order: .reverse) var gradeRecords: [GradeRecord]

    // Export
    @State private var exportScope: ExportScope = .all
    @State private var selectedCollections: Set<UUID> = []
    @State private var includeWatchlist = true
    @State private var showShareSheet = false
    @State private var exportFileURL: URL?

    // Import
    @State private var showFilePicker = false
    @State private var importMode: CSVService.ImportMode = .merge
    @State private var importDataType: ImportDataType = .collections
    @State private var showImportConfirm = false
    @State private var pendingImportURL: URL?
    @State private var importResult: CSVService.ImportResult?
    @State private var showImportResult = false

    enum ExportScope: String, CaseIterable {
        case all = "All Data"
        case selected = "Selected Collections"
    }

    enum ImportDataType: String, CaseIterable {
        case collections = "Collections"
        case watchlist = "Watchlist"
        case grades = "Grades"
    }

    var body: some View {
        List {
            exportSection
            watchlistExportSection
            gradesExportSection
            importSection
        }
        .navigationTitle("Import & Export")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            if let url = exportFileURL {
                ShareSheetFile(fileURL: url)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Replace All Data?", isPresented: $showImportConfirm) {
            Button("Cancel", role: .cancel) { pendingImportURL = nil }
            Button("Replace", role: .destructive) { performImport() }
        } message: {
            Text("This will delete all existing \(importDataType.rawValue.lowercased()), then import from the CSV file.")
        }
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK") {}
        } message: {
            if let r = importResult {
                switch importDataType {
                case .collections:
                    Text("\(r.cardsCreated) cards imported\n\(r.collectionsCreated) collections created\(r.errors.isEmpty ? "" : "\n\(r.errors.count) rows skipped")")
                case .watchlist:
                    Text("\(r.watchlistCreated) watchlist items imported\(r.errors.isEmpty ? "" : "\n\(r.errors.count) rows skipped")")
                case .grades:
                    Text("\(r.gradesCreated) grades imported\(r.errors.isEmpty ? "" : "\n\(r.errors.count) rows skipped")")
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Export Collections Section

    private var exportSection: some View {
        Section {
            Picker("Scope", selection: $exportScope) {
                ForEach(ExportScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue).tag(scope)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            if exportScope == .selected {
                if collections.isEmpty {
                    Text("No collections yet")
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.gray.opacity(0.08))
                } else {
                    ForEach(collections) { collection in
                        Button {
                            toggleSelection(collection.id)
                        } label: {
                            HStack {
                                Image(systemName: selectedCollections.contains(collection.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedCollections.contains(collection.id) ? theme.accent : .secondary)
                                Text(collection.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text("\(collection.cardCount) cards")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listRowBackground(Color.gray.opacity(0.08))
                    }
                }
            }

            Button {
                exportCollections()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Collections CSV")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(exportScope == .selected && selectedCollections.isEmpty)
            .listRowBackground(Color.gray.opacity(0.08))
        } header: {
            Text("Export Collections")
        } footer: {
            Text("Export your cards as a CSV file you can open in Excel, Google Sheets, or import into another app.")
        }
    }

    // MARK: - Export Watchlist Section

    private var watchlistExportSection: some View {
        Section {
            Button {
                exportWatchlist()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Watchlist CSV")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(watchlistItems.isEmpty)
            .listRowBackground(Color.gray.opacity(0.08))
        } header: {
            Text("Export Watchlist")
        } footer: {
            Text("\(watchlistItems.count) items in watchlist")
        }
    }

    // MARK: - Export Grades Section

    private var gradesExportSection: some View {
        Section {
            Button {
                exportGrades()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Grades CSV")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(gradeRecords.isEmpty)
            .listRowBackground(Color.gray.opacity(0.08))
        } header: {
            Text("Export Grades")
        } footer: {
            Text("\(gradeRecords.count) grade\(gradeRecords.count == 1 ? "" : "s") recorded")
        }
    }

    // MARK: - Import Section

    private var importSection: some View {
        Section {
            Picker("Data Type", selection: $importDataType) {
                ForEach(ImportDataType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            Picker("Mode", selection: $importMode) {
                Text("Add to existing").tag(CSVService.ImportMode.merge)
                Text("Replace all").tag(CSVService.ImportMode.replace)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

            Button {
                showFilePicker = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Import \(importDataType.rawValue) CSV")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .listRowBackground(Color.gray.opacity(0.08))
        } header: {
            Text("Import")
        } footer: {
            Text(importMode == .merge
                 ? "Imported data will be added alongside your existing \(importDataType.rawValue.lowercased())."
                 : "⚠️ All existing \(importDataType.rawValue.lowercased()) will be deleted and replaced.")
        }
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedCollections.contains(id) {
            selectedCollections.remove(id)
        } else {
            selectedCollections.insert(id)
        }
    }

    private func exportCollections() {
        let collectionsToExport: [CardCollection]
        var uncollected: [CardRecord] = []

        switch exportScope {
        case .all:
            collectionsToExport = collections
            uncollected = uncollectedCards
        case .selected:
            collectionsToExport = collections.filter { selectedCollections.contains($0.id) }
        }

        let csv = CSVService.exportCSV(collections: collectionsToExport, includeUncollected: uncollected)
        shareCSV(csv, fileName: "paperscan_collections_\(dateStamp()).csv")
    }

    private func exportWatchlist() {
        let csv = CSVService.exportWatchlistCSV(items: watchlistItems)
        shareCSV(csv, fileName: "paperscan_watchlist_\(dateStamp()).csv")
    }

    private func exportGrades() {
        let csv = CSVService.exportGradesCSV(grades: gradeRecords)
        shareCSV(csv, fileName: "paperscan_grades_\(dateStamp()).csv")
    }

    private func shareCSV(_ csv: String, fileName: String) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            exportFileURL = tempURL
            showShareSheet = true
        } catch {
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "csv_export_write", "file": fileName]
            )
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        pendingImportURL = url

        if importMode == .replace {
            showImportConfirm = true
        } else {
            performImport()
        }
    }

    private func performImport() {
        guard let url = pendingImportURL else { return }
        defer { pendingImportURL = nil }

        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let csvString = try String(contentsOf: url, encoding: .utf8)

            let result: CSVService.ImportResult
            switch importDataType {
            case .collections:
                result = CSVService.importCSV(
                    csvString: csvString,
                    context: modelContext,
                    mode: importMode,
                    existingCollections: collections
                )
            case .watchlist:
                result = CSVService.importWatchlistCSV(
                    csvString: csvString,
                    context: modelContext,
                    mode: importMode,
                    existingItems: watchlistItems
                )
            case .grades:
                result = CSVService.importGradesCSV(
                    csvString: csvString,
                    context: modelContext,
                    mode: importMode,
                    existingGrades: gradeRecords
                )
            }

            self.importResult = result
            showImportResult = true
        } catch {
            self.importResult = CSVService.ImportResult(errors: ["Failed to read file: \(error.localizedDescription)"])
            showImportResult = true
        }
    }

    private func dateStamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - Share Sheet for File

private struct ShareSheetFile: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
