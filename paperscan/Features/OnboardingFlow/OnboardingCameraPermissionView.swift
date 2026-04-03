//
//  OnboardingCameraPermissionView.swift
//  paperscan
//
//  Screen 3: Camera permission — scan target visualization
//  with privacy reassurance before requesting camera access.
//

import SwiftUI
import Inject

struct OnboardingCameraPermissionView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var scanLineOffset: CGFloat = 3

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("ONE LAST THING")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(KashColors.green300)
                    .tracking(2)
                    .padding(.bottom, 12)

                (Text("Allow ")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("camera access")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(KashColors.green300))
                .padding(.bottom, 8)

                Text("Kash needs your camera to scan and identify banknotes. Nothing is stored without your approval.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)

                // Camera visualization
                cameraVisualization
                    .padding(.bottom, 28)

                // Privacy card
                infoCard(
                    icon: "🔒",
                    title: "Your privacy",
                    body: "Photos are processed on-device whenever possible. We never access your camera roll automatically."
                )
                .padding(.bottom, 16)

                // What camera sees card
                infoCard(
                    icon: "📖",
                    title: "What the camera sees",
                    body: "Only the frame you point at a banknote. No background photos, no location, no contacts."
                )
            }
            .padding(.horizontal, 28)
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

    // MARK: - Camera Visualization

    private var cameraVisualization: some View {
        ZStack {
            // Dark camera background
            LinearGradient(
                colors: [Color(hex: "#1a2a1e"), Color(hex: "#0a1510")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Scan target — centered
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        // Corner brackets
                        scanCorners

                        // Scan line
                        GeometryReader { geo in
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, KashColors.green300, KashColors.goldLight, KashColors.green300, .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 2)
                                .offset(y: scanLineOffset)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                        scanLineOffset = geo.size.height - 5
                                    }
                                }
                        }
                        .padding(3)

                        // Ghost banknote
                        RoundedRectangle(cornerRadius: 7)
                            .fill(Color.white.opacity(0.06))
                            .overlay(
                                RoundedRectangle(cornerRadius: 7)
                                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .frame(width: 140, height: 70)
                    }
                    .frame(width: 180, height: 100)
                    Spacer()
                }
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(3/2, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .opacity(isAnimating ? 1 : 0)
        .scaleEffect(isAnimating ? 1 : 0.95)
    }

    // MARK: - Scan Corners

    private var scanCorners: some View {
        GeometryReader { geo in
            let w: CGFloat = 20
            let h: CGFloat = 20
            let lineWidth: CGFloat = 3

            // Top-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: h))
                path.addLine(to: CGPoint(x: 0, y: lineWidth))
                path.addQuadCurve(to: CGPoint(x: lineWidth, y: 0), control: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: w, y: 0))
            }
            .stroke(KashColors.green300, lineWidth: lineWidth)

            // Top-right
            Path { path in
                path.move(to: CGPoint(x: geo.size.width - w, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width - lineWidth, y: 0))
                path.addQuadCurve(to: CGPoint(x: geo.size.width, y: lineWidth), control: CGPoint(x: geo.size.width, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: h))
            }
            .stroke(KashColors.green300, lineWidth: lineWidth)

            // Bottom-left
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height - h))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height - lineWidth))
                path.addQuadCurve(to: CGPoint(x: lineWidth, y: geo.size.height), control: CGPoint(x: 0, y: geo.size.height))
                path.addLine(to: CGPoint(x: w, y: geo.size.height))
            }
            .stroke(KashColors.green300, lineWidth: lineWidth)

            // Bottom-right
            Path { path in
                path.move(to: CGPoint(x: geo.size.width, y: geo.size.height - h))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - lineWidth))
                path.addQuadCurve(to: CGPoint(x: geo.size.width - lineWidth, y: geo.size.height), control: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: geo.size.width - w, y: geo.size.height))
            }
            .stroke(KashColors.green300, lineWidth: lineWidth)
        }
    }

    // MARK: - Info Card

    private func infoCard(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.system(size: 20))

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }

            Text(body)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ZStack {
        KashColors.green900.ignoresSafeArea()
        OnboardingCameraPermissionView()
    }
}
