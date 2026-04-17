import SwiftUI
import Inject
import UIKit

struct ScanCorrectionSheet: View {
    @ObserveInjection var inject
    @Environment(\.dismiss) private var dismiss
    let record: ScanRecord
    let scanStore: ScanStore

    @State private var viewModel = ScanCorrectionViewModel()
    @State private var capturedImage: UIImage?

    var body: some View {
        NavigationView {
            Group {
                switch viewModel.loadState {
                case .loading:   loadingView
                case .expired:   expiredView
                case .failed(let msg): errorView(msg)
                case .loaded(let candidates): loadedView(candidates)
                }
            }
            .navigationTitle("Correct Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            guard let url = ScanStore.resolveImageURL(record.capturedImagePath) else { return }
            capturedImage = await Task.detached(priority: .utility) {
                guard let data = try? Data(contentsOf: url) else { return nil }
                return UIImage(data: data)
            }.value
        }
        .task {
            guard let jobId = record.jobId else { viewModel.loadState = .expired; return }
            await viewModel.load(jobId: jobId)
        }
        .enableInjection()
    }

    // MARK: - States

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading candidates…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var expiredView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Scan expired")
                .font(.headline)
            Text("The job result is no longer available. Re-scan the card to identify it again.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Re-scan") {
                scanStore.retryFailed(record)
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(Color(.systemOrange))
            Text("Something went wrong")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Loaded

    private func loadedView(_ candidates: [Candidate]) -> some View {
        VStack(spacing: 0) {
            capturedHeader

            List {
                Section {
                    ForEach(Array(candidates.enumerated()), id: \.offset) { _, candidate in
                        candidateRow(candidate: candidate)
                            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                } header: {
                    Text("\(candidates.count) candidates found")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)

            confirmBar(candidates: candidates)
        }
    }

    // MARK: - Captured Header

    private var capturedHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let img = capturedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.secondarySystemBackground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .clipped()

            Label("Captured Input", systemImage: "camera")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding(12)
        }
    }

    // MARK: - Candidate Row

    private func candidateRow(candidate: Candidate) -> some View {
        let isSelected = viewModel.selectedProductId == candidate.productId
        return Button {
            viewModel.selectedProductId = candidate.productId
        } label: {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: candidate.image ?? "")) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.tertiarySystemFill))
                }
                .frame(width: 48, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 3) {
                    Group {
                        if let variant = candidate.variant, !variant.isEmpty, variant.uppercased() != "STANDARD" {
                            Text("\(candidate.name ?? "Unknown") (\(variant))")
                        } else {
                            Text(candidate.name ?? "Unknown")
                        }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                    if let set = candidate.setName {
                        Text([set, candidate.cardNumber].compactMap { $0 }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let price = candidate.marketPrice ?? candidate.lowestPrice {
                        Text(String(format: "$%.2f", price))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(theme.value)
                    }
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 6) {
                    if let confidence = candidate.confidence {
                        Text("\(Int(confidence * 100))%")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(isSelected ? theme.value : .secondary)
                    }
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? theme.value : Color(.tertiaryLabel))
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm Bar

    private func confirmBar(candidates: [Candidate]) -> some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                guard let id = viewModel.selectedProductId,
                      let candidate = candidates.first(where: { $0.productId == id })
                else { return }
                scanStore.applyCandidate(candidate, to: record)
                dismiss()
            } label: {
                Text("Confirm Selection")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedProductId == nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}
