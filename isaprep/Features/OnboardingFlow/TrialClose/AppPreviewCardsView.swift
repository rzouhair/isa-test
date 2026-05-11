//
//  AppPreviewCardsView.swift
//  isaprep
//
//  Two stacked card mockups previewing the CDL app — a quiz question card
//  on top and a results / readiness card behind it. Pure SwiftUI, no assets.
//

import SwiftUI
import Inject

struct AppPreviewCardsView: View {
    @ObserveInjection var inject
    @State private var checkmarkScale: CGFloat = 0
    @State private var donutProgress: Double = 0

    var body: some View {
        ZStack {
            // Back card — readiness summary
            backCard
                .frame(width: 200, height: 260)
                .rotationEffect(.degrees(6))
                .offset(x: 60, y: 20)
                .shadow(color: Color.black.opacity(0.25), radius: 16, y: 8)

            // Front card — practice question
            frontCard
                .frame(width: 190, height: 280)
                .rotationEffect(.degrees(-4))
                .offset(x: -40, y: 16)
                .shadow(color: Color.black.opacity(0.3), radius: 16, y: 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.6).delay(0.4)) {
                checkmarkScale = 1
            }
            withAnimation(.easeOut(duration: 1.1).delay(0.2)) {
                donutProgress = 0.82
            }
        }
        .enableInjection()
    }

    // MARK: - Back Card (Readiness summary — passes the math)

    private var backCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Exam ready")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.accentBright.opacity(0.7))
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.accentWarmLight)
            }

            // Donut + score
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: donutProgress)
                        .rotation(.degrees(-90))
                        .stroke(theme.accentWarmLight, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                }
                .frame(width: 50, height: 50)

                VStack(alignment: .leading, spacing: 0) {
                    Text("\(Int(donutProgress * 100))%")
                        .font(.system(size: 20, weight: .heavy, design: .rounded).monospacedDigit())
                        .foregroundColor(.white)
                    Text("ready")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Mini category bars
            VStack(spacing: 5) {
                miniBar(label: "GK", value: 0.86)
                miniBar(label: "Air Brakes", value: 0.72)
                miniBar(label: "Hazmat", value: 0.54)
            }
            .padding(.top, 4)

            Spacer(minLength: 0)

            // Endorsement pills
            HStack(spacing: 6) {
                ForEach(["Class A", "HazMat"], id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(theme.accentBright)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.accentBright.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(theme.onboardingCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func miniBar(label: String, value: Double) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 56, alignment: .leading)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 4)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.accent, theme.accentWarm],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80 * value, height: 4)
            }
        }
    }

    // MARK: - Front Card (Practice question — correct-answer feedback)

    private var frontCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header — test pill + timer
            HStack {
                Text("Q 12 / 50")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(theme.accentBright)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(theme.accentBright.opacity(0.14))
                    .clipShape(Capsule())
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 8))
                    Text("38:42")
                        .font(.system(size: 9, weight: .semibold).monospacedDigit())
                }
                .foregroundColor(theme.accentWarmLight)
            }

            // Question text
            Text("Ideal soil ratio of solids to pore space?")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(.top, 2)

            // Answer rows
            VStack(spacing: 5) {
                answerRow(letter: "A", text: "20:80", state: .neutral)
                answerRow(letter: "B", text: "35:65", state: .neutral)
                answerRow(letter: "C", text: "40:60", state: .neutral)
                answerRow(letter: "D", text: "50:50", state: .correct)
            }
            .padding(.top, 2)

            Spacer(minLength: 0)

            // CTA
            HStack {
                Spacer()
                Text("Next")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(theme.accent)
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(theme.onboardingCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private enum AnswerState { case neutral, correct }

    private func answerRow(letter: String, text: String, state: AnswerState) -> some View {
        HStack(spacing: 8) {
            Text(letter)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(state == .correct ? theme.accentWarmLight : .white.opacity(0.55))
                .frame(width: 14, height: 14)
                .background(
                    Circle()
                        .stroke(state == .correct ? theme.accentWarmLight : Color.white.opacity(0.18), lineWidth: 1)
                )
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(state == .correct ? .white : .white.opacity(0.7))
            Spacer()
            if state == .correct {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(theme.accentWarmLight)
                    .scaleEffect(checkmarkScale)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(state == .correct ? theme.accentWarm.opacity(0.15) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(state == .correct ? theme.accentWarmLight.opacity(0.55) : .clear, lineWidth: 1)
        )
    }
}

#Preview {
    AppPreviewCardsView()
        .frame(height: 340)
        .padding()
        .background(theme.onboardingBg)
}
