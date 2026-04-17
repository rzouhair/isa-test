import SwiftUI
import UIKit
import SwiftData

@MainActor @Observable
final class GradingViewModel {
    let cameraService = CameraService()
    private let gradingService: GradingServiceProtocol = DIContainer.shared.gradingService
    private let analytics: AnalyticsServiceProtocol = DIContainer.shared.analyticsService
    private let crashReporting: CrashReportingServiceProtocol = DIContainer.shared.crashReportingService

    // MARK: - Flow State

    enum FlowPhase: Equatable {
        case capturing
        case reviewing   // shows captured image with retake/next
        case processing
        case results
        case error
    }

    var phase: FlowPhase = .capturing
    var currentStepIndex: Int = 0
    var capturedImages: [GradingStep: UIImage] = [:]

    // Processing
    var processingMessage: String = "Uploading images..."

    // Results
    var gradeResult: GradeResponse?
    var errorMessage: String?

    // Camera
    var cropRect: CGRect = .zero
    var screenSize: CGSize = .zero
    var showCaptureFlash = false
    var selectedZoom: CGFloat = 1.0

    let zoomLevels: [CGFloat] = [1, 2, 3]

    // MARK: - Computed

    var currentStep: GradingStep {
        GradingStep(rawValue: currentStepIndex) ?? .frontFlat
    }

    var allSteps: [GradingStep] {
        GradingStep.allCases
    }

    var requiredStepsDone: Bool {
        GradingStep.allCases
            .filter(\.isRequired)
            .allSatisfy { capturedImages[$0] != nil }
    }

    var totalCaptured: Int {
        capturedImages.count
    }

    var isLastStep: Bool {
        currentStepIndex == GradingStep.allCases.count - 1
    }

    // MARK: - Lifecycle

    func setup() {
        cameraService.onPhotoCaptured = { [weak self] image in
            self?.handleCapture(image)
        }
        cameraService.start()
    }

    func teardown() {
        cameraService.stop()
    }

    // MARK: - Camera

    func setZoom(_ factor: CGFloat) {
        selectedZoom = factor
        cameraService.zoomFactor = factor
    }

    func capture() {
        analytics.capture(.gradingStepCaptured, properties: ["step": currentStep.apiKey])
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        showCaptureFlash = true
        withAnimation(.easeOut(duration: 0.1)) { showCaptureFlash = false }
        cameraService.capturePhoto()
    }

    private func handleCapture(_ image: UIImage) {
        let cropSnapshot = cropRect
        let sizeSnapshot = screenSize
        let step = currentStep

        Task.detached(priority: .userInitiated) {
            let cropped = ScannerViewModel.cropImage(image, cropRect: cropSnapshot, screenSize: sizeSnapshot) ?? image
            let optimized = ScannerViewModel.optimizeImage(cropped)
            await MainActor.run {
                self.capturedImages[step] = optimized
                self.phase = .reviewing
            }
        }
    }

    // MARK: - Navigation

    func retake() {
        capturedImages.removeValue(forKey: currentStep)
        phase = .capturing
    }

    func nextStep() {
        if isLastStep {
            submitAll()
        } else {
            currentStepIndex += 1
            phase = .capturing
        }
    }

    func skipStep() {
        guard !currentStep.isRequired else { return }
        if isLastStep {
            submitAll()
        } else {
            currentStepIndex += 1
            phase = .capturing
        }
    }

    func previousStep() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        phase = capturedImages[currentStep] != nil ? .reviewing : .capturing
    }

    func submitEarly() {
        guard requiredStepsDone else { return }
        submitAll()
    }

    // MARK: - Submit

    private func submitAll() {
        phase = .processing
        processingMessage = "Uploading images..."

        Task {
            // Start cycling messages
            let messageTask = Task {
                let messages = [
                    "Uploading images...",
                    "Analyzing centering...",
                    "Evaluating corners...",
                    "Inspecting edges...",
                    "Assessing surface...",
                    "Calculating grade..."
                ]
                var index = 1
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(1.5))
                    if !Task.isCancelled {
                        await MainActor.run {
                            self.processingMessage = messages[index % messages.count]
                        }
                        index += 1
                    }
                }
            }

            do {
                let request = buildRequest()
                let response = try await gradingService.submitGrade(request: request)

                messageTask.cancel()
                gradeResult = response
                phase = .results
                analytics.capture(.gradingCompleted, properties: [
                    "confidence": response.estimatedGrade.confidence,
                    "psa_range": response.estimatedGrade.psaRange
                ])
            } catch {
                messageTask.cancel()
                errorMessage = error.localizedDescription
                phase = .error
                analytics.capture(.gradingFailed, properties: ["error": error.localizedDescription])
                crashReporting.captureError(error, context: [
                    "action": "grading_submit",
                    "steps_captured": capturedImages.count
                ])
            }
        }
    }

    private func buildRequest() -> GradeRequest {
        func payload(for step: GradingStep) -> GradeImagePayload? {
            guard let image = capturedImages[step],
                  let data = image.jpegData(compressionQuality: 0.6) else { return nil }
            return GradeImagePayload(base64: data.base64EncodedString())
        }

        return GradeRequest(
            frontFlat: payload(for: .frontFlat)!,
            backFlat: payload(for: .backFlat)!,
            frontAngled: payload(for: .frontAngled),
            cornersTop: payload(for: .cornersTop),
            cornersBottom: payload(for: .cornersBottom),
            edges: payload(for: .edges)
        )
    }

    // MARK: - Save

    func saveGradeRecord(modelContext: ModelContext) {
        guard let result = gradeResult else { return }

        let record = GradeRecord()
        record.update(from: result)

        // Save captured images to disk (store relative paths so they survive app reinstalls)
        var imagePaths: [String: String] = [:]
        let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let gradesDir = docsURL.appendingPathComponent("Grades", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: gradesDir, withIntermediateDirectories: true)
        } catch {
            crashReporting.captureError(error, context: ["action": "create_grades_directory"])
        }

        for (step, image) in capturedImages {
            if let data = image.jpegData(compressionQuality: 0.6) {
                let relativePath = "Grades/\(record.id)_\(step.apiKey).jpg"
                let fullURL = docsURL.appendingPathComponent(relativePath)
                do {
                    try data.write(to: fullURL)
                    imagePaths[step.apiKey] = relativePath
                } catch {
                    crashReporting.captureError(error, context: [
                        "action": "grade_image_write",
                        "step": step.apiKey
                    ])
                }
            }
        }
        record.storeCapturedImagePaths(imagePaths)

        modelContext.insert(record)
        do {
            try modelContext.save()
        } catch {
            crashReporting.captureError(error, context: ["action": "grade_record_save"])
        }

        analytics.capture(.gradingSaved)
    }

    // MARK: - Reset

    func gradeAnother() {
        capturedImages.removeAll()
        currentStepIndex = 0
        gradeResult = nil
        errorMessage = nil
        phase = .capturing
    }

    func retrySubmission() {
        errorMessage = nil
        submitAll()
    }
}
