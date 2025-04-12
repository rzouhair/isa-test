//
//  BanknoteDetailsView.swift
//  notescan
//
//  Created by user on 27/3/2025.
//

import SwiftData
import SwiftUI

struct BanknoteDetailView: View {
    @State var banknote: Banknote
    @Environment(Router.self) private var router: Router
    @Environment(\.modelContext) private var context: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex = 0
    @State private var vm: ViewModel?
    @State private var showRarityCitations = false
    @State private var showValuationCitations = false
    
    init(banknote: Banknote) {
        self.banknote = banknote
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Image Carousel
                        imagesSection
                        
                        // Main Content
                        VStack(alignment: .leading, spacing: 0) {
                            headerSection
                                .modifier(SectionStyleModifier())
                                .padding(.top, 8)
                            
                            raritySection
                                .modifier(SectionStyleModifier())
                            
                            serialNumberSection
                                .modifier(SectionStyleModifier())
                            
                            valuationSection
                                .modifier(SectionStyleModifier())
                            
                            specificationsSection
                                .modifier(SectionStyleModifier())
                            
                            gradeSection
                                .modifier(SectionStyleModifier())

                            designDetailsSection
                                .modifier(SectionStyleModifier(showDivider: false))
                        }
                        .padding(.bottom, 120)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if router.navigationPath.isEmpty || router.presentedFullscreenCover == .banknoteDetails(banknote: banknote) {
                            Button {
                                router.dismissFullscreenCover()
                                dismiss()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundStyle(.primary)
                                    .imageScale(.large)
                            }
                        } else {
                            Button {
                                router.dismissFullscreenCover()
                                dismiss()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                }

                addToCollectionButton
                    .padding(.horizontal)
                    .padding(.vertical, 24)
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .ignoresSafeArea()
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            vm = ViewModel(banknote: banknote, context: context)
        }
    }
    
