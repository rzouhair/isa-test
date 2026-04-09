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
    private let maxScansPerSession = 50

    private init() {}

    // MARK: - Setup

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadRecent()
    }

    // MARK: - Capture

    /// Insert a pending placeholder immediately (before photo is ready) so UI updates instantly.
    func insertPending() -> ScanRecord {
        let record = ScanRecord(capturedImagePath: "")
        modelContext?.insert(record)
        records.insert(record, at: 0)
        trySave()
        return record
    }

    /// Called once the camera delivers and processes the image for a pending record.
    func fulfillPending(_ record: ScanRecord, image: UIImage) {
        Task {
            let prepared: (Data, String)? = await Task.detached(priority: .userInitiated) {
                guard let data = image.jpegData(compressionQuality: 0.6) else { return nil }
                let path = ScanStore.writeImageToDisk(data)
                return (data, path)
            }.value

            guard let (imageData, imagePath) = prepared else {
                record.scanStatus = .failed
                record.errorMessage = "Image encoding failed"
                return
            }

            record.capturedImagePath = imagePath
            trySave()

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
            let maxAttempts = 60 // 2min max
            while !Task.isCancelled && attempts < maxAttempts {
                do {
                    try await Task.sleep(for: .seconds(2))
                    let status = try await service.checkStatus(jobId: jobId)
                    let mapped = ScanStatus(apiStatus: status.status)
                    print("[ScanStore] Poll \(attempts+1) for \(jobId) — status: \(status.status)")

                    record.scanStatus = mapped
                    record.updatedAt = Date()

                    switch mapped {
                    case .complete:
                        if let result = status.result {
                            record.update(from: result)
                        }
                        trySave()
                        return
                    case .failed:
                        record.errorMessage = status.error ?? "Unknown error"
                        trySave()
                        return
                    case .pending, .processing:
                        trySave()
                    }
                } catch {
                    if Task.isCancelled { return }
                    print("[ScanStore] Poll error for \(jobId): \(error)")
                }
                attempts += 1
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
        // Remove saved image
        try? FileManager.default.removeItem(atPath: record.capturedImagePath)
        records.removeAll { $0.id == record.id }
        modelContext?.delete(record)
        trySave()
    }

    // MARK: - Retry

    func retryFailed(_ record: ScanRecord) {
        guard record.scanStatus == .failed else { return }
        guard let imageData = loadImageFromDisk(path: record.capturedImagePath) else { return }

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
        trySave()
    }

    func addToCollection(_ record: ScanRecord, to collection: CardCollection) -> CardRecord? {
        guard record.scanStatus == .complete else { return nil }
        // Prevent duplicates: same productId in same collection
        if let productId = record.productId, !productId.isEmpty {
            let alreadyExists = collection.cards.contains { $0.tcgplayerProductId == productId }
            if alreadyExists {
                record.addedToCollection = true
                trySave()
                return nil
            }
        }
        let card = CardRecord(from: record)
        card.collection = collection
        modelContext?.insert(card)
        record.addedToCollection = true
        trySave()
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
        var descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 3
        records = (try? modelContext.fetch(descriptor)) ?? []

        // Resume polling for any pending/processing records
        for record in records where record.scanStatus == .pending || record.scanStatus == .processing {
            if record.jobId != nil {
                startPolling(record)
            }
        }
    }

    func loadAll() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<ScanRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        records = (try? modelContext.fetch(descriptor)) ?? []
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
        try? modelContext?.save()
    }

    private nonisolated static func writeImageToDisk(_ imageData: Data) -> String {
        let filename = UUID().uuidString + ".jpg"
        let url = scansDirectory.appendingPathComponent(filename)
        try? imageData.write(to: url)
        return url.path
    }

    private func loadImageFromDisk(path: String) -> Data? {
        try? Data(contentsOf: URL(fileURLWithPath: path))
    }

    private nonisolated static var scansDirectory: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Scans", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
