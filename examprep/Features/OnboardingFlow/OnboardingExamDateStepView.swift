import SwiftUI
import SwiftData
import Inject

struct OnboardingExamDateStepView: View {
    @ObserveInjection var inject
    @Environment(\.modelContext) private var modelContext

    let onSave: () -> Void
    let onSkip: () -> Void

    @State private var date: Date = Date().addingTimeInterval(14 * 86_400)
    @State private var titleOpacity: Double = 0
    @State private var badgeAnim: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 8)

            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.accent.opacity(0.15))
                        .frame(width: 76, height: 76)
                    Image(systemName: "calendar")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(theme.accentBright)
                }
                .scaleEffect(badgeAnim ? 1 : 0.7)
                .rotation3DEffect(.degrees(badgeAnim ? 0 : -18), axis: (x: 1, y: 0, z: 0))

                Text("When's your exam?")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(titleOpacity)
                Text("We'll remind you 30, 14, 7, 3, and 1 day before.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .opacity(titleOpacity)
            }

            DatePicker("", selection: $date, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(14)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                .environment(\.colorScheme, .dark)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    save()
                } label: {
                    Text("Save & remind me")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Button("Skip for now") { onSkip() }
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear { animateIn() }
        .enableInjection()
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            badgeAnim = true
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            titleOpacity = 1
        }
    }

    private func save() {
        let progress = DIContainer.shared.userProgressRepository(context: modelContext)
        try? progress.updateExamDate(date)
        DIContainer.shared.analyticsService.capture(.examDateSet, properties: [
            "days_out": Int(date.timeIntervalSinceNow / 86_400),
            "source": "onboarding",
        ])
        Task {
            let granted = await ExamReminderScheduler.requestAuthorization()
            if granted { await ExamReminderScheduler.scheduleExamReminders(for: date) }
            await MainActor.run { onSave() }
        }
    }
}
