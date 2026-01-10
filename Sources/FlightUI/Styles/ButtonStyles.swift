import SwiftUI

// MARK: - Button Style Defaults

private enum ButtonDefaults {
    static let pressedOpacity: CGFloat = 0.6
    static let pressedScale: CGFloat = 0.95
}

// MARK: - Filled Button Style

public struct FilledButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, theme.spacing.grid4x)
            .frame(minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .fontStyle(theme.typography.bodyBold)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
    }

    private var backgroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.disabled
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.onCore : theme.color.onDisabled
    }
}

// MARK: - Filled Icon Button Style

public struct FilledIconButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: theme.size.medium, minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .fontStyle(theme.typography.bodyBold)
            .clipShape(Circle())
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
    }

    private var backgroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.disabled
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.onCore : theme.color.onDisabled
    }
}

// MARK: - Tonal Button Style

public struct TonalButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, theme.spacing.grid4x)
            .frame(minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .fontStyle(theme.typography.bodyBold)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
    }

    private var backgroundColor: Color {
        isEnabled ? theme.color.nominal.opacity(0.18) : theme.color.disabled
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.onDisabled
    }
}

// MARK: - Tonal Icon Button Style

public struct TonalIconButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: theme.size.medium, minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .fontStyle(theme.typography.bodyBold)
            .clipShape(Circle())
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
    }

    private var backgroundColor: Color {
        isEnabled ? theme.color.nominal.opacity(0.18) : theme.color.disabled
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.onDisabled
    }
}

// MARK: - Outline Button Style

public struct OutlineButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, theme.spacing.grid4x)
            .frame(minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .fontStyle(theme.typography.bodyBold)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
            .overlay(
                Capsule(style: .circular)
                    .strokeBorder(foregroundColor, style: StrokeStyle(lineWidth: theme.size.border))
                    .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
                    .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
            )
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.onDisabled
    }
}

// MARK: - Outline Icon Button Style

public struct OutlineIconButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: theme.size.medium, minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .fontStyle(theme.typography.bodyBold)
            .clipShape(Circle())
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
            .overlay(
                Circle()
                    .strokeBorder(foregroundColor, style: StrokeStyle(lineWidth: theme.size.border))
                    .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
                    .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
            )
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.onDisabled
    }
}

// MARK: - Text Button Style

public struct TextButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, theme.spacing.grid4x)
            .frame(minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .fontStyle(theme.typography.bodyBold)
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.onDisabled
    }
}

// MARK: - Text Icon Button Style

public struct TextIconButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: theme.size.medium, minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .fontStyle(theme.typography.bodyBold)
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.nominal : theme.color.onDisabled
    }
}

// MARK: - Core Button Style

public enum CoreButtonType: Sendable {
    case advisory, caution, warning
}

public struct CoreButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    private let coreType: CoreButtonType

    public init(coreType: CoreButtonType) {
        self.coreType = coreType
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, theme.spacing.grid4x)
            .frame(minHeight: theme.size.medium)
            .foregroundColor(foregroundColor)
            .background(backgroundColor)
            .fontStyle(theme.typography.bodyBold)
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? ButtonDefaults.pressedOpacity : 1.0)
            .scaleEffect(configuration.isPressed ? ButtonDefaults.pressedScale : 1.0)
    }

    private var backgroundColor: Color {
        guard isEnabled else { return theme.color.disabled }
        switch coreType {
        case .advisory: return theme.color.primary
        case .caution: return theme.color.caution
        case .warning: return theme.color.warning
        }
    }

    private var foregroundColor: Color {
        isEnabled ? theme.color.onCore : theme.color.onDisabled
    }
}

// MARK: - ButtonStyle Extensions

public extension ButtonStyle where Self == FilledButtonStyle {
    static var filled: Self { .init() }
}

public extension ButtonStyle where Self == FilledIconButtonStyle {
    static var filledIcon: Self { .init() }
}

public extension ButtonStyle where Self == TonalButtonStyle {
    static var tonal: Self { .init() }
}

public extension ButtonStyle where Self == TonalIconButtonStyle {
    static var tonalIcon: Self { .init() }
}

public extension ButtonStyle where Self == OutlineButtonStyle {
    static var outline: Self { .init() }
}

public extension ButtonStyle where Self == OutlineIconButtonStyle {
    static var outlineIcon: Self { .init() }
}

public extension ButtonStyle where Self == TextButtonStyle {
    static var text: Self { .init() }
}

public extension ButtonStyle where Self == TextIconButtonStyle {
    static var textIcon: Self { .init() }
}

public extension ButtonStyle where Self == CoreButtonStyle {
    static var advisory: Self { .init(coreType: .advisory) }
    static var caution: Self { .init(coreType: .caution) }
    static var warning: Self { .init(coreType: .warning) }
}
