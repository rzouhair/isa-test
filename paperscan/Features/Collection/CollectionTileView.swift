import SwiftUI
import Inject

struct CollectionTileView: View {
    @ObserveInjection var inject
    let collection: CardCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: collection.tcgType.iconName)
                    .font(.title3)
                    .foregroundStyle(theme.accent.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .background(theme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
                HStack(spacing: 3) {
                    Text("\(collection.cardCount)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.secondary)
                    Image(systemName: "creditcard")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(collection.name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(String(format: "$%.2f", collection.totalValue))
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(theme.valueGradient)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 130)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .enableInjection()
    }
}
