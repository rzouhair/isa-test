//
//  OnboardingPriceView.swift
//  poke
//
//  Screen 1: Price & Price History — emphasize real-time pricing,
//  animated price chart, price updates, and market value tracking.
//

import SwiftUI
import Inject

struct OnboardingValueView: View {
    @ObserveInjection var inject

    @State private var isAnimating = false
    @State private var chartProgress: CGFloat = 0
    @State private var priceCountUp: Double = 0
    @State private var showChange = false
    @State private var barFillWidth: CGFloat = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("REAL-TIME PRICING")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.accentBright)
                    .tracking(2)
                    .padding(.bottom, 12)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                (Text("Track your cards'\n")
                    .font(.system(size: 34))
                    .foregroundColor(.white)
                + Text("market value.")
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .italic()
                    .foregroundColor(theme.accentBright))
                .padding(.bottom, 8)
                .opacity(isAnimating ? 1 : 0)
                .offset(y: isAnimating ? 0 : 20)

                Text("Live prices from TCGPlayer, updated daily. See exactly what your cards are worth.")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.55))
                    .lineSpacing(4)
                    .padding(.bottom, 28)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)

                // Animated price card
                priceCard
                    .padding(.bottom, 20)

                // Animated price chart
                priceChartCard
                    .padding(.bottom, 20)

                // Price update feature card
                priceUpdateCard
            }
            .padding(.horizontal, 28)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 2.0)) {
                    chartProgress = 1.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeOut(duration: 1.5)) {
                    priceCountUp = 328.50
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 1.2)) {
                    barFillWidth = 0.72
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showChange = true
                }
            }
        }
        .enableInjection()
    }

    // MARK: - Price Card

    private var priceCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Charizard EX")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Scarlet & Violet · 006/198")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(priceCountUp, specifier: "%.2f")")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentWarm)
                        .contentTransition(.numericText())

                    if showChange {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9, weight: .bold))
                            Text("+12.4%")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(theme.accentBright)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            // Price range bar — using state-driven width
            HStack(spacing: 8) {
                Text("Low $180")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))

                GeometryReader { geo in
                    let totalWidth = geo.size.width
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [theme.ctaFill, theme.accentWarm],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: totalWidth * barFillWidth, height: 4)

                        Circle()
                            .fill(theme.accentWarm)
                            .frame(width: 8, height: 8)
                            .shadow(color: theme.accentWarm.opacity(0.5), radius: 4)
                            .offset(x: max(0, totalWidth * barFillWidth - 4))
                    }
                }
                .frame(height: 8)

                Text("High $420")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.15), value: isAnimating)
    }

    // MARK: - Animated Price Chart

    private let chartPoints: [CGFloat] = [0.35, 0.28, 0.42, 0.38, 0.55, 0.48, 0.62, 0.58, 0.72, 0.68, 0.78, 0.82]

    private var priceChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Price History")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Last 6 months")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()

                // Period pills
                HStack(spacing: 6) {
                    ForEach(["1M", "3M", "6M"], id: \.self) { period in
                        Text(period)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(period == "6M" ? theme.onboardingBg : .white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(period == "6M" ? theme.accentBright : Color.clear)
                            .clipShape(Capsule())
                    }
                }
            }

            // Chart
            GeometryReader { geo in
                ZStack {
                    // Grid lines
                    ForEach(0..<4, id: \.self) { i in
                        Path { path in
                            let y = geo.size.height * CGFloat(i) / 3
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        }
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                    }

                    // Gradient fill under chart
                    chartPath(in: geo, closed: true)
                        .fill(
                            LinearGradient(
                                colors: [theme.accent.opacity(0.25), theme.accent.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(
                            Rectangle()
                                .frame(width: geo.size.width * chartProgress)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )

                    // Chart line
                    chartPath(in: geo, closed: false)
                        .trim(from: 0, to: chartProgress)
                        .stroke(
                            LinearGradient(
                                colors: [theme.ctaFill, theme.accentBright],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )

                    // Glow dot at the end
                    if chartProgress > 0.95 {
                        let lastPoint = chartPoints.last ?? 0.82
                        Circle()
                            .fill(theme.accentBright)
                            .frame(width: 8, height: 8)
                            .shadow(color: theme.accentBright.opacity(0.6), radius: 6)
                            .position(
                                x: geo.size.width,
                                y: geo.size.height * (1 - lastPoint)
                            )
                            .transition(.scale)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.25), value: isAnimating)
    }

    private func chartPath(in geo: GeometryProxy, closed: Bool) -> Path {
        Path { path in
            let stepX = geo.size.width / CGFloat(chartPoints.count - 1)
            for (i, point) in chartPoints.enumerated() {
                let x = stepX * CGFloat(i)
                let y = geo.size.height * (1 - point)
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    let prevX = stepX * CGFloat(i - 1)
                    let prevY = geo.size.height * (1 - chartPoints[i - 1])
                    let midX = (prevX + x) / 2
                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: midX, y: prevY),
                        control2: CGPoint(x: midX, y: y)
                    )
                }
            }
            if closed {
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                path.closeSubpath()
            }
        }
    }

    // MARK: - Price Update Card

    private var priceUpdateCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.accentBright.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(theme.accentBright)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Update prices anytime")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Refresh market values on demand. Stay up to date with the latest card prices.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isAnimating ? 1 : 0)
        .offset(y: isAnimating ? 0 : 20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.35), value: isAnimating)
    }
}

#Preview {
    ZStack {
        theme.onboardingBg.ignoresSafeArea()
        OnboardingValueView()
    }
}
