import SwiftUI
import Inject

struct GradeDetailView: View {
    @ObserveInjection var inject
    let record: GradeRecord

    @State private var showTips = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Card image
                cardImage
                    .padding(.top, 8)

                // Grade header
                gradeHeader

                // Sub-scores
                subScoresSection

                // Centering detail
                if record.frontCenteringLR != nil || record.backCenteringLR != nil {
                    centeringSection
                }

                // Confidence
                confidenceBadge

                // Interpretation
                interpretationSection

                // Defects
                defectsSection

                // Disclaimer
                if let disclaimer = record.disclaimer {
                    Text(disclaimer)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .navigationTitle("Grade Details")
        .navigationBarTitleDisplayMode(.inline)
        .enableInjection()
    }

    // MARK: - Card Image

    private var cardImage: some View {
        let paths = record.capturedImagePaths
        let orderedKeys = ["front_flat", "back_flat", "front_angled", "corners_top", "corners_bottom", "edges"]
        let availableImages: [(String, UIImage)] = orderedKeys.compactMap { key in
            guard let path = paths[key],
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let img = UIImage(data: data) else { return nil }
            return (key, img)
        }

        return Group {
            if availableImages.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemFill))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo").font(.system(size: 28)).foregroundStyle(.tertiary)
                            Text("No images saved").font(.caption).foregroundStyle(.tertiary)
                        }
                    )
            } else if availableImages.count == 1 {
                Image(uiImage: availableImages[0].1)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(availableImages, id: \.0) { key, img in
                            VStack(spacing: 4) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 140, height: 196)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .shadow(radius: 4)
                                Text(stepLabel(key))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }

    private func stepLabel(_ key: String) -> String {
        switch key {
        case "front_flat": "Front"
        case "back_flat": "Back"
        case "front_angled": "Angled"
        case "corners_top": "Top Corners"
        case "corners_bottom": "Bottom Corners"
        case "edges": "Edges"
        default: key
        }
    }

    // MARK: - Grade Header

    private var gradeHeader: some View {
        VStack(spacing: 8) {
            Text("ESTIMATED GRADE")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.7))

            if let psa = record.psaRange {
                Text("PSA \(psa)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            if let bgs = record.bgsRange {
                Text("BGS \(bgs)")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.summaryGradient)
        )
    }

    // MARK: - Sub-Scores

    private var subScoresSection: some View {
        VStack(spacing: 12) {
            Text("Sub-Grades")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            scoreRow(label: "Centering", score: record.centeringScore, notes: record.centeringNotes)
            scoreRow(label: "Corners", score: record.cornersScore, notes: record.cornersNotes)
            scoreRow(label: "Edges", score: record.edgesScore, notes: record.edgesNotes)
            scoreRow(label: "Surface", score: record.surfaceScore, notes: record.surfaceNotes)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func scoreRow(label: String, score: Double, notes: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(format: "%.1f", score))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(scoreColor(score))
                Text("/ 10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.tertiarySystemFill))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(scoreColor(score))
                        .frame(width: geo.size.width * CGFloat(score / 10.0))
                }
            }
            .frame(height: 6)

            if let notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Centering

    private var centeringSection: some View {
        VStack(spacing: 8) {
            Text("Centering Detail")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 16) {
                if record.frontCenteringLR != nil || record.frontCenteringTB != nil {
                    centeringBox(title: "Front", lr: record.frontCenteringLR, tb: record.frontCenteringTB)
                }
                if record.backCenteringLR != nil || record.backCenteringTB != nil {
                    centeringBox(title: "Back", lr: record.backCenteringLR, tb: record.backCenteringTB)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func centeringBox(title: String, lr: String?, tb: String?) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            if let lr {
                HStack(spacing: 4) {
                    Text("L/R:").font(.caption).foregroundStyle(.secondary)
                    Text(lr).font(.caption.weight(.semibold).monospacedDigit())
                }
            }
            if let tb {
                HStack(spacing: 4) {
                    Text("T/B:").font(.caption).foregroundStyle(.secondary)
                    Text(tb).font(.caption.weight(.semibold).monospacedDigit())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Confidence

    private var confidenceBadge: some View {
        HStack {
            Image(systemName: confidenceIcon)
                .foregroundStyle(confidenceColor)
            Text("\(record.confidence.capitalized) Confidence")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(confidenceColor)
            Spacer()
        }
        .padding(14)
        .background(confidenceColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var confidenceIcon: String {
        switch record.confidence {
        case "high": "checkmark.shield.fill"
        case "medium": "shield.lefthalf.filled"
        default: "shield"
        }
    }

    private var confidenceColor: Color {
        switch record.confidence {
        case "high": .green
        case "medium": .orange
        default: .red
        }
    }

    // MARK: - Interpretation

    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { showTips.toggle() }
            } label: {
                HStack {
                    Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                    Text("Grade Interpretation Guide")
                        .font(.headline).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: showTips ? "chevron.up" : "chevron.down")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            if showTips {
                VStack(alignment: .leading, spacing: 10) {
                    tipRow(number: 1, text: "If corners show whitening or fuzzing under a loupe, expect 0.5-1 point lower")
                    tipRow(number: 2, text: "Surface scratches only visible at certain angles may drop the grade by 1 point")
                    tipRow(number: 3, text: "AI cannot detect micro-defects requiring 10x loupe magnification")
                    tipRow(number: 4, text: "Centering is the most reliably measured attribute from photos")
                    tipRow(number: 5, text: "PSA grades by the weakest sub-grade; BGS averages all four")
                    tipRow(number: 6, text: "Cannot reliably distinguish PSA 9 from PSA 10 — these require professional grading")

                    if !record.tips.isEmpty {
                        Divider()
                        Text("AI Suggestions")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.accent)
                        ForEach(record.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.right.circle")
                                    .font(.caption).foregroundStyle(theme.accent)
                                Text(tip).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func tipRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(theme.accent.opacity(0.7))
                .clipShape(Circle())
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: - Defects

    private var defectsSection: some View {
        let allDefects = record.centeringDefects + record.cornersDefects + record.edgesDefects + record.surfaceDefects
        return Group {
            if !allDefects.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Defects Found")
                            .font(.headline)
                    }
                    ForEach(allDefects, id: \.self) { defect in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 5))
                                .foregroundStyle(.orange)
                                .padding(.top, 5)
                            Text(defect)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 8.0 { return .green }
        if score >= 6.0 { return .orange }
        return .red
    }
}
