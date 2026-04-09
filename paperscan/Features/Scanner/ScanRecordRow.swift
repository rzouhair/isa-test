import SwiftUI
import Inject

struct ScanRecordRow: View {
    @ObserveInjection var inject
    let record: ScanRecord
    var onAdd: (() -> Void)?
    var onRetry: (() -> Void)?
    var onCorrect: (() -> Void)?

    @State private var pulseOpacity: Double = 1.0
    @State private var capturedImage: UIImage?
    @State private var showImageViewer = false

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            info
            Spacer(minLength: 0)
            actionButtons
        }
        .frame(minHeight: 72)
        .contentShape(Rectangle())
        .fullScreenCover(isPresented: $showImageViewer) {
            CapturedImageViewer(image: capturedImage, record: record)
        }
        .enableInjection()
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnail: some View {
        Group {
            switch record.scanStatus {
            case .complete:
                if let urlString = record.imageSmall, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        capturedThumbnail
                    }
                } else {
                    capturedThumbnail
                }
            case .failed:
                capturedThumbnail.opacity(0.5)
            case .pending, .processing:
                capturedThumbnail.blur(radius: 3)
            }
        }
        .frame(width: 44, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .onTapGesture { showImageViewer = true }
    }

    private var capturedThumbnail: some View {
        Group {
            if let image = capturedImage {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color(.tertiarySystemFill)
            }
        }
        .task(id: record.capturedImagePath) {
            guard !record.capturedImagePath.isEmpty else { return }
            capturedImage = await Task.detached(priority: .utility) {
                guard let data = try? Data(contentsOf: URL(fileURLWithPath: record.capturedImagePath)) else { return nil }
                return UIImage(data: data)
            }.value
        }
    }

    // MARK: - Info

    @ViewBuilder
    private var info: some View {
        switch record.scanStatus {
        case .pending, .processing:
            Text("Identifying…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .italic()
                .opacity(pulseOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                        pulseOpacity = 0.3
                    }
                }

        case .complete:
            VStack(alignment: .leading, spacing: 2) {
                if let set = record.setName {
                    Text(set)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                Text([record.productName, record.cardNumber.map { "#\($0)" }].compactMap { $0 }.joined(separator: " "))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                if let price = record.marketPrice ?? record.medianPrice ?? record.lowestPrice {
                    Text(String(format: "$%.2f", price))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.value)
                }
            }

        case .failed:
            Text("Couldn't identify")
                .font(.subheadline)
                .foregroundStyle(Color(.systemOrange))
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch record.scanStatus {
        case .complete:
            HStack(spacing: 6) {
                if record.addedToCollection {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(theme.value)
                } else {
                    rowButton(icon: "plus.circle", tint: theme.value) { onAdd?() }
                }
                rowButton(icon: "pencil.circle", tint: Color(.secondaryLabel)) { onCorrect?() }
            }

        case .failed:
            HStack(spacing: 6) {
                rowButton(icon: "arrow.clockwise.circle", tint: Color(.systemOrange)) { onRetry?() }
                rowButton(icon: "pencil.circle", tint: Color(.secondaryLabel)) { onCorrect?() }
            }

        case .pending, .processing:
            EmptyView()
        }
    }

    private func rowButton(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
        }
    }

    private var priceString: String {
        guard let price = record.marketPrice ?? record.medianPrice ?? record.lowestPrice else { return "—" }
        return String(format: "$%.2f", price)
    }
}

// MARK: - Captured Image Viewer

struct CapturedImageViewer: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage?
    let record: ScanRecord

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in scale = lastScale * value }
                            .onEnded { _ in
                                lastScale = scale
                                if scale < 1 { withAnimation { scale = 1; lastScale = 1; offset = .zero; lastOffset = .zero } }
                            }
                            .simultaneously(with:
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in lastOffset = offset }
                            )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation { scale = scale > 1 ? 1 : 2; lastScale = scale; offset = .zero; lastOffset = .zero }
                    }
            } else {
                Color(.secondarySystemBackground)
                    .overlay(Image(systemName: "photo").font(.largeTitle).foregroundStyle(.tertiary))
            }

            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(.black.opacity(0.55))
                    .clipShape(Circle())
            }
            .padding(16)

            if record.scanStatus == .complete, let name = record.productName {
                VStack {
                    Spacer()
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Hex Color Helper (shared)

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red:   Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue:  Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}
