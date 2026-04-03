//
//  OnboardingPersonalizationView.swift
//  paperscan
//
//  Screen 2: Personalization — user selects their persona(s)
//  to segment the experience (traveller, collector, buyer, gift finder).
//

import SwiftUI
import Inject

struct OnboardingPersonalizationView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false

    private let personas: [(icon: String, label: String, desc: String)] = [
        ("✈️", "World Traveller", "Visiting abroad"),
        ("🏆", "Banknote Collector", "Hunting for rarities"),
        ("💰", "Deal Hunter", "Buying or selling"),
        ("🎁", "Treasure Finder", "Inherited or discovered notes"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("COMMUNITY")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(KashColors.green300)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("An app for every\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("banknote story")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(KashColors.green300))
                .padding(.bottom, 12)

                Text("The app suits many user profiles — from curious travellers to seasoned collectors.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(3)
                    .padding(.bottom, 28)

                // Persona grid (2x2)
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(personas, id: \.label) { persona in
                        personaCard(icon: persona.icon, label: persona.label, desc: persona.desc)
                    }
                }
                .padding(.bottom, 24)

                // Social proof hint
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 11))
                        .foregroundColor(KashColors.green300)

                    Text("Kash is suitable for a wide range of users, from curious travellers to seasoned collectors. See how it works for yourself!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isAnimating = true
            }
        }
        .enableInjection()
    }

    // MARK: - Persona Card

    private func personaCard(icon: String, label: String, desc: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(icon)
                    .font(.system(size: 26))

                Spacer()
            }

            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineSpacing(1)

            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        KashColors.green900.ignoresSafeArea()
        OnboardingPersonalizationView()
    }
}
