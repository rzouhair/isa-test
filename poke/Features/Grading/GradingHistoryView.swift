import SwiftUI
import SwiftData
import Inject

struct GradingHistoryView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \GradeRecord.createdAt, order: .reverse) private var records: [GradeRecord]

    @State private var isSelecting: Bool = false
    @State private var selection: Set<UUID> = []
    @State private var showDeleteConfirm: Bool = false

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(records) { record in
                        Button {
                            if isSelecting {
                                toggleSelection(record.id)
                            } else {
                                router.navigate(to: .gradeDetail(record))
                            }
                        } label: {
                            HStack(spacing: 10) {
                                if isSelecting {
                                    Image(systemName: selection.contains(record.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(selection.contains(record.id) ? theme.accent : Color(.tertiaryLabel))
                                }
                                gradeRow(record)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Grading History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !records.isEmpty {
                    Button(isSelecting ? "Done" : "Select") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSelecting.toggle()
                            if !isSelecting { selection.removeAll() }
                        }
                    }
                    .tint(theme.accent)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if isSelecting { selectionActionBar }
        }
        .confirmationDialog(
            "Delete \(selection.count) grade\(selection.count == 1 ? "" : "s")?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Grade records will be permanently removed.")
        }
        .enableInjection()
    }

    // MARK: - Selection

    private func toggleSelection(_ id: UUID) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }

    private var selectionActionBar: some View {
        HStack {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(.white)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(selection.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Text(selection.isEmpty ? "Tap grades to select" : "\(selection.count) selected")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.top, -22)
                .frame(maxWidth: .infinity)
        }
    }

    private func deleteSelected() {
        guard !selection.isEmpty else { return }
        let targets = records.filter { selection.contains($0.id) }
        for record in targets {
            modelContext.delete(record)
        }
        do {
            try modelContext.save()
        } catch {
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "grade_bulk_delete"]
            )
        }
        selection.removeAll()
        isSelecting = false
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("No grades yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Grade a card to see results here")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gradeRow(_ record: GradeRecord) -> some View {
        HStack(spacing: 12) {
            // Card thumbnail from captured front_flat image
            cardThumbnail(record)
                .frame(width: 52, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                // PSA + BGS range
                HStack(spacing: 8) {
                    if let psa = record.psaRange {
                        Text("PSA \(psa)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.valueGradient)
                    }
                    if let bgs = record.bgsRange {
                        Text("BGS \(bgs)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                // Sub-scores inline
                HStack(spacing: 10) {
                    miniScore(label: "Centering", score: record.centeringScore)
                    miniScore(label: "Corners", score: record.cornersScore)
                    miniScore(label: "Edges", score: record.edgesScore)
                    miniScore(label: "Surface", score: record.surfaceScore)
                }

                // Date + confidence
                HStack {
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    confidenceBadge(record.confidence)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func cardThumbnail(_ record: GradeRecord) -> some View {
        Group {
            let paths = record.capturedImagePaths
            if let frontPath = paths["front_flat"],
               let data = try? Data(contentsOf: URL(fileURLWithPath: frontPath)),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .overlay(
                        Image(systemName: "star.circle")
                            .foregroundStyle(.quaternary)
                    )
            }
        }
    }

    private func miniScore(label: String, score: Double) -> some View {
        VStack(spacing: 1) {
            Text(label.prefix(1).uppercased())
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            Text(String(format: "%.1f", score))
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundStyle(scoreColor(score))
        }
    }

    private func confidenceBadge(_ confidence: String) -> some View {
        Text(confidence.capitalized)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(confidenceColor(confidence))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(confidenceColor(confidence).opacity(0.12))
            .clipShape(Capsule())
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 8.0 { return .green }
        if score >= 6.0 { return .orange }
        return .red
    }

    private func confidenceColor(_ confidence: String) -> Color {
        switch confidence {
        case "high": .green
        case "medium": .orange
        default: .red
        }
    }
}
