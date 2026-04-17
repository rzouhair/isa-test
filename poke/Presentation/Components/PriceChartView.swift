import SwiftUI
import Inject
import Charts

/// Reusable price history chart.
/// - Shows line chart if data exists
/// - Shows empty state placeholder if chart array is empty
/// - Renders nothing (EmptyView) if history is nil
struct PriceChartView<TrailingHeader: View>: View {
    @ObserveInjection var inject
    let history: PriceHistory?
    let trailingHeader: TrailingHeader

    init(history: PriceHistory?, @ViewBuilder trailingHeader: () -> TrailingHeader = { EmptyView() }) {
        self.history = history
        self.trailingHeader = trailingHeader()
    }

    var body: some View {
        if let history {
            if history.chart.isEmpty || history.chart.allSatisfy({ $0.dataPoints.isEmpty }) {
                emptyChart(summary: history.summary).enableInjection()
            } else {
                populatedChart(history: history).enableInjection()
            }
        }
    }

    // MARK: - Populated Chart

    private func populatedChart(history: PriceHistory) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            summaryHeader(history.summary)

            // Only use first (primary) series
            let points = history.chart.first?.dataPoints ?? []

            Chart(points) { point in
                if let date = point.parsedDate {
                    AreaMark(
                        x: .value("Date", date),
                        y: .value("Price", point.marketPrice)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [theme.accent.opacity(0.15), theme.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", date),
                        y: .value("Price", point.marketPrice)
                    )
                    .foregroundStyle(theme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(v >= 1000 ? String(format: "$%.0fK", v / 1000) : String(format: "$%.2f", v))
                                .font(.system(size: 10).monospacedDigit())
                                .foregroundStyle(.tertiary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color(.separator).opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 160)

            Divider()

            statsRow(history.summary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Empty Chart

    private func emptyChart(summary: PriceSummary) -> some View {
        VStack(spacing: 14) {
            summaryHeader(summary)

            ZStack {
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        Divider().opacity(0.3)
                        Spacer()
                    }
                    Divider().opacity(0.3)
                }
                .frame(height: 100)

                VStack(spacing: 4) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.title3)
                        .foregroundStyle(.quaternary)
                    Text("No price history available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Divider()

            statsRow(summary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Summary Header

    private func summaryHeader(_ summary: PriceSummary) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Text("Price History")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            trailingHeader
            if let change = summary.priceChange, let pct = summary.priceChangePct {
                HStack(spacing: 3) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2.weight(.bold))
                    Text(String(format: "%@%.2f (%.1f%%)", change >= 0 ? "+" : "", change, pct))
                        .font(.caption.weight(.semibold).monospacedDigit())
                }
                .foregroundStyle(change >= 0 ? Color(.systemGreen) : Color(.systemRed))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    (change >= 0 ? Color(.systemGreen) : Color(.systemRed)).opacity(0.1)
                )
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Stats Row

    private func statsRow(_ summary: PriceSummary) -> some View {
        HStack(spacing: 0) {
            statItem("High", value: summary.periodHigh)
            statDivider
            statItem("Low", value: summary.periodLow)
            statDivider
            statItem("Volume", value: summary.totalVolume > 0 ? Double(summary.totalVolume) : nil, isInt: true)
            statDivider
            statItem("Avg/Day", value: summary.avgDailyVolume > 0 ? summary.avgDailyVolume : nil, isDecimal: true)
        }
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color(.separator).opacity(0.3))
            .frame(width: 1, height: 24)
    }

    private func statItem(_ label: String, value: Double?, isInt: Bool = false, isDecimal: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            if let v = value {
                if isInt {
                    Text("\(Int(v))")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                } else if isDecimal {
                    Text(String(format: "%.1f", v))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(format: "$%.2f", v))
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
