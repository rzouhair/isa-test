import Foundation
import CoreGraphics

enum GradingStep: Int, CaseIterable, Identifiable {
    case frontFlat = 0
    case backFlat
    case frontAngled
    case cornersTop
    case cornersBottom
    case edges

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .frontFlat: "Front Flat"
        case .backFlat: "Back Flat"
        case .frontAngled: "Front Angled"
        case .cornersTop: "Top Corners"
        case .cornersBottom: "Bottom Corners"
        case .edges: "Edges"
        }
    }

    var instruction: String {
        switch self {
        case .frontFlat: "Place card flat on a dark surface, front facing up"
        case .backFlat: "Flip card over, keep flat in the same position"
        case .frontAngled: "Tilt card ~45° so light catches surface scratches"
        case .cornersTop: "Move close to the top corners of the card"
        case .cornersBottom: "Move close to the bottom corners of the card"
        case .edges: "Tilt card slightly to show the edge thickness"
        }
    }

    var isRequired: Bool {
        switch self {
        case .frontFlat, .backFlat: true
        default: false
        }
    }

    var apiKey: String {
        switch self {
        case .frontFlat: "front_flat"
        case .backFlat: "back_flat"
        case .frontAngled: "front_angled"
        case .cornersTop: "corners_top"
        case .cornersBottom: "corners_bottom"
        case .edges: "edges"
        }
    }

    var viewfinderStyle: ViewfinderStyle {
        switch self {
        case .frontFlat, .backFlat: .fullCard
        case .frontAngled: .angledCard
        case .cornersTop: .cornerTop
        case .cornersBottom: .cornerBottom
        case .edges: .edgeStrip
        }
    }

    var stepIcon: String {
        switch self {
        case .frontFlat: "rectangle.portrait"
        case .backFlat: "rectangle.portrait.fill"
        case .frontAngled: "rectangle.portrait.rotate"
        case .cornersTop: "arrow.up.forward.and.arrow.down.backward"
        case .cornersBottom: "arrow.down.backward.and.arrow.up.forward"
        case .edges: "rectangle.split.3x1"
        }
    }
}

enum ViewfinderStyle {
    case fullCard      // 78% width, 1:1.4 ratio
    case angledCard    // same rect + tilt guide lines
    case cornerTop     // smaller rect in upper portion
    case cornerBottom  // smaller rect in lower portion
    case edgeStrip     // wide, narrow rectangle

    func cutoutRect(in size: CGSize) -> CGRect {
        switch self {
        case .fullCard, .angledCard:
            let w = size.width * 0.78
            let h = w * 1.4
            let x = (size.width - w) / 2
            let y = (size.height - h) / 2
            return CGRect(x: x, y: y, width: w, height: h)

        case .cornerTop:
            let w = size.width * 0.85
            let h = w * 0.45
            let x = (size.width - w) / 2
            let y = size.height * 0.30 - h / 2
            return CGRect(x: x, y: y, width: w, height: h)

        case .cornerBottom:
            let w = size.width * 0.85
            let h = w * 0.45
            let x = (size.width - w) / 2
            let y = size.height * 0.65 - h / 2
            return CGRect(x: x, y: y, width: w, height: h)

        case .edgeStrip:
            let w = size.width * 0.85
            let h = w * 0.35
            let x = (size.width - w) / 2
            let y = (size.height - h) / 2
            return CGRect(x: x, y: y, width: w, height: h)
        }
    }
}
