//
//  BanknoteDetectionViewModel.swift
//  paperscan
//
//  Created by user on 27/3/2025.
//

import SwiftUI
import Observation
import SwiftData
import StoreKit

// Static flag to track if review has been requested in this app session
private var hasRequestedReviewThisSession = false

extension BanknoteDetectionView {
    @Observable
    class ViewModel {
        var context: ModelContext
        var router: Router
        
        init(context: ModelContext, router: Router, images: [UIImage] = []) {
            self.images = images
            self.context = context
            self.router = router
        }
        
        var isErrorModalPresented: Bool = false
        
        var images: [UIImage] = []
        var currentMessageIndex = 0
        var messages = [
            "image": [
                "Processing banknote image...",
                "Analyzing image quality...",
                "Detecting banknote features..."
            ],
            "description": [
                "Generating detailed description...",
                "Identifying key characteristics...",
                "Analyzing visual elements..."
            ],
            "details": [
                "Extracting banknote information...",
                "Validating note patterns...",
                "Confirming authenticity..."
            ],
            "valuation": [
                "Researching market value...",
                "Analyzing condition impact...",
                "Finalizing valuation..."
            ]
        ]
        var currentStep: String = "image"
        var progressMessages: [String] {
            return messages[currentStep] ?? []
        }
        
        // Timer for message rotation
        let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
        
        var showFront = true
        var flipTimer: Timer?
        let flipInterval: TimeInterval = 3 // Configurable flip interval

        func startFlipTimer() {
            flipTimer = Timer.scheduledTimer(withTimeInterval: flipInterval, repeats: true) { _ in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    self.showFront.toggle()
                }
            }
        }

        func stopFlipTimer() {
            flipTimer?.invalidate()
            flipTimer = nil
        }
        
        func detectBanknotes() async {
            do {
                print("Step 1: Starting banknote detection process")
                var imagesNames: [String] = []
                var base64Images: [String] = []
                
                // Process and save images
                print("Step 2: Processing \(images.count) images")
                for (index, image) in images.enumerated() {
                    do {
                        print("Processing image \(index): original size \(image.size.width)x\(image.size.height), scale: \(image.scale)")
                        
                        let resizedImage = image.resized(toHeight: 750)!
                        print("Image \(index) resized to \(resizedImage.size.width)x\(resizedImage.size.height)")
                        
                        if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                            print("Image \(index) compressed to \(imageData.count) bytes")
                            // Save image to documents directory
                            let uniqueId = UUID().uuidString
                            let imageName = "banknote_\(uniqueId)_\(index)"
                            imagesNames.append(imageName)
                            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                            let imageUrl = documentsDirectory.appendingPathComponent(imageName)
                            try imageData.write(to: imageUrl)
                            print("Step 2.\(index+1): Saved image to \(imageUrl.path)")
                            
                            // Convert to base64 for API
                            if let base64String = resizedImage.toBase64(quality: 0.7) {
                                base64Images.append(base64String)
                                print("Step 2.\(index+1): Converted image to base64 (length: \(base64String.count))")
                                
                                // Log first 100 and last 100 characters of base64 string for debugging
                                if base64String.count > 200 {
                                    let prefix = String(base64String.prefix(100))
                                    let suffix = String(base64String.suffix(100))
                                    print("Base64 image \(index) preview: \(prefix)...\(suffix)")
                                } else {
                                    print("Base64 image \(index) full: \(base64String)")
                                }
                            } else {
                                print("Warning: Failed to convert image \(index) to base64")
                            }
                        } else {
                            print("Warning: Failed to compress image \(index)")
                        }
                    } catch {
                        print("Error processing image \(index): \(error.localizedDescription)")
                    }
                }
                
                if base64Images.isEmpty {
                    print("Error: No valid images to process")
                    throw NSError(domain: "No valid images", code: 1)
                }
                
                currentStep = "image"
                print("Step 3: Preparing Lambda request with \(base64Images.count) images")
                
                // Create request for Lambda function
                guard let lambdaURL = URL(string: Constants.proxyLambdaURL) else {
                    print("Error: Invalid Lambda URL: \(Constants.proxyLambdaURL)")
                    throw NSError(domain: "Invalid Lambda URL", code: 2)
                }
                
                var request = URLRequest(url: lambdaURL)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                // Prepare request payload
                let payload: [String: Any] = [
                    "images": base64Images,
                    "process_numista": true
                ]
                
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
                    print("Step 4: Payload prepared successfully, size: \(request.httpBody?.count ?? 0) bytes")
                    
                    // Log total image count and sizes
                    print("Total images in payload: \(base64Images.count)")
                    for (index, image) in base64Images.enumerated() {
                        print("Image \(index) size: \(image.count) characters")
                    }
                } catch {
                    print("Error preparing request payload: \(error.localizedDescription)")
                    throw error
                }
                
