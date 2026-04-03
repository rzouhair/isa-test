//
//  AppPreviewCardsView.swift
//  paperscan
//

import SwiftUI
import Inject

struct AppPreviewCardsView: View {
    @ObserveInjection var inject
    @State private var scanOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Back card - Scan result
            backCard
                .frame(width: 200, height: 260)
                .rotationEffect(.degrees(6))
                .offset(x: 60, y: 20)
                .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)

            // Front card - Scanner UI
            frontCard
                .frame(width: 190, height: 280)
                .rotationEffect(.degrees(-4))
                .offset(x: -40, y: 16)
                .shadow(color: Color.black.opacity(0.14), radius: 16, y: 8)
        }
        .enableInjection()
    }

    // MARK: - Back Card (Scan Result)

    private var backCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scan result")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(hex: "1E4A2C").opacity(0.6))
                .padding(.bottom, 2)

            Text("$2 United States")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "1A1A14"))

            Text("Thomas Jefferson")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "5A5548"))

            HStack(spacing: 4) {
                Text("Market value")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "9A9080"))
                Spacer()
                Text("$261")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "C49A28"))
            }
            .padding(.top, 4)

            // Rarity bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "EDE7DB"))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "1E4A2C"), Color(hex: "C49A28")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.72, height: 6)
                }
            }
            .frame(height: 6)
            .padding(.top, 4)

            // Grade pills
            HStack(spacing: 6) {
                ForEach(["XF", "VF", "F"], id: \.self) { grade in
                    Text(grade)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color(hex: "1E4A2C"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(hex: "1E4A2C").opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(16)
        .background(Color(hex: "D0E8D8"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Front Card (Scanner UI)

    private var frontCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Viewfinder area
            GeometryReader { geo in
                ZStack {
                    // Banknote placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "D0E8D8").opacity(0.5))
                        .frame(width: geo.size.width * 0.7, height: geo.size.height * 0.5)

                    // Scan line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    Color(hex: "3A8855"),
                                    Color(hex: "F0D880"),
                                    Color(hex: "3A8855"),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                        .offset(y: scanOffset - geo.size.height / 2)
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 2.4)
                                .repeatForever(autoreverses: false)
                            ) {
                                scanOffset = geo.size.height
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 130)
            .background(Color(hex: "EDE7DB"))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Value row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Identified")
                        .font(.system(size: 9))
                        .foregroundColor(Color(hex: "9A9080"))
                    Text("$2 Note")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "1A1A14"))
                }
                Spacer()
                Text("$261")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "C49A28"))
            }

            // Rarity bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "EDE7DB"))
                    .frame(height: 5)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "1E4A2C"))
                    .frame(width: 90, height: 5)
            }

            // Icon row
            HStack(spacing: 12) {
                ForEach(["doc.text.magnifyingglass", "chart.bar", "star"], id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "9A9080"))
                }
                Spacer()
            }

            Spacer()
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    AppPreviewCardsView()
        .frame(height: 340)
        .padding()
        .background(Color(hex: "F5F0E8"))
}
