import SwiftUI

// MARK: - Input Field Style

public struct InputFieldStyle: @preconcurrency TextFieldStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled
    @FocusState private var isFocused: Bool

    private let state: InputAlertingState
    private let config: InputFieldConfig

    public init(
        _ state: InputAlertingState,
        config: InputFieldConfig = .standard
    ) {
        self.state = state
        self.config = config
    }

    @MainActor
    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .foregroundColor(fontColor)
            .fontStyle(config.fontStyle ?? theme.typography.bodyBold)
            .frame(maxWidth: .infinity, minHeight: theme.size.large)
            .padding(.horizontal, theme.spacing.grid2x)
            .background(fieldBackgroundColor)
            .cornerRadius(cornerRadius)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderSize)
            }
            .disabled(state == .advisory)
            .focused($isFocused)
            .onTapGesture {
                isFocused = true
            }
    }

    @MainActor
    private var fontColor: Color {
        if let overrideColor = config.fontColor {
            return overrideColor
        }
        switch state {
        case .advisory:
            return theme.color.primary
        default:
            return theme.color.inputOutput.opacity(isEnabled ? 1 : InputFieldDefaults.disabledOpacity)
        }
    }

    @MainActor
    private var fieldBackgroundColor: Color {
        if !isEnabled {
            return theme.color.surfaceHigh.opacity(InputFieldDefaults.disabledOpacity)
        }
        if let overrideColor = config.backgroundColor {
            return overrideColor
        }
        switch state {
        case .default, .advisory:
            return theme.color.surfaceHigh
        case .nominal:
            return theme.color.nominal.opacity(InputFieldDefaults.stateBackgroundOpacity)
        case .caution:
            return theme.color.caution.opacity(InputFieldDefaults.stateBackgroundOpacity)
        case .warning:
            return theme.color.warning.opacity(InputFieldDefaults.stateBackgroundOpacity)
        }
    }

    @MainActor
    private var cornerRadius: CGFloat {
        config.cornerRadius ?? theme.radius.medium
    }

    @MainActor
    private var borderColor: Color {
        if let overrideColor = config.borderColor {
            return overrideColor
        }
        switch state {
        case .default:
            return theme.color.surfaceHigh
        case .advisory:
            return theme.color.primary.opacity(isEnabled ? 1 : InputFieldDefaults.disabledOpacity)
        case .nominal:
            return theme.color.nominal.opacity(isEnabled ? 1 : InputFieldDefaults.disabledOpacity)
        case .caution:
            return theme.color.caution.opacity(isEnabled ? 1 : InputFieldDefaults.disabledOpacity)
        case .warning:
            return theme.color.warning.opacity(isEnabled ? 1 : InputFieldDefaults.disabledOpacity)
        }
    }

    @MainActor
    private var borderSize: CGFloat {
        switch state {
        case .nominal, .caution, .warning:
            return theme.size.border
        default:
            return 0
        }
    }
}

// MARK: - TextFieldStyle Extensions

public extension TextFieldStyle where Self == InputFieldStyle {
    static var `default`: InputFieldStyle {
        InputFieldStyle(.default)
    }

    static var advisory: InputFieldStyle {
        InputFieldStyle(.advisory)
    }

    static var nominal: InputFieldStyle {
        InputFieldStyle(.nominal)
    }

    static var caution: InputFieldStyle {
        InputFieldStyle(.caution)
    }

    static var warning: InputFieldStyle {
        InputFieldStyle(.warning)
    }
}
