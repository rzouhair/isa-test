import SwiftUI
import Inject

struct OnboardingNotificationsStepView: View {
    @ObserveInjection var inject
    let onEnable: () -> Void
    let onSkip: () -> Void

    @State private var bellRotation: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var bulletOpacity: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 90))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.accentBright, theme.accentWarm],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(bellRotation), anchor: .top)
                .shadow(color: theme.accent.opacity(0.3), radius: 16, y: 8)

            VStack(spacing: 8) {
                Text("Never miss a study day")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .opacity(titleOpacity)
                Text("Short, friendly reminders. No spam.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.white.opacity(0.6))
                    .opacity(titleOpacity)
            }

            VStack(alignment: .leading, spacing: 12) {
                bullet(icon: "calendar.badge.clock", text: "Countdown reminders 30/14/7/3/1 days out")
                bullet(icon: "sunrise.fill", text: "Optional daily morning practice reminder")
                bullet(icon: "hand.raised.fill", text: "Change or disable anytime in Settings")
            }
            .padding(.horizontal, 24)
            .opacity(bulletOpacity)

            Spacer()

            VStack(spacing: 10) {
                Button { enable() } label: {
                    Text("Enable reminders")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                Button("Not now") { onSkip() }
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear { animateIn() }
        .enableInjection()
    }

    private func bullet(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(theme.accentBright)
                .frame(width: 28)
            Text(text)
                .font(.callout)
                .foregroundStyle(Color.white.opacity(0.85))
        }
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.5)) { titleOpacity = 1 }
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) { bulletOpacity = 1 }
        startBellRing()
    }

    private func startBellRing() {
        let angles: [Double] = [0, -10, 10, -8, 8, -5, 5, 0]
        var delay = 0.0
        for angle in angles {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.1)) { bellRotation = angle }
            }
            delay += 0.1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            startBellRing()
        }
    }

    private func enable() {
        Task {
            let granted = await ExamReminderScheduler.requestAuthorization()
            if granted { await ExamReminderScheduler.enableDailyReminder() }
            await MainActor.run { onEnable() }
        }
    }
}
