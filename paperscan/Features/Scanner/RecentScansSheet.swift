import SwiftUI
import Inject
import SwiftData

struct RecentScansSheet: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router
    let scanStore: ScanStore

    @State private var showClearConfirmation = false
    @State private var addedAllToast = false
    @State private var correctionRecord: ScanRecord?
    @State private var recordToAdd: ScanRecord?
    @State private var showAddAllSheet = false

    var body: some View {
        VStack(spacing: 0) {
            header
            if scanStore.records.isEmpty {
                emptyState
            } else {
                recordsList
            }
        }
        .background(Color(.systemBackground))
        .alert("Clear all \(scanStore.records.count) scans?", isPresented: $showClearConfirmation) {
            Button("Clear", role: .destructive) { scanStore.clearSession() }
            Button("Cancel", role: .cancel) {}
        }
        .overlay(alignment: .top) {
            if addedAllToast { toastView }
        }
        .sheet(item: $correctionRecord) { record in
            ScanCorrectionSheet(record: record, scanStore: scanStore)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $recordToAdd) { record in
            AddToCollectionSheet { collection in
                _ = scanStore.addToCollection(record, to: collection)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAddAllSheet) {
            AddToCollectionSheet { collection in
                let count = scanStore.addAllToCollection(to: collection)
                if count > 0 {
                    addedAllToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { addedAllToast = false }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .enableInjection()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Recent Scans")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Button(role: .destructive) {
                    showClearConfirmation = true
                } label: {
                    Text("CLEAR")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .overlay(
                            Capsule().stroke(Color(.separator), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                Spacer()

                Text(String(format: "$%.2f", scanStore.totalValue))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)
                + Text(" total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if scanStore.records.count >= 2 {
                HStack(spacing: 8) {
                    Spacer()
                    Button {
                        showAddAllSheet = true
                    } label: {
                        Label("Add all", systemImage: "plus.square.on.square")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        router.dismissFullscreenCover()
                    } label: {
                        Label("Collection", systemImage: "square.stack")
                            .font(.caption.weight(.medium))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.top, 6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 24)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    // MARK: - List

    private var recordsList: some View {
        List {
            ForEach(scanStore.records, id: \.id) { record in
                ScanRecordRow(
                    record: record,
                    onAdd:     { recordToAdd = record },
                    onRetry:   { scanStore.retryFailed(record) },
                    onCorrect: { correctionRecord = record }
                )
                .buttonStyle(.borderless)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation { scanStore.deleteRecord(record) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("Scanned cards will appear here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Load previous scans") { scanStore.loadAll() }
                .font(.subheadline)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Toast

    private var toastView: some View {
        Label("Added to collection", systemImage: "checkmark.circle.fill")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(theme.value)
            .clipShape(Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
            .padding(.top, 8)
    }
}