                // Make request to Lambda
                currentStep = "details"
                print("Step 5: Sending request to Lambda endpoint")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Error: Not an HTTP response")
                    throw NSError(domain: "Invalid response type", code: 3)
                }
                
                print("Step 6: Received response with status code: \(httpResponse.statusCode)")
                print("Response headers: \(httpResponse.allHeaderFields)")
                
                if httpResponse.statusCode != 200 {
                    if let responseText = String(data: data, encoding: .utf8) {
                        print("Error response: \(responseText)")
                    }
                    throw NSError(domain: "Lambda request failed with code \(httpResponse.statusCode)", code: 4)
                }
                
                // Log full response for debugging
                if let responseText = String(data: data, encoding: .utf8) {
                    if responseText.count > 1000 {
                        print("Response preview (first 500 chars): \(String(responseText.prefix(500)))")
                        print("Response preview (last 500 chars): \(String(responseText.suffix(500)))")
                    } else {
                        print("Full response: \(responseText)")
                    }
                }
                
                // Parse response from Lambda
                print("Step 7: Parsing Lambda response, data size: \(data.count) bytes")
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("Error: Could not parse JSON response")
                        if let responseText = String(data: data, encoding: .utf8) {
                            print("Raw response: \(responseText)")
                        }
                        throw NSError(domain: "Invalid JSON response", code: 5)
                    }
                    
                    print("Step 8: Successfully parsed JSON response")
                    
                    guard let success = json["success"] as? Bool, success else {
                        print("Error: Lambda reported failure: \(json["error"] ?? "Unknown error")")
                        throw NSError(domain: "Lambda processing failed", code: 6)
                    }
                    
                    guard let structuredData = json["structured_data"] as? [String: Any] else {
                        print("Error: Missing structured_data in response")
                        print("Response keys: \(json.keys.joined(separator: ", "))")
                        throw NSError(domain: "Missing structured data", code: 7)
                    }
                    
                    print("Step 9: Successfully extracted structured data")
                    
                    #if DEBUG
                        print("Lambda response received:")
                        print(structuredData)
                    #endif
                    
                    // Extract banknote information
                    let year = structuredData["year"] as? String ?? "Unknown"
                    let denomination = structuredData["denomination"] as? String ?? "Unknown"
                    let issuer = structuredData["issuer"] as? String ?? "Unknown"
                    let type = structuredData["type"] as? String ?? "Unknown"
                    let currency = structuredData["currency"] as? String ?? "Unknown"
                    let serialNumber = structuredData["serial_number"] as? String ?? "Unknown"
                    let rarityIndex = structuredData["rarity_index"] as? Int ?? 0
                    let numistUrl = json["numista_url"] as? String
                    
                    print("Step 10: Extracted basic banknote details")
                    print("Year: \(year), Issuer: \(issuer), Serial: \(serialNumber), Rarity: \(rarityIndex)")
                    
                    // Create specifications
                    var specifications: [[String: String]] = []
                    
                    if let composition = structuredData["composition"] as? String {
                        specifications.append(["title": "Composition", "value": composition])
                    }
                    
                    if let size = structuredData["size"] as? String {
                        specifications.append(["title": "Size", "value": size])
                    }
                    
                    if let shape = structuredData["shape"] as? String {
                        specifications.append(["title": "Shape", "value": shape])
                    }
                    
                    if let number = structuredData["number"] as? String {
                        specifications.append(["title": "Number", "value": number])
                    }
                    
                    print("Step 11: Created \(specifications.count) specifications")
                    
                    // Extract sales information for valuation
                    currentStep = "valuation"
                    var minPrice = 0.0
                    var maxPrice = 0.0
 
                    var uncirculatedPriceRange = "Unknown"
                    var circulatedPriceRange = "Unknown"
                    
                    // Check if sales_summary exists, if not build it from sales data
                    if let salesSummary = structuredData["sales_summary"] as? [String: Any],
                       let otherPrices = salesSummary["other_prices"] as? [String: Any],
                       let unc_prices = salesSummary["unc_prices"] as? [String: Any] {
                        // Use existing sales_summary
                        minPrice = otherPrices["min_price"] as? Double ?? 0.0
                        maxPrice = otherPrices["max_price"] as? Double ?? 0.0
                        uncirculatedPriceRange = unc_prices["formatted"] as? String ?? "Unknown"
                        circulatedPriceRange = otherPrices["formatted"] as? String ?? "Unknown"
                        
                        print("Step 12: Used existing sales_summary information")
                        print("Circulated: \(circulatedPriceRange), Uncirculated: \(uncirculatedPriceRange)")
                    } else if let sales = structuredData["sales"] as? [[String: Any]], !sales.isEmpty {
                        // Build sales_summary from sales data
                        print("Step 12a: Building sales_summary from sales data (\(sales.count) entries)")
                        
                        var uncPrices: [Double] = []
                        var otherPrices: [Double] = []
                        var currency = "$"
                        
                        // Group sales by grade
                        for sale in sales {
                            if let price = sale["price"] as? Double, price > 0 {
                                if let grade = sale["grade"] as? String, grade.uppercased() == "UNC" {
                                    uncPrices.append(price)
                                    print("Found UNC price: \(price)")
                                } else if let grade = sale["grade"] as? String, !grade.isEmpty {
                                    otherPrices.append(price)
                                    print("Found \(grade) price: \(price)")
                                }
                            }
                        }
                        
                        // Extract min and max for uncirculated
                        if !uncPrices.isEmpty {
                            let minUncPrice = uncPrices.min() ?? 0
                            let maxUncPrice = uncPrices.max() ?? 0
                            uncirculatedPriceRange = "\(minUncPrice)\(currency) - \(maxUncPrice)\(currency)"
                            print("Created UNC price range: \(uncirculatedPriceRange) from \(uncPrices.count) prices")
                        }
                        
                        // Extract min and max for circulated
                        if !otherPrices.isEmpty {
                            minPrice = otherPrices.min() ?? 0
                            maxPrice = otherPrices.max() ?? 0
                            circulatedPriceRange = "\(minPrice)\(currency) - \(maxPrice)\(currency)"
                            print("Created circulated price range: \(circulatedPriceRange) from \(otherPrices.count) prices")
                        }
                        
                        print("Step 12b: Successfully built sales_summary from sales data")
                    } else {
                        print("Warning: Could not extract or build sales information")
                        if let salesSummary = structuredData["sales_summary"] as? [String: Any] {
                            print("Available sales_summary keys: \(salesSummary.keys.joined(separator: ", "))")
                        } else {
                            print("No sales_summary or sales found in data")
                        }
                    }
                    
                    currentStep = "description"
                    
                    // Create citations for sources
                    let rarityCitations: [URLCitation] = numistUrl != nil ? 
                        [URLCitation(type: "none", startIndex: 0, endIndex: numistUrl!.count, url: numistUrl!, title: "Numista")] : []
                    let valuationCitations: [URLCitation] = numistUrl != nil ? 
                        [URLCitation(type: "none", startIndex: 0, endIndex: numistUrl!.count, url: numistUrl!, title: "Numista")] : []
                    
                    print("Step 13: Created citations from URL: \(numistUrl ?? "none")")
                    
                    // Create banknote object
                    print("Step 14: Creating banknote object")
                    
                    // Extract sales data for detailed display
                    var salesData: [[String: Any]] = []
                    if let sales = structuredData["sales"] as? [[String: Any]], !sales.isEmpty {
                        // Filter out header row and empty entries
                        salesData = sales.filter { sale in
                            if let grade = sale["grade"] as? String, grade.uppercased() == "GRADE" {
                                return false // Skip header row
                            }
                            return sale["price"] != nil // Keep only entries with prices
                        }
                        print("Step 14a: Extracted \(salesData.count) sales records for detailed display")
                    }
                    
                    // Convert to JSON string for storage
                    var salesDataJSON: String? = nil
                    if !salesData.isEmpty {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: salesData, options: [])
                            salesDataJSON = String(data: jsonData, encoding: .utf8)
                            print("Step 14b: Converted sales data to JSON string")
                        } catch {
                            print("Warning: Failed to convert sales data to JSON: \(error)")
                        }
                    }
                    
                    let createdBanknote = Banknote(
                        country: issuer,
                        title: denomination,
                        serialNumber: serialNumber,
                        issueDate: year,
                        rarity: String(rarityIndex),
                        uncirculatedPriceRange: uncirculatedPriceRange,
                        circulatedPriceRange: circulatedPriceRange,
                        designElements: [type, currency].filter { !$0.isEmpty },
                        imageNames: imagesNames,
                        sources: [
                            "rarity": rarityCitations,
                            "valuation": valuationCitations,
                        ],
                        salesData: salesDataJSON
                    )
                    
                    // Add specifications to banknote
                    print("Step 15: Adding \(specifications.count) specifications to banknote")
                    for spec in specifications {
                        if let title = spec["title"], let value = spec["value"] {
                            let createdSpec = Specification(title: title, value: value)
                            createdSpec.banknote = createdBanknote
                            createdBanknote.specifications.append(createdSpec)
                        }
                    }
                    
                    // Save banknote to database
                    print("Step 16: Saving banknote to database")
                    self.context.insert(createdBanknote)
                    
                    do {
                        try self.context.save()
                        print("Step 17: Successfully saved banknote to database")
                    } catch {
                        print("Error saving context: \(error.localizedDescription)")
                        throw error
                    }
                    
                    print("Step 18: Navigating to banknote details screen")
                    
                    // Check if we should request a review after successful detection
                    // Only show once per app launch and if user hasn't been prompted from onboarding
                    if !hasRequestedReviewThisSession && !DIContainer.shared.userRepository.wasReviewPrompted() {
                        // Mark that we've requested a review this session
                        hasRequestedReviewThisSession = true
                        
                        // Save that the user was prompted for a review
                        DIContainer.shared.userRepository.setReviewPrompted()
                        
                        // Request review in the main thread
                        DispatchQueue.main.async {
                            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                SKStoreReviewController.requestReview(in: windowScene)
                            }
                        }
                        
                        print("Step 18a: Requested app review after successful detection")
                    }
                    
                    self.router.navigateToRoot()
                    self.router.presentFullscreenCover(.banknoteDetails(banknote: createdBanknote))
                    print("Step 19: Banknote detection completed successfully")
                    
                } catch {
                    print("Error parsing Lambda response: \(error.localizedDescription)")
                    throw error
                }
                
            } catch {
                print("CRITICAL ERROR in banknote detection: \(error)")
                if let nsError = error as NSError? {
                    print("Domain: \(nsError.domain), Code: \(nsError.code)")
                    if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? NSError {
                        print("Underlying error: \(underlyingError)")
                    }
                }
                isErrorModalPresented = true
            }
        }
    }
}
