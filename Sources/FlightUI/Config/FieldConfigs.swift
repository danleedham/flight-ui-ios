import SwiftUI

// MARK: - Input Alerting State

public enum InputAlertingState: Sendable {
    case `default`
    case advisory
    case nominal
    case caution
    case warning
}

// MARK: - Input Field Defaults

internal enum InputFieldDefaults {
    static let disabledOpacity: CGFloat = 0.38
    static let stateBackgroundOpacity: CGFloat = 0.08
    static let hintOpacity: CGFloat = 0.54
}

// MARK: - Menu Field Defaults

internal enum MenuFieldDefaults {
    static let disabledOpacity: CGFloat = 0.38
    static let stateBackgroundOpacity: CGFloat = 0.08
    static let hintOpacity: CGFloat = 0.54
}

// MARK: - Input Field Config

public struct InputFieldConfig: Sendable {
    public let fontColor: Color?
    public let fontStyle: FontStyle?
    public let backgroundColor: Color?
    public let cornerRadius: CGFloat?
    public let borderColor: Color?

    public init(
        fontColor: Color? = nil,
        fontStyle: FontStyle? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat? = nil,
        borderColor: Color? = nil
    ) {
        self.fontColor = fontColor
        self.fontStyle = fontStyle
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
    }
}

// MARK: - InputFieldConfig Factory

extension InputFieldConfig {
    /// Default configuration with no overrides
    public static var standard: InputFieldConfig {
        InputFieldConfig()
    }
}

// MARK: - Menu Field Config

public struct MenuFieldConfig: Sendable {
    public let fontColor: Color?
    public let fontStyle: FontStyle?
    public let backgroundColor: Color?
    public let cornerRadius: CGFloat?
    public let borderColor: Color?

    public init(
        fontColor: Color? = nil,
        fontStyle: FontStyle? = nil,
        backgroundColor: Color? = nil,
        cornerRadius: CGFloat? = nil,
        borderColor: Color? = nil
    ) {
        self.fontColor = fontColor
        self.fontStyle = fontStyle
        self.backgroundColor = backgroundColor
        self.cornerRadius = cornerRadius
        self.borderColor = borderColor
    }
}

// MARK: - MenuFieldConfig Factory

extension MenuFieldConfig {
    /// Default configuration with no overrides
    public static var standard: MenuFieldConfig {
        MenuFieldConfig()
    }
}
