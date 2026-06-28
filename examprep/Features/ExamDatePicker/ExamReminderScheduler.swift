import Foundation
import UserNotifications

/// Wrapper around `UNUserNotificationCenter` for exam-date reminders.
/// Schedules a cascade of "N days out" nudges plus an optional daily
/// 8am practice reminder.
enum ExamReminderScheduler {
    static let dailyReminderId = "isaprep_daily_reminder"
    static let examReminderPrefix = "isaprep_exam_"
    static let reminderOffsets = [30, 14, 7, 3, 1]

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func clearExamReminders() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(examReminderPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func scheduleExamReminders(for examDate: Date) async {
        await clearExamReminders()
        let center = UNUserNotificationCenter.current()

        for days in reminderOffsets {
            guard let fire = Calendar.current.date(byAdding: .day, value: -days, to: examDate),
                  fire > Date() else { continue }
            var components = Calendar.current.dateComponents([.year, .month, .day], from: fire)
            components.hour = 8
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let content = UNMutableNotificationContent()
            content.title = "Exam in \(days) day\(days == 1 ? "" : "s")"
            content.body = "Keep practicing to pass first try."
            content.sound = .default
            let request = UNNotificationRequest(
                identifier: "\(examReminderPrefix)\(days)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    static func enableDailyReminder(hour: Int = 8, minute: Int = 0) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Today's practice"
        content.body = "Quick study session?"
        content.sound = .default
        let request = UNNotificationRequest(identifier: dailyReminderId, content: content, trigger: trigger)
        try? await center.add(request)
    }

    static func disableDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [dailyReminderId])
    }
}
