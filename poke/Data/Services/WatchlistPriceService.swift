import Foundation
import SwiftData
import UserNotifications

final class WatchlistPriceService: Sendable {
    static let shared = WatchlistPriceService()

    nonisolated(unsafe) static var modelContainer: ModelContainer?

    private let crashReporting: CrashReportingServiceProtocol = DIContainer.shared.crashReportingService

    private static let lastRefreshKey = "watchlist_last_refresh"
    static let intervalKey = "watchlist_refresh_interval"
    static let defaultInterval: TimeInterval = 12 * 3600 // 12h

    /// Available interval options (hours)
    static let intervalOptions: [Int] = [6, 8, 10, 12, 16, 24]

    /// Current interval from UserDefaults
    static var refreshInterval: TimeInterval {
        let stored = UserDefaults.standard.double(forKey: intervalKey)
        return stored > 0 ? stored : defaultInterval
    }

    /// Timestamp of last refresh
    static var lastRefreshDate: Date {
        let ts = UserDefaults.standard.double(forKey: lastRefreshKey)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : .distantPast
    }

    /// Seconds remaining until next refresh is allowed
    static var cooldownRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(lastRefreshDate)
        return max(0, refreshInterval - elapsed)
    }

    /// Whether a manual refresh is currently allowed
    static var canRefresh: Bool {
        cooldownRemaining <= 0
    }

    private let service = DIContainer.shared.cardIdentifierService
    private init() {}

    // MARK: - Auto Refresh on App Open

    @MainActor
    func checkOnAppOpen() async {
        guard let container = Self.modelContainer else { return }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<WatchlistItem>()
        let count = (try? context.fetchCount(descriptor)) ?? 0

        if count > 0 {
            Self.scheduleRecurringReminder()

            if Self.canRefresh {
                let result = await refreshAllPrices()
                if result.success > 0 {
                    Self.recordRefreshTimestamp()
                    sendCompletionNotification(success: result.success, failed: result.failed)
                }
            }
        } else {
            Self.cancelRecurringReminder()
        }
    }

    // MARK: - Manual Refresh

    @MainActor
    func refreshAllPrices() async -> (success: Int, failed: Int) {
        guard let container = Self.modelContainer else { return (0, 0) }

        let context = ModelContext(container)
        let descriptor = FetchDescriptor<WatchlistItem>()

        let items: [WatchlistItem]
        do {
            items = try context.fetch(descriptor)
        } catch {
            crashReporting.captureError(error, context: ["action": "watchlist_fetch_for_refresh"])
            return (0, 0)
        }
        guard !items.isEmpty else { return (0, 0) }

        let cardDescriptor = FetchDescriptor<CardRecord>()
        let allCards: [CardRecord]
        do {
            allCards = try context.fetch(cardDescriptor)
        } catch {
            crashReporting.captureError(error, context: ["action": "cards_fetch_for_price_refresh"])
            allCards = []
        }

        var success = 0
        var failed = 0

        for item in items {
            guard !item.tcgplayerProductId.isEmpty else { continue }

            do {
                let history = try await service.fetchPriceHistory(productId: item.tcgplayerProductId)

                if let card = allCards.first(where: { $0.tcgplayerProductId == item.tcgplayerProductId }) {
                    card.storePriceHistory(history)
                    if let current = history.summary.currentMarketPrice, current > 0 {
                        card.tcgplayerPrice = current
                    } else if let latest = history.chart.first?.dataPoints.last?.marketPrice, latest > 0 {
                        card.tcgplayerPrice = latest
                    }
                    card.priceUpdatedAt = Date()
                }

                if let current = history.summary.currentMarketPrice, current > 0 {
                    item.lastKnownPrice = current
                }

                success += 1
            } catch {
                failed += 1
                crashReporting.captureError(error, context: [
                    "action": "watchlist_price_fetch",
                    "product_id": item.tcgplayerProductId
                ])
            }

            try? await Task.sleep(for: .milliseconds(200))
        }

        do {
            try context.save()
        } catch {
            crashReporting.captureError(error, context: ["action": "watchlist_price_save"])
        }
        return (success, failed)
    }

    // MARK: - Timestamp

    static func recordRefreshTimestamp() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastRefreshKey)
    }

    // MARK: - Completion Notification

    func sendCompletionNotification(success: Int, failed: Int) {
        guard success > 0 || failed > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Watchlist prices updated"
        content.body = failed == 0
            ? "\(success) card\(success == 1 ? "" : "s") refreshed successfully."
            : "\(success) of \(success + failed) cards refreshed. \(failed) failed."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "poke_watchlist_refresh",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Recurring Reminder

    private static let reminderIdentifier = "poke_watchlist_reminder"

    static func scheduleRecurringReminder() {
        let interval = refreshInterval
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to check your watchlist"
        content.body = "Open Poke to see the latest prices on your watched cards."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(60, interval), repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    static func cancelRecurringReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    /// Update interval and reschedule
    static func setRefreshInterval(hours: Int) {
        let interval = TimeInterval(hours * 3600)
        UserDefaults.standard.set(interval, forKey: intervalKey)
        scheduleRecurringReminder()
    }
}
