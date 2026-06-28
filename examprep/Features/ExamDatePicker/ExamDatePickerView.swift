import SwiftUI
import SwiftData
import Inject

struct ExamDatePickerView: View {
    @ObserveInjection var inject
    @Environment(Router.self) private var router
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date = Date().addingTimeInterval(14 * 86_400)
    @State private var dailyReminderOn: Bool = false
    @State private var saving: Bool = false
    @State private var error: String?

    var body: some View {
        Form {
            Section {
                DatePicker("Exam date", selection: $date, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
            } footer: {
                Text("We'll remind you 30, 14, 7, 3, and 1 day before.")
            }

            Section {
                Toggle("Daily study reminder (8am)", isOn: $dailyReminderOn)
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    HStack {
                        Spacer()
                        if saving { ProgressView() } else { Text("Save").fontWeight(.semibold) }
                        Spacer()
                    }
                }
                .disabled(saving)
            }

            if let error {
                Section {
                    Text(error).foregroundStyle(.secondary).font(.callout)
                }
            }
        }
        .navigationTitle("Exam date")
        .navigationBarTitleDisplayMode(.inline)
        .task { loadExisting() }
        .enableInjection()
    }

    private func loadExisting() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        if let existing = progress.profile()?.examDate {
            date = existing
        }
    }

    private func save() async {
        saving = true
        defer { saving = false }

        let granted = await ExamReminderScheduler.requestAuthorization()
        guard granted else {
            error = "Notifications denied — enable them in Settings to get reminders."
            return
        }

        do {
            let progress = DIContainer.shared.userProgressRepository(context: modelContext)
            try progress.updateExamDate(date)
            await ExamReminderScheduler.scheduleExamReminders(for: date)
            if dailyReminderOn {
                await ExamReminderScheduler.enableDailyReminder()
            } else {
                ExamReminderScheduler.disableDailyReminder()
            }
            DIContainer.shared.analyticsService.capture(.examDateSet, properties: [
                "days_out": Int(date.timeIntervalSinceNow / 86_400),
                "daily_reminder": dailyReminderOn,
            ])
            dismiss()
        } catch {
            self.error = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
