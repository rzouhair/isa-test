import Foundation
import SwiftData
import UserNotifications

@MainActor
final class WatchlistPriceService {
    static let shared = WatchlistPriceService()

    static var modelContainer: ModelContainer?

    private let crashReporting: CrashReportingServiceProtocol = DIContainer.shared.crashReportingService

    nonisolated private static let lastRefreshKey = "watchlist_last_refresh"
    nonisolated static let intervalKey = "watchlist_refresh_interval"
    nonisolated static let defaultInterval: TimeInterval = 12 * 3600 // 12h

    /// Available interval options (hours)
    nonisolated static let intervalOptions: [Int] = [6, 8, 10, 12, 16, 24]

    // Reminder notification preferences
    nonisolated static let reminderEnabledKey = "watchlist_reminder_enabled"
    nonisolated static let reminderHourKey = "watchlist_reminder_hour"
    nonisolated static let reminderMinuteKey = "watchlist_reminder_minute"
    nonisolated static let defaultReminderHour = 9
    nonisolated static let defaultReminderMinute = 0

    nonisolated static var remindersEnabled: Bool {
        UserDefaults.standard.object(forKey: reminderEnabledKey) as? Bool ?? true
    }

    nonisolated static var reminderHour: Int {
        UserDefaults.standard.object(forKey: reminderHourKey) as? Int ?? defaultReminderHour
    }

    nonisolated static var reminderMinute: Int {
        UserDefaults.standard.object(forKey: reminderMinuteKey) as? Int ?? defaultReminderMinute
    }

    nonisolated static var reminderDate: Date {
        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = reminderMinute
        return Calendar.current.date(from: comps) ?? Date()
    }

    /// Current interval from UserDefaults
    nonisolated static var refreshInterval: TimeInterval {
        let stored = UserDefaults.standard.double(forKey: intervalKey)
        return stored > 0 ? stored : defaultInterval
    }

    /// Timestamp of last refresh
    nonisolated static var lastRefreshDate: Date {
        let ts = UserDefaults.standard.double(forKey: lastRefreshKey)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : .distantPast
    }

    /// Seconds remaining until next refresh is allowed
    nonisolated static var cooldownRemaining: TimeInterval {
        let elapsed = Date().timeIntervalSince(lastRefreshDate)
        return max(0, refreshInterval - elapsed)
    }

    /// Whether a manual refresh is currently allowed
    nonisolated static var canRefresh: Bool {
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
        let count: Int
        do {
            count = try context.fetchCount(descriptor)
        } catch {
            crashReporting.captureError(error, context: ["action": "watchlist_fetch_count_on_open"])
            return
        }

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

            do {
                try await Task.sleep(for: .milliseconds(200))
            } catch {
                // Cancellation propagates out so callers can bail.
                return (success, failed)
            }
        }

        do {
            try context.save()
        } catch {
            crashReporting.captureError(error, context: ["action": "watchlist_price_save"])
        }
        return (success, failed)
    }

    // MARK: - Timestamp

    nonisolated static func recordRefreshTimestamp() {
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
            identifier: "poke_watchlist_refresh_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Recurring Reminder

    nonisolated private static let reminderIdentifier = "poke_watchlist_reminder"

    nonisolated static func scheduleRecurringReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        guard remindersEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to check your watchlist"
        content.body = "Open Poke to see the latest prices on your watched cards."
        content.sound = .default

        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = reminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    nonisolated static func cancelRecurringReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    /// Update refresh cooldown interval (governs background refresh on app open).
    nonisolated static func setRefreshInterval(hours: Int) {
        let interval = TimeInterval(hours * 3600)
        UserDefaults.standard.set(interval, forKey: intervalKey)
    }

    /// Enable/disable the daily reminder notification.
    /// Returns true if the state was applied; false if user denied notification permission.
    @discardableResult
    nonisolated static func setRemindersEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            let granted = await requestNotificationAuthorizationIfNeeded()
            guard granted else {
                UserDefaults.standard.set(false, forKey: reminderEnabledKey)
                return false
            }
        }
        UserDefaults.standard.set(enabled, forKey: reminderEnabledKey)
        if enabled {
            scheduleRecurringReminder()
        } else {
            cancelRecurringReminder()
        }
        return true
    }

    /// Requests notification auth if status is `.notDetermined`; returns true if granted.
    nonisolated private static func requestNotificationAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                DIContainer.shared.crashReportingService.captureError(
                    error,
                    context: ["action": "notification_auth_request"]
                )
                return false
            }
        @unknown default:
            return false
        }
    }

    /// Update daily reminder time.
    nonisolated static func setReminderTime(hour: Int, minute: Int) {
        UserDefaults.standard.set(hour, forKey: reminderHourKey)
        UserDefaults.standard.set(minute, forKey: reminderMinuteKey)
        scheduleRecurringReminder()
    }
}
