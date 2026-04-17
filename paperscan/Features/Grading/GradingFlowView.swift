import SwiftUI
import SwiftData
import Inject

struct GradingFlowView: View {
    @ObserveInjection var inject
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(Router.self) private var router

    @State private var viewModel = GradingViewModel()

    var body: some View {
        ZStack {
            if viewModel.phase == .capturing || viewModel.phase == .reviewing {
                GradingCaptureView(viewModel: viewModel)
                    .id("capture")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            if viewModel.phase == .processing {
                GradingProcessingView(message: viewModel.processingMessage)
                    .id("processing")
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }

            if viewModel.phase == .results, let result = viewModel.gradeResult {
                GradingResultsView(
                    result: result,
                    onSave: {
                        viewModel.saveGradeRecord(modelContext: modelContext)
                        closeFlow()
                    },
                    onGradeAnother: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            viewModel.gradeAnother()
                        }
                    }
                )
                .id("results")
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            if viewModel.phase == .error {
                errorView
                    .id("error")
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: viewModel.phase)
        .onAppear { viewModel.setup() }
        .onDisappear { viewModel.teardown() }
        .statusBarHidden()
        .enableInjection()
    }

    // MARK: - Error

    private var errorView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Grading Failed")
                .font(.title2.weight(.bold))

            if let msg = viewModel.errorMessage {
                Text(msg)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 12) {
                Button {
                    withAnimation { viewModel.retrySubmission() }
                } label: {
                    Text("Retry")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.accent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    closeFlow()
                } label: {
                    Text("Close")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func closeFlow() {
        viewModel.teardown()
        router.dismissFullscreenCover()
    }
}
