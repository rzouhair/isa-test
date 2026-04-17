import SwiftUI
import Inject

struct CollectionTileView: View {
    @ObserveInjection var inject
    let collection: CardCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon + card count
            HStack(alignment: .top) {
                Image(systemName: collection.tcgType.iconName)
                    .font(.caption)
                    .foregroundStyle(theme.accent.opacity(0.7))
                    .frame(width: 30, height: 30)
                    .background(theme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                Spacer()
                Text("\(collection.cardCount) cards")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            // Name
            Text(collection.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            // Value
            Text(String(format: "$%.2f", collection.totalValue))
                .font(.footnote.weight(.bold).monospacedDigit())
                .foregroundStyle(theme.valueGradient)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 120)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .enableInjection()
    }
}
