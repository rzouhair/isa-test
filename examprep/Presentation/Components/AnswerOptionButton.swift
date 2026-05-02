import SwiftUI
import Inject

enum AnswerOptionState {
    case idle, selected, correct, incorrect, disabled
}

struct AnswerOptionButton: View {
    @ObserveInjection var inject
    let text: String
    let state: AnswerOptionState
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(text)
                    .font(.body)
                    .foregroundStyle(textColor)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                // Always reserve icon space so the label wrapping doesn't
                // reflow when the reveal icon appears.
                Image(systemName: trailingIcon ?? "circle.fill")
                    .font(.body)
                    .foregroundStyle(trailingIcon == nil ? .clear : textColor)
                    .frame(width: 18)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
        }
        .disabled(state == .disabled || state == .correct || state == .incorrect)
        .enableInjection()
    }

    private var background: Color {
        switch state {
        case .idle, .disabled: return Color(.secondarySystemGroupedBackground)
        case .selected: return theme.accent.opacity(0.1)
        case .correct: return Color.green.opacity(0.15)
        case .incorrect: return Color.red.opacity(0.15)
        }
    }

    private var border: Color {
        switch state {
        case .idle, .disabled: return Color.clear
        case .selected: return theme.accent.opacity(0.6)
        case .correct: return Color.green
        case .incorrect: return Color.red
        }
    }

    private var textColor: Color {
        state == .disabled ? Color.secondary : Color.primary
    }

    private var trailingIcon: String? {
        switch state {
        case .correct: return "checkmark"
        case .incorrect: return "xmark"
        default: return nil
        }
    }
}
