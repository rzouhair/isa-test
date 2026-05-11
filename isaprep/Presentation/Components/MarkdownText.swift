import SwiftUI
import Inject

/// Lightweight markdown renderer. Handles `#`/`##`/`###` headers, bullet
/// points, and inline markdown (bold, italic, links) via `AttributedString`.
/// Tables and other block constructs fall back to inline rendering — good
/// enough for cheat-sheet and handbook bodies in v1.
struct MarkdownText: View {
    @ObserveInjection var inject
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                render(block: block)
            }
        }
        .enableInjection()
    }

    private var blocks: [String] {
        source
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    @ViewBuilder
    private func render(block: String) -> some View {
        if block.hasPrefix("### ") {
            Text(String(block.dropFirst(4)))
                .font(.headline)
        } else if block.hasPrefix("## ") {
            Text(String(block.dropFirst(3)))
                .font(.title3.weight(.bold))
        } else if block.hasPrefix("# ") {
            Text(String(block.dropFirst(2)))
                .font(.title2.weight(.bold))
        } else if block.hasPrefix("- ") || block.hasPrefix("* ") {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(block.split(separator: "\n").enumerated()), id: \.offset) { _, line in
                    let trimmed = line.trimmingCharacters(in: .whitespaces)
                    let stripped = trimmed.hasPrefix("- ") ? String(trimmed.dropFirst(2))
                                : trimmed.hasPrefix("* ") ? String(trimmed.dropFirst(2))
                                : trimmed
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("•").foregroundStyle(.secondary)
                        Text(inline(stripped))
                    }
                }
            }
        } else {
            Text(inline(block))
        }
    }

    private func inline(_ source: String) -> AttributedString {
        (try? AttributedString(markdown: source, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(source)
    }
}
