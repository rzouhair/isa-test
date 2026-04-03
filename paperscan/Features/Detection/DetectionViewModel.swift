//
//  DetectionViewModel.swift
//  paperscan
//

import SwiftUI
import Observation
import SwiftData
import StoreKit

private var hasRequestedReviewThisSession = false

extension DetectionView {
    @Observable
    class ViewModel {
        var context: ModelContext
        var router: Router
        var images: [UIImage]
        var isErrorModalPresented: Bool = false
        var currentMessageIndex = 0
        let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

        var progressMessages: [String] {
            [
                "Processing image...",
                "Analyzing details...",
                "Extracting information...",
                "Identifying features...",
                "Finalizing results...",
            ]
        }

        init(context: ModelContext, router: Router, images: [UIImage] = []) {
            self.images = images
            self.context = context
            self.router = router
        }

        // MARK: - Detection

        func detect() async {
            do {
                let (imageNames, base64Images) = try processImages()

                guard !base64Images.isEmpty else {
                    throw DetectionError.noValidImages
                }

                let data = try await sendRequest(base64Images: base64Images)
                let result = try parseResponse(data: data, imageNames: imageNames)

                context.insert(result)
                try context.save()

                requestReviewIfNeeded()

                router.navigateToRoot()
                // TODO: Navigate to a detail view for the result
                // router.presentFullscreenCover(.detectionResult(result: result))
            } catch {
                print("Detection error: \(error)")
                isErrorModalPresented = true
            }
        }

        // MARK: - Image Processing

        private func processImages() throws -> ([String], [String]) {
            var imageNames: [String] = []
            var base64Images: [String] = []
            let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

            for (index, image) in images.enumerated() {
                guard let resized = image.resized(toHeight: 512),
                      let compressed = resized.jpegData(compressionQuality: 0.5) else {
                    continue
                }

                // Save locally at higher quality
                let name = "detection_\(UUID().uuidString)_\(index)"
                imageNames.append(name)
                let saveData = image.resized(toHeight: 750)?.jpegData(compressionQuality: 0.8) ?? compressed
                try saveData.write(to: documentsDir.appendingPathComponent(name))

                base64Images.append("data:image/jpeg;base64," + compressed.base64EncodedString())
            }

            return (imageNames, base64Images)
        }

        // MARK: - Network

        private func sendRequest(base64Images: [String]) async throws -> Data {
            guard let url = URL(string: Constants.proxyLambdaURL) else {
                throw DetectionError.invalidURL
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 180
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let payload: [String: Any] = [
                "images": base64Images,
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw DetectionError.requestFailed
            }

            return data
        }

        // MARK: - Parsing

        private func parseResponse(data: Data, imageNames: [String]) throws -> DetectionResult {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success,
                  let structured = json["structured_data"] as? [String: Any] else {
                throw DetectionError.invalidResponse
            }

            // TODO: Adapt parsing to your API response structure
            let title = structured["denomination"] as? String
                ?? structured["title"] as? String
                ?? structured["name"] as? String
                ?? "Unknown"
            let subtitle = structured["issuer"] as? String
                ?? structured["subtitle"] as? String
                ?? ""
            let category = structured["type"] as? String
                ?? structured["category"] as? String
                ?? ""
            let date = structured["year"] as? String
                ?? structured["date"] as? String
                ?? ""

            // Store full response as raw JSON for flexibility
            let rawJSON = String(data: data, encoding: .utf8)

            let result = DetectionResult(
                title: title,
                subtitle: subtitle,
                category: category,
                date: date,
                imageNames: imageNames,
                rawJSON: rawJSON
            )

            // Extract key-value details from structured data
            let detailKeys = ["composition", "size", "shape", "serial_number", "currency", "rarity_index"]
            for key in detailKeys {
                if let value = structured[key] as? String ?? (structured[key].map { "\($0)" }) {
                    let detail = DetectionDetail(key: key.replacingOccurrences(of: "_", with: " ").capitalized, value: value)
                    detail.result = result
                    result.details.append(detail)
                }
            }

            return result
        }

        // MARK: - Review

        private func requestReviewIfNeeded() {
            guard !hasRequestedReviewThisSession,
                  !DIContainer.shared.userRepository.wasReviewPrompted() else { return }

            hasRequestedReviewThisSession = true
            DIContainer.shared.userRepository.setReviewPrompted()

            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }
        }
    }
}

// MARK: - Errors

enum DetectionError: LocalizedError {
    case noValidImages
    case invalidURL
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noValidImages: return "No valid images to process"
        case .invalidURL: return "Invalid API URL"
        case .requestFailed: return "Request failed"
        case .invalidResponse: return "Invalid response from server"
        }
    }
}
