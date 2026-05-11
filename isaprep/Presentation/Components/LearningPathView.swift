import SwiftUI
import Inject

/// Vertical Duolingo-style winding path of circular nodes with status-aware
/// styling and connector lines. Pure presentation — callers provide tiles +
/// tap handler.
struct LearningPathView: View {
    @ObserveInjection var inject

    struct Node: Identifiable, Hashable {
        enum Status: Hashable {
            case locked, start, continueInProgress, failed, passed
        }
        let id: Int
        let label: String          // short label shown under the circle
        let status: Status
    }

    let nodes: [Node]
    let onTap: (Node) -> Void

    /// Horizontal offset amplitude (points). ±amplitude on the winding path.
    private let amplitude: CGFloat = 64
    /// Vertical spacing between node centers.
    private let rowHeight: CGFloat = 96
    /// Node circle diameter.
    private let nodeSize: CGFloat = 64

    /// Index of the "current" node — furthest non-locked non-passed. Gets a
    /// pulse halo so the user knows where to tap next.
    private var currentIndex: Int? {
        nodes.enumerated()
            .last(where: { $0.element.status != .locked && $0.element.status != .passed })?
            .offset
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(nodes.enumerated()), id: \.offset) { idx, node in
                VStack(spacing: 0) {
                    if idx > 0 {
                        connector(fromIndex: idx - 1, toIndex: idx)
                    }
                    nodeRow(node: node, index: idx, isCurrent: idx == currentIndex)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .enableInjection()
    }

    // MARK: - Node row

    @ViewBuilder
    private func nodeRow(node: Node, index: Int, isCurrent: Bool) -> some View {
        HStack {
            Spacer(minLength: 0)
            VStack(spacing: 6) {
                Button {
                    guard node.status != .locked else { return }
                    onTap(node)
                } label: {
                    nodeCircle(node: node, isCurrent: isCurrent)
                }
                .buttonStyle(PathNodePressStyle())
                .disabled(node.status == .locked)

                Text(node.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(labelColor(for: node.status))
                    .lineLimit(1)
                    .frame(maxWidth: 120)

                if node.status == .continueInProgress {
                    Text("Continue")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(theme.accent))
                }
            }
            .offset(x: xOffset(for: index))
            Spacer(minLength: 0)
        }
        .frame(height: rowHeight)
    }

    private func nodeCircle(node: Node, isCurrent: Bool) -> some View {
        ZStack {
            if isCurrent {
                Circle()
                    .stroke(fillColor(for: node.status).opacity(0.35), lineWidth: 6)
                    .frame(width: nodeSize + 18, height: nodeSize + 18)
                    .modifier(PulseModifier())
            }

            Circle()
                .fill(fillColor(for: node.status))
                .frame(width: nodeSize, height: nodeSize)
                .shadow(color: fillColor(for: node.status).opacity(0.35), radius: 6, x: 0, y: 3)

            iconContent(for: node)
                .foregroundStyle(iconColor(for: node.status))
        }
    }

    @ViewBuilder
    private func iconContent(for node: Node) -> some View {
        switch node.status {
        case .passed:
            Image(systemName: "checkmark")
                .font(.title2.weight(.bold))
        case .locked:
            Image(systemName: "lock.fill")
                .font(.title3.weight(.bold))
        case .failed:
            Image(systemName: "arrow.clockwise")
                .font(.title2.weight(.bold))
        case .start, .continueInProgress:
            Text("\(node.id)")
                .font(.title2.weight(.bold).monospacedDigit())
        }
    }

    // MARK: - Connector

    @ViewBuilder
    private func connector(fromIndex: Int, toIndex: Int) -> some View {
        let x1 = xOffset(for: fromIndex)
        let x2 = xOffset(for: toIndex)
        let targetLocked = nodes[toIndex].status == .locked

        HStack {
            Spacer(minLength: 0)
            ConnectorShape(x1: x1, x2: x2, height: 20)
                .stroke(
                    connectorColor(locked: targetLocked),
                    style: StrokeStyle(
                        lineWidth: 3,
                        lineCap: .round,
                        dash: targetLocked ? [4, 6] : []
                    )
                )
                .frame(height: 20)
                .padding(.vertical, -2)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Positioning

    /// Gentle sine-wave winding with period of 6 rows.
    private func xOffset(for index: Int) -> CGFloat {
        let phase = Double(index) * (.pi / 3.0)
        return CGFloat(sin(phase)) * amplitude
    }

    // MARK: - Colors

    private func fillColor(for status: Node.Status) -> Color {
        switch status {
        case .passed: return theme.accent
        case .continueInProgress: return theme.accent
        case .start: return theme.accent.opacity(0.6)
        case .failed: return theme.warning
        case .locked: return Color(.systemFill)
        }
    }

    private func iconColor(for status: Node.Status) -> Color {
        status == .locked ? .secondary : .white
    }

    private func labelColor(for status: Node.Status) -> Color {
        status == .locked ? .secondary : .primary
    }

    private func connectorColor(locked: Bool) -> Color {
        locked ? Color(.systemFill) : theme.accent.opacity(0.5)
    }
}

// MARK: - Shape

/// Curved vertical connector from one horizontal offset to another. Drawn as
/// a simple cubic bezier inside a thin horizontal strip.
private struct ConnectorShape: Shape {
    let x1: CGFloat
    let x2: CGFloat
    let height: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midX = rect.midX
        let top = CGPoint(x: midX + x1, y: 0)
        let bottom = CGPoint(x: midX + x2, y: rect.height)
        let c1 = CGPoint(x: top.x, y: rect.height * 0.5)
        let c2 = CGPoint(x: bottom.x, y: rect.height * 0.5)
        path.move(to: top)
        path.addCurve(to: bottom, control1: c1, control2: c2)
        return path
    }
}

// MARK: - Press + pulse

private struct PathNodePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

private struct PulseModifier: ViewModifier {
    @State private var pulse = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulse ? 1.08 : 1.0)
            .opacity(pulse ? 0.25 : 0.9)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
