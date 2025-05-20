//
//  BanknoteDetectionViewModel.swift
//  paperscan
//
//  Created by user on 27/3/2025.
//

import SwiftUI
import Observation
import SwiftData

extension BanknoteDetectionView {
    @Observable
    class ViewModel {
        var aiService: AIService
        var context: ModelContext
        var router: Router
        
        init(aiService: AIService, context: ModelContext, router: Router, images: [UIImage] = []) {
            self.images = images
            self.aiService = aiService
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
                var imagesDescriptionMessagesContent = [
                    MessageContent(text: BanknoteDetectionPrompt.system)
                ]
                
                var imagesNames: [String] = []
                
                for (index, image) in images.enumerated() {
                    let resizedImage = image.resized(toHeight: 750)!
                    if let imageData = resizedImage.jpegData(compressionQuality: 0.8) {
                        let uniqueId = UUID().uuidString
                        let imageName = "banknote_\(uniqueId)_\(index)"
                        imagesNames.append(imageName)
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let imageUrl = documentsDirectory.appendingPathComponent(imageName)
                        try? imageData.write(to: imageUrl)
                    }
                    imagesDescriptionMessagesContent.append(
                        .init(imageURL: resizedImage.toBase64(quality: 0.7)!)
                    )
                }

                let messages: [Message] = [
                    Message(role: .system, content: BanknoteDetectionPrompt.user),
                    Message(
                        role: .user,
                        content: imagesDescriptionMessagesContent
                    )
                ]
                
                currentStep = "image"
                guard let imageDescriptionResponse = try await self.aiService.sendMessage(
                    "Analyze the banknote images in detail",
                    initialMessages: messages
                ) else {
                    print("No image description response")
                    return
                }
                print("Step 1: Got image description response")

                guard let imageDescription = imageDescriptionResponse.last?.content.description else {
                    print("No description image")
                    throw AIServiceError.invalidResponse
                }
                
                #if DEBUG
                    print("Step 2: Extracted image description")
                    print(imageDescription)
                    print("===================")
                #endif

                currentStep = "details"
                guard let detectedBanknote: DetectedBanknote = await self.aiService.sendToolCompletion(
                    prompt: "Extract the banknote details from the description: \(imageDescription)",
                    tools: [ItemDetectionFunction.toFunctionDefinition()]
                ) else {
                    throw AIServiceError.invalidResponse
                }                

                #if DEBUG
                    print("Step 3: Detected banknote details")
                    print(detectedBanknote)
                #endif

                let banknoteIdentifier = detectedBanknote.name ?? "\(String(describing: detectedBanknote.country))'s \(detectedBanknote.year != nil ? String(detectedBanknote.year ?? "0") : "") \(String(describing: detectedBanknote.title))" ?? "Not available"
                currentStep = "valuation"
                let (valuationWebSearch, rarityWebSearch, gradingResponse): (CitationResult?, CitationResult?, [Message]?) = await (
                    self.aiService.sendWebSearch(
                        prompt: BanknoteDetectionPrompt.valuation(banknote: banknoteIdentifier.description)
                    ),
                    self.aiService.sendWebSearch(
                        prompt: BanknoteDetectionPrompt.rarity(banknote: banknoteIdentifier.description)
                    ),
                    try self.aiService.sendMessage(
                        BanknoteDetectionPrompt.grading(specs: detectedBanknote.fullSpecsList),
                        initialMessages: []
                    )
                )

                guard let valuationWebSearch = valuationWebSearch, let rarityWebSearch = rarityWebSearch else {
                    print("Couldn't fetch web search results")
                    throw AIServiceError.invalidResponse
                }
                currentStep = "description"
                
                #if DEBUG
                print("Step 4: Completed web search for valuation")
                print(detectedBanknote.fullSpecsList)
                print(gradingResponse?.last?.content.description)

                    print("======")
                    print("Step 5: Extracted valuation details")
                    print("Step 6: Completed web search for rarity")
                    print("======")
                #endif
                
                let (detectedGrade, detectedValuation, detectedRarity): (DetectedGrade?, DetectedValuation?, DetectedBanknoteRarity?) = await (
                    self.aiService.sendToolCompletion(
                        prompt: "Extract the banknote grade information from the following response results: \(gradingResponse?.last?.content.description ?? "")",
                        tools: [ItemGradeFunction.toFunctionDefinition()]
                    ),
                    self.aiService.sendToolCompletion(
                        prompt: "Extract the banknote valuation details from the given websearch: \(valuationWebSearch.text)",
                        tools: [ItemValuationFunction.toFunctionDefinition()]
                    ),
                    self.aiService.sendToolCompletion(
                        prompt: "Extract the banknote rarity score from 0-100 from the following websearch results: \(rarityWebSearch.text.removeMarkdownLinks())",
                        tools: [ItemRarityFunction.toFunctionDefinition()]
                    )
                )
                
                guard let detectedValuation = detectedValuation, let detectedRarity = detectedRarity else {
                    if (detectedValuation == nil) {
                        print("Couldn't fetch valuation")
                    } else if (detectedRarity == nil) {
                        print("Couldn't fetch rarity")
                    }
                    throw AIServiceError.invalidResponse
                }
                
                #if DEBUG
                    print("Step 7: Extracted rarity details")
                            

                    print("=== Detected banknote ===")
                    print(detectedBanknote)
                    print("=======================")
                    
                    print("=== Detected valuation ===")
                    print(detectedValuation)
                    print("=======================")
                    
                    print("=== Detected Rarity ===")
                    print(detectedRarity)
                    print("=======================")
                    
                    print("=== Detected Grade ===")
                    print(detectedGrade)
                    print("=======================")
                #endif

                let createdBanknote = Banknote(
                    country: detectedBanknote.country ?? "Unknown",
                    title: detectedBanknote.title ?? "Unknown",
                    serialNumber: detectedBanknote.serialNumber ?? "Unknown",
                    issueDate: detectedBanknote.year ?? "n/a",
                    rarity: detectedRarity.rarity?.description ?? "n/a",
                    uncirculatedPriceRange: detectedValuation.uncirculated,
                    circulatedPriceRange: detectedValuation.circulated,
                    designElements: detectedBanknote.designElements ?? [],
                    imageNames: imagesNames,
                    sources: [
                        "rarity": rarityWebSearch.citations,
                        "valuation": valuationWebSearch.citations,
                    ],
                    grade: [
                        "grade": detectedGrade?.grade ?? "n/a",
                        "gradeLabel": detectedGrade?.gradeLabel ?? "n/a",
                        "gradingScale": detectedGrade?.gradingScale ?? "n/a",
                        "justification": detectedGrade?.justification ?? "n/a",
                        "notableStrengths": detectedGrade?.notableStrengths ?? "n/a",
                        "notableFlaws": detectedGrade?.notableFlaws ?? "n/a",
                    ]
                )
                
                if let specifications = detectedBanknote.specifications {
                    for spec in specifications {
                        let createdSpec = Specification(title: spec.title, value: spec.value)
                        createdSpec.banknote = createdBanknote
                        createdBanknote.specifications.append(createdSpec)
                    }
                }
                
                self.context.insert(createdBanknote)
                
                do {
                    try self.context.save()
                    
                } catch {
                    print("Error saving context: \(error.localizedDescription)")
                }
                
                let descriptor = FetchDescriptor<Banknote>(sortBy: [SortDescriptor(\.id, order: .reverse)])
                
                self.router.navigateToRoot()
                self.router.presentFullscreenCover(.banknoteDetails(banknote: createdBanknote))
                
            } catch {
                isErrorModalPresented = true
                print("Error during banknote detection: \(error.localizedDescription)")
            }
        }
    }
}
