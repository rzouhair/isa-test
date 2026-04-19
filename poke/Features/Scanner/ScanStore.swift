import Foundation
import SwiftData
import SwiftUI
import UIKit

/// Singleton managing scan queue, API polling, and collection persistence.
@MainActor @Observable
final class ScanStore {
    static let shared = ScanStore()

    private(set) var records: [ScanRecord] = []
    private var pollTasks: [UUID: Task<Void, Never>] = [:]
    private var modelContext: ModelContext?

    private let service: CardIdentifierServiceProtocol = DIContainer.shared.cardIdentifierService
    private let analytics: AnalyticsServiceProtocol = DIContainer.shared.analyticsService
    private let crashReporting: CrashReportingServiceProtocol = DIContainer.shared.crashReportingService
    private let maxScansPerSession = 50

    private init() {}

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecent()
    }

    // MARK: - Capture

    /// Insert a pending placeholder immediately (before photo is ready) so UI updates instantly.
    /// Does NOT call save — defers it to avoid blocking main thread during capture.
    func insertPending() -> ScanRecord {
        let record = ScanRecord(capturedImagePath: "")
        modelContext?.insert(record)
        records.insert(record, at: 0)
        // Defer save so the UI updates instantly — save happens on next runloop
        Task { @MainActor in
            self.trySave()
        }
        return record
    }

    /// Called once the camera delivers and processes the image for a pending record.
    /// Image encoding + disk write happen on a background thread and never block main.
    func fulfillPending(_ record: ScanRecord, image: UIImage) {
        // Fire-and-forget: encode image off main thread, then hop back to update record
        Task.detached(priority: .userInitiated) {
            guard let data = image.jpegData(compressionQuality: 0.6) else {
                await MainActor.run {
                    record.scanStatus = .failed
                    record.errorMessage = "Image encoding failed"
                    self.crashReporting.captureMessage("Scan image encoding failed")
                    self.trySave()
                }
                return
            }
            let path = ScanStore.writeImageToDisk(data)

            // Hop back to main only to mutate SwiftData
            await MainActor.run {
                record.capturedImagePath = path
                self.trySave()
                self.analytics.capture(.scanSubmitted)
            }

            // Submit job off main thread
            do {
                let response = try await self.service.submitJob(imageData: data)
                await MainActor.run {
                    record.jobId = response.jobId
                    record.updatedAt = Date()
                    self.trySave()
                    self.startPolling(record)
                }
            } catch {
                await MainActor.run {
                    record.scanStatus = .failed
                    record.errorMessage = error.localizedDescription
                    record.updatedAt = Date()
                    self.trySave()
                    self.analytics.capture(.scanFailed, properties: ["error": error.localizedDescription])
                    self.crashReporting.captureError(error, context: ["action": "submit_job"])
                }
            }
        }
    }

    var isAtCapacity: Bool { records.count >= maxScansPerSession }

    // MARK: - Polling

    func startPolling(_ record: ScanRecord) {
        guard let jobId = record.jobId else { return }
        cancelPolling(for: record.id)

        pollTasks[record.id] = Task {
            var attempts = 0
            let maxAttempts = 150 // 5min max (150 × 2s avg)
            let pollingRateSeconds = 4
            while !Task.isCancelled && attempts < maxAttempts {
                do {
                    try await Task.sleep(for: .seconds(pollingRateSeconds))
                    let status = try await service.checkStatus(jobId: jobId)
                    let mapped = ScanStatus(apiStatus: status.status)
                    #if DEBUG
                    print("[ScanStore] Poll \(attempts+1) for \(jobId) — status: \(status.status)")
                    #endif

                    record.scanStatus = mapped
                    record.updatedAt = Date()

                    switch mapped {
                    case .complete:
                        if let result = status.result {
                            record.update(from: result)
                        }
                        analytics.capture(.scanCompleted, properties: [
                            "game": record.game ?? "unknown",
                            "has_price": record.marketPrice != nil
                        ])
                        self.autoCreateCardRecord(from: record)
                        trySave()
                        return
                    case .failed:
                        record.errorMessage = status.error ?? "Unknown error"
                        analytics.capture(.scanFailed, properties: ["error": record.errorMessage ?? "unknown"])
                        trySave()
                        return
                    case .pending, .processing:
                        break
                    }
                } catch {
                    if Task.isCancelled { return }
                    crashReporting.captureError(error, context: ["action": "poll", "job_id": jobId])
                }
                attempts += 1
            }

            if !Task.isCancelled {
                record.scanStatus = .failed
                record.errorMessage = "Identification timed out. Tap to retry."
                record.updatedAt = Date()
                analytics.capture(.scanFailed, properties: ["error": "poll_timeout"])
                trySave()
            }
        }
    }

    private func cancelPolling(for id: UUID) {
        pollTasks[id]?.cancel()
        pollTasks[id] = nil
    }

    // MARK: - Delete Single

    func deleteRecord(_ record: ScanRecord) {
        cancelPolling(for: record.id)
        // Remove saved image (non-fatal if file doesn't exist)
        if let url = ScanStore.resolveImageURL(record.capturedImagePath),
           FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                crashReporting.captureError(error, context: ["action": "delete_scan_image"])
            }
        }
        records.removeAll { $0.id == record.id }
        modelContext?.delete(record)
        trySave()
    }

    /// Remove any ScanRecords linked to a deleted CardRecord. Cancels polling,
    /// deletes image files, removes from the in-memory `records` array, and
    /// issues `modelContext.delete` — caller is responsible for saving.
    ///
    /// Matches by `cardRecordId` first; falls back to `productId` so scans from
    /// pre-Wave-1 builds (before auto-linkage existed) are still cleaned up.
    /// Also sweeps `records` in-memory as a final safety net so the Scanner
    /// recent-scans UI reacts immediately even if SwiftData indexing lags.
    func purgeScans(forCardId cardId: UUID, productId: String? = nil, in context: ModelContext? = nil) {
        let ctx = context ?? modelContext
        guard let ctx else {
            // No context — still sweep in-memory so UI reflects the delete.
            records.removeAll { $0.cardRecordId == cardId }
            return
        }

        var matches: [ScanRecord] = []

        let idDescriptor: FetchDescriptor<ScanRecord> = {
            var d = FetchDescriptor<ScanRecord>(predicate: #Predicate { $0.cardRecordId == cardId })
            d.fetchLimit = 20
            return d
        }()
        if let byId = try? ctx.fetch(idDescriptor) {
            matches.append(contentsOf: byId)
        }

        if let pid = productId, !pid.isEmpty {
            let productDescriptor: FetchDescriptor<ScanRecord> = {
                var d = FetchDescriptor<ScanRecord>(predicate: #Predicate { $0.productId == pid })
                d.fetchLimit = 20
                return d
            }()
            if let byProduct = try? ctx.fetch(productDescriptor) {
                for rec in byProduct where !matches.contains(where: { $0.id == rec.id }) {
                    matches.append(rec)
                }
            }
        }

        for record in matches {
            cancelPolling(for: record.id)
            if let url = ScanStore.resolveImageURL(record.capturedImagePath),
               FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            records.removeAll { $0.id == record.id }
            ctx.delete(record)
        }

        // Final in-memory sweep in case fetch missed something.
        records.removeAll { record in
            record.cardRecordId == cardId ||
            (productId != nil && !productId!.isEmpty && record.productId == productId)
        }
    }

    // MARK: - Retry

    func retryFailed(_ record: ScanRecord) {
        guard record.scanStatus == .failed else { return }
        guard let imageData = loadImageFromDisk(path: record.capturedImagePath) else { return }

        analytics.capture(.scanRetried)
        record.scanStatus = .pending
        record.errorMessage = nil
        record.updatedAt = Date()
        trySave()

        Task {
            do {
                let response = try await service.submitJob(imageData: imageData)
                record.jobId = response.jobId
                record.updatedAt = Date()
                trySave()
                startPolling(record)
            } catch {
                record.scanStatus = .failed
                record.errorMessage = error.localizedDescription
                record.updatedAt = Date()
                trySave()
                crashReporting.captureError(error, context: ["action": "retry_submit"])
            }
        }
    }

    // MARK: - Collection

    /// Overwrite a record's identity with a manually selected candidate.
    func applyCandidate(_ candidate: Candidate, to record: ScanRecord) {
        record.productId     = candidate.productId
        record.productName   = candidate.name
        record.setName       = candidate.setName
        record.setCode       = candidate.setCode
        record.cardNumber    = candidate.cardNumber
        record.rarity        = candidate.rarity
        record.variant       = candidate.variant
        record.year          = candidate.year
        record.game          = candidate.game
        record.imageSmall    = candidate.image
        record.imageMedium   = candidate.image
        record.marketPrice   = candidate.marketPrice
        record.lowestPrice   = candidate.lowestPrice
        record.medianPrice   = candidate.medianPrice
        record.productUrl    = candidate.url
        record.addedToCollection = false  // identity changed — require re-save
        record.scanStatus    = .complete
        record.updatedAt     = Date()

        // Update the auto-created CardRecord so detail view shows corrected data
        if let cardId = record.cardRecordId {
            var descriptor = FetchDescriptor<CardRecord>()
            descriptor.predicate = #Predicate { $0.id == cardId }
            descriptor.fetchLimit = 1
            if let existing = try? modelContext?.fetch(descriptor).first {
                existing.tcgplayerProductId = candidate.productId ?? ""
                existing.name = candidate.name ?? "Unknown"
                existing.setName = candidate.setName ?? ""
                existing.setCode = candidate.setCode ?? ""
                existing.number = candidate.cardNumber ?? ""
                existing.rarity = candidate.rarity ?? ""
                existing.variant = candidate.variant ?? "STANDARD"
                existing.game = candidate.game ?? ""
                existing.tcgplayerPrice = candidate.marketPrice ?? 0
                existing.scanImageUrl = candidate.image
                existing.candidatesJSON = record.candidatesJSON
                existing.isUserConfirmed = true
            }
        }

        trySave()
    }

    /// Marks the auto-created identification as user-confirmed without changing identity.
    func confirmCard(_ card: CardRecord) {
        card.isUserConfirmed = true
        trySave()
    }

    /// Finds the originating ScanRecord for a CardRecord, if still present.
    func scanRecord(for card: CardRecord) -> ScanRecord? {
        guard let modelContext else { return nil }
        let cardId = card.id
        var descriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate { $0.cardRecordId == cardId }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    func addToCollection(_ record: ScanRecord, to collection: CardCollection) -> CardRecord? {
        guard record.scanStatus == .complete else { return nil }

        // Find auto-created CardRecord by stored ID
        if let cardId = record.cardRecordId {
            var descriptor = FetchDescriptor<CardRecord>()
            descriptor.predicate = #Predicate { $0.id == cardId }
            descriptor.fetchLimit = 1

            if let existing = try? modelContext?.fetch(descriptor).first {
                existing.collection = collection
                record.addedToCollection = true
                trySave()
                analytics.capture(.cardAddedToCollection)
                return existing
            }
        }

        // Fallback: create new CardRecord if auto-created one not found
        let card = CardRecord(from: record)
        card.collection = collection
        modelContext?.insert(card)
        record.addedToCollection = true
        record.cardRecordId = card.id
        trySave()
        analytics.capture(.cardAddedToCollection)
        return card
    }

    func addAllToCollection(to collection: CardCollection) -> Int {
        let completed = records.filter { $0.scanStatus == .complete && !$0.addedToCollection }
        var count = 0
        for record in completed {
            if addToCollection(record, to: collection) != nil {
                count += 1
            }
        }
        return count
    }

    // MARK: - Auto Card Creation

    /// Automatically create a CardRecord when scan completes (no collection required).
    private func autoCreateCardRecord(from record: ScanRecord) {
        guard record.scanStatus == .complete else { return }
        guard record.cardRecordId == nil else { return }

        if let productId = record.productId, !productId.isEmpty,
           let existing = findCardRecord(productId: productId) {
            record.cardRecordId = existing.id
            return
        }

        let card = CardRecord(from: record)
        modelContext?.insert(card)
        record.cardRecordId = card.id
    }

    private func findCardRecord(productId: String) -> CardRecord? {
        guard let modelContext else { return nil }
        var descriptor = FetchDescriptor<CardRecord>(
            predicate: #Predicate { $0.tcgplayerProductId == productId }
        )
        descriptor.fetchLimit = 1
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Session Management

    func clearSession() {
        for (id, task) in pollTasks {
            task.cancel()
            pollTasks[id] = nil
        }
        for record in records {
            modelContext?.delete(record)
        }
        records.removeAll()
        trySave()
    }

    func loadRecent() {
        guard let modelContext else { return }
        sweepOrphanedScans(in: modelContext)

        var descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            records = []
            crashReporting.captureError(error, context: ["action": "load_recent_scans"])
        }

        // Resume polling for any pending/processing records
        for record in records where record.scanStatus == .pending || record.scanStatus == .processing {
            if record.jobId != nil {
                startPolling(record)
            }
        }
    }

    /// Purges completed ScanRecords whose linked CardRecord no longer exists.
    /// Cleans up rows left over from builds before the purge-on-delete fix.
    private func sweepOrphanedScans(in context: ModelContext) {
        var completedDescriptor = FetchDescriptor<ScanRecord>(
            predicate: #Predicate { $0.status == "complete" }
        )
        completedDescriptor.fetchLimit = 500
        guard let completed = try? context.fetch(completedDescriptor), !completed.isEmpty else {
            return
        }

        let cardDescriptor = FetchDescriptor<CardRecord>()
        let allCards = (try? context.fetch(cardDescriptor)) ?? []
        let validCardIds = Set(allCards.map(\.id))
        let validProductIds = Set(allCards.map(\.tcgplayerProductId).filter { !$0.isEmpty })

        var purged = 0
        for scan in completed {
            let hasCardLink = scan.cardRecordId.map { validCardIds.contains($0) } ?? false
            let hasProductMatch = (scan.productId.map { !$0.isEmpty && validProductIds.contains($0) }) ?? false
            if !hasCardLink && !hasProductMatch {
                if let url = ScanStore.resolveImageURL(scan.capturedImagePath),
                   FileManager.default.fileExists(atPath: url.path) {
                    try? FileManager.default.removeItem(at: url)
                }
                context.delete(scan)
                purged += 1
            }
        }

        if purged > 0 {
            do {
                try context.save()
            } catch {
                crashReporting.captureError(error, context: ["action": "sweep_orphaned_scans"])
            }
        }
    }

    func loadAll() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            records = try modelContext.fetch(descriptor)
        } catch {
            records = []
            crashReporting.captureError(error, context: ["action": "load_all_scans"])
        }
    }

    // MARK: - Computed

    var totalValue: Double {
        records
            .filter { $0.scanStatus == .complete }
            .compactMap { $0.marketPrice }
            .reduce(0, +)
    }

    var identifiedCount: Int {
        records.filter { $0.scanStatus == .complete }.count
    }

    // MARK: - Persistence Helpers

    private func trySave() {
        do {
            try modelContext?.save()
        } catch {
            crashReporting.captureError(error, context: ["action": "scan_store_save"])
        }
    }

    /// Writes image and returns a **filename** (not absolute path).
    /// Absolute Documents paths include the app container UUID which changes across dev reinstalls,
    /// so we persist the filename only and resolve it against `scansDirectory` at read time.
    nonisolated static func writeImageToDisk(_ imageData: Data) -> String {
        let filename = UUID().uuidString + ".jpg"
        let url = scansDirectory.appendingPathComponent(filename)
        do {
            try imageData.write(to: url)
        } catch {
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "scan_image_write", "path": url.path]
            )
        }
        return filename
    }

    /// Resolves a stored value (filename or legacy absolute path) to a current URL.
    nonisolated static func resolveImageURL(_ stored: String) -> URL? {
        guard !stored.isEmpty else { return nil }
        let filename = (stored as NSString).lastPathComponent
        return scansDirectory.appendingPathComponent(filename)
    }

    private func loadImageFromDisk(path: String) -> Data? {
        guard let url = ScanStore.resolveImageURL(path) else { return nil }
        do {
            return try Data(contentsOf: url)
        } catch {
            crashReporting.captureError(error, context: ["action": "scan_image_read", "path": url.path])
            return nil
        }
    }

    nonisolated static var scansDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Scans", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "create_scans_directory"]
            )
        }
        return dir
    }
}