    private var addToCollectionButton: some View {
        Button {
            try? vm?.addToCollection(banknote: banknote)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: banknote.isCollected ? "checkmark.circle.fill" : "plus.circle.fill")
                Text(banknote.isCollected ? "In Collection" : "Add to Collection")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background {
                Capsule()
                    .fill(banknote.isCollected ? Color.green.gradient : Color.appPrimary.gradient)
                    .shadow(color: .primary.opacity(0.15), radius: 4)
            }
        }
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityHint(banknote.isCollected ? "Remove from collection" : "Add to your collection")
        .accessibilityLabel(banknote.isCollected ? "In collection" : "Add to collection")
    }
    
    // MARK: - Subviews
    
    private var imagesSection: some View {
        VStack(spacing: 0) {
            // Images TabView
            TabView(selection: $currentImageIndex) {
                if let viewModel = vm, !viewModel.images.isEmpty {
                    ForEach(viewModel.images.indices, id: \.self) { index in
                        Image(uiImage: viewModel.images[index])
                            .resizable()
                            .scaledToFit()
                            .tag(index)
                    }
                } else {
                    Text("No images available")
                }
            }
            .tabViewStyle(.page)
            .frame(height: 200)
            .overlay(alignment: .bottomTrailing) {
                if let viewModel = vm, !viewModel.images.isEmpty {
                    Text("\(currentImageIndex + 1)/\(banknote.imageNames.count)")
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(Capsule())
                        .padding()
                }
            }

            // Grading Banner
            if let grade = banknote.grade["grade"] {
                if (grade != "n/a") {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .top) {
                            if let scale = banknote.grade["gradingScale"] {
                                HStack (alignment: .center, spacing: 10) {
                                    Text(scale)
                                        .font(.system(size: 36, weight: .bold, design: .serif))
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(grade)
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(.black)
                                
                                if let label = banknote.grade["gradeLabel"] {
                                    Text(label)
                                        .font(.caption)
                                        .foregroundColor(.black.opacity(0.8))
                                }
                            }
                        }
                        
                        Text("This is an AI estimation and not a certified grade.")
                            .font(.caption2)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.855, green: 0.859, blue: 0.831))
                    .overlay(
                        VStack {
                            Rectangle().frame(height: 4).foregroundColor(Color(red: 0.396, green: 0.427, blue: 0.408))
                            Spacer()
                            Rectangle().frame(height: 4).foregroundColor(Color(red: 0.396, green: 0.427, blue: 0.408))
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading) {
            Text(banknote.fullName)
                .font(.title2.bold())
            
            Text(banknote.country)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
    
    private var raritySection: some View {
        Section {
            VStack(spacing: 16) {
                SemiCircularProgressView(progress: banknote.rarityProgress, rarityValue: banknote.rarity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        } header: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                SectionHeader("Rarity Rating")
                
                Spacer()
                
                Button {
                    showRarityCitations = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("View Sources")
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Asset.Colors.appPrimary.swiftUIColor)
                }
            }
        }
        .sheet(isPresented: $showRarityCitations) {
            NavigationStack {
                List {
                    ForEach(banknote.sources["rarity"] ?? [], id: \.url) { citation in
                        Link(destination: URL(string: citation.url)!) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(citation.title)
                                    .font(.headline)
                                Text(citation.url)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("Rarity Sources")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showRarityCitations = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private var serialNumberSection: some View {
        Section {
            Text("#\(banknote.serialNumber)")
                .multilineTextAlignment(.trailing)
                .font(.system(.title2, design: .monospaced, weight: .semibold))
                .foregroundColor(.appPrimary)
        } header: {
            SectionHeader("Identification")
        }
    }
    
    private var valuationSection: some View {
        Section {
            VStack {
                HStack(alignment: .lastTextBaseline) {
                    Text("Uncirculated")
                        .font(.subheadline)
                    Spacer()
                    Text(banknote.uncirculatedPriceRange)
                        .font(.body.bold())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Spacer()
                
                HStack(alignment: .lastTextBaseline) {
                    Text("Circulated")
                        .font(.subheadline)
                    Spacer()
                    Text(banknote.circulatedPriceRange)
                        .font(.body.bold())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } header: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                SectionHeader("Market Valuation")
                
                Spacer()
                
                Button {
                    showValuationCitations = true
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("View Sources")
                    }
                    .font(.footnote.weight(.medium))
                    .foregroundColor(Asset.Colors.appPrimary.swiftUIColor)
                }
            }
        }
        .sheet(isPresented: $showValuationCitations) {
            NavigationStack {
                List {
                    ForEach(banknote.sources["valuation"] ?? [], id: \.url) { citation in
                        Link(destination: URL(string: citation.url)!) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(citation.title)
                                    .font(.headline)
                                Text(citation.url)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle("Valuation Sources")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            showValuationCitations = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
    private var designDetailsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(banknote.designElements, id: \.self) { element in
                    Text("• \(element)")
                }
            }
        } header: {
            SectionHeader("Design Elements")
        }
    }
    
    private var specificationsSection: some View {
        Section {
            VStack(spacing: 8) {
                ForEach(banknote.specifications) { spec in
                    SpecificationRow(title: spec.title, value: spec.value)
                    if spec.id != banknote.specifications.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            SectionHeader("Specifications")
        }
    }
    
    private var gradeSection: some View {
        Section {
            if banknote.grade.keys.isEmpty != true {
                VStack(spacing: 8) {
                    SpecificationRow(title: "Grade", value: banknote.grade["grade"] ?? "n/a")
                    SpecificationRow(title: "Grading Scale", value: banknote.grade["gradingScale"] ?? "n/a")
                    SpecificationRow(title: "Grade Label", value: banknote.grade["gradeLabel"] ?? "n/a")
                    SpecificationRow(title: "Justification", value: banknote.grade["justification"] ?? "n/a")
                    SpecificationRow(title: "Notable Strengths", value: banknote.grade["notableStrengths"] ?? "n/a")
                    SpecificationRow(title: "Notable Flaws", value: banknote.grade["notableFlaws"] ?? "n/a")
                }
                .padding(.vertical, 8)
            } else {
                Text("Grade Unavailable")
                    .padding(.vertical, 8)
            }
        } header: {
            SectionHeader("Grade Information")
        }
    }
    
    private struct SectionStyleModifier: ViewModifier {
        var showDivider: Bool = true
        
        func body(content: Content) -> some View {
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .padding(.top, 4)
            
            if (showDivider) {
                Divider()
                    .frame(height: 12)
                    .overlay(Color(.systemGray6))
            }
        }
    }
}

struct SpecificationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
                .monospacedDigit()
        }
        .font(.body)
    }
}

// MARK: - Components

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SectionHeader: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.primary)
            .padding(.top, 8)
    }
}

struct RarityIndicator: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isActive ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isActive ? .white : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isActive ? Color.blue : Color.gray, lineWidth: 1)
            )
    }
}

struct SemiCircularProgressView: View {
    var progress: CGFloat // Value between 0 and 1
    var rarityValue: String // Add this parameter
    
    private var rarityColor: Color {
        let rarityValue = Int(rarityValue) ?? 0
        switch rarityValue {
        case 21...40: return .green
        case 41...60: return .blue
        case 61...80: return .purple
        case 81...: return .orange
        default: return .blue // Default color instead of gray
        }
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Background arc (gray)
                ArcShape()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 14)
                
                // Progress arc (using rarity color)
                ArcShape()
                    .trim(from: 0, to: progress)
                    .stroke(rarityColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
            }
            .frame(width: 150, height: 75)
            
            // Labels
            HStack {
                Text("Common")
                Spacer()
                Text("Rare")
            }
            .frame(width: 210)
            .font(.body)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable
    @State var router: Router = Router()
    
    let preview = Preview(Banknote.self)
    preview.addExamples(Banknote.sampleData)

    return NavigationStack {
        BanknoteDetailView(banknote: Banknote(
            country: "United States",
            title: "1 Dollar, 1963-2021",
            serialNumber: "L32513006T",
            issueDate: "2018",
            rarity: "34",
            uncirculatedPriceRange: "$1.1 – $7.3",
            circulatedPriceRange: "$1 – $2.2",
            designElements: [
                "George Washington portrait",
                "Great Seal of the United States",
                "Serial numbers with Federal Reserve indicators",
                "Green treasury seal on obverse"
            ],
            imageNames: ["banknote-front", "banknote-back"],
            specifications: [
                Specification(title: "Issuer", value: "United States"),
                Specification(title: "Denomination", value: "10 dollars"),
                Specification(title: "Size", value: "156 × 67 mm"),
                Specification(title: "Shape", value: "Rectangular"),
                Specification(title: "Composition", value: "Paper")
            ],
            sources: [
                "rarity": [
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                ],
                "valuation": [
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                    URLCitation(type: "none", startIndex: 0, endIndex: 6, url: "https://google.com", title: "Google"),
                ],
            ],
            grade: [
                "grade": "55",
                "gradingScale": "PMG",
                "gradeLabel": "VF",
                "justification": "The note shows strong margins, vibrant ink, and no visible folds. Corners are sharp with only minor handling.",
                "notableStrengths": "Strong embossing, bright paper, original surfaces",
                "notableFlaws": "Slight corner handling, light centering issue"
            ]
        ))
    }
    .tint(.appPrimary)
    .environment(router)
    .modelContainer(preview.container)
}
