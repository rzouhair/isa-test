import Foundation

enum TCGType: String, Codable, CaseIterable, Identifiable {
    case magic
    case pokemon
    case yugioh
    case dragonBallSuper
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .magic: "Magic TG"
        case .pokemon: "Poke TCG"
        case .yugioh: "Yugi TCG"
        case .dragonBallSuper: "DBS TCG"
        case .other: "Other"
        }
    }

    var iconName: String {
        switch self {
        case .magic: "suit.diamond.fill"
        case .pokemon: "circle.circle.fill"
        case .yugioh: "square.stack.fill"
        case .dragonBallSuper: "circle.grid.2x2.fill"
        case .other: "ellipsis.circle.fill"
        }
    }
}
