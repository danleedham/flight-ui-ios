import SwiftUI
import Combine

// MARK: - Input Field

public struct InputField: View {
    @Environment(\.theme) var theme
    @Environment(\.isEnabled) private var isEnabled
    @FocusState var isFocused: Bool

    @Binding var text: String
    let placeholder: String?
    let topLabel: String?
    let topLabelSpacer: Bool
    let bottomLabelConfig: BottomLabelConfig
    let formatter: ((String) -> String)?
    let filter: RegexFilter?
    let maxCharacterCount: Int?

    public init(
        text: Binding<String>,
        placeholder: String? = nil,
        topLabel: String? = nil,
        topLabelSpacer: Bool = false,
        bottomLabelConfig: BottomLabelConfig = .init(isVisible: false),
        formatter: ((String) -> String)? = nil,
        filter: RegexFilter? = nil,
        maxCharacterCount: Int? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.topLabel = topLabel
        self.topLabelSpacer = topLabelSpacer
        self.bottomLabelConfig = bottomLabelConfig
        self.formatter = formatter
        self.filter = filter
        self.maxCharacterCount = maxCharacterCount
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.grid0_5x) {
            buildTopLabel()
            buildTextField()
            BottomLabel(bottomLabelConfig)
        }
    }

    @ViewBuilder
    private func buildTopLabel() -> some View {
        if let top = topLabel {
            Text(top)
                .foregroundColor(theme.color.primary)
                .fontStyle(theme.typography.subhead)
        } else if topLabelSpacer {
            Text("-")
                .foregroundColor(theme.color.surfaceHigh.opacity(0))
                .fontStyle(theme.typography.subhead)
        }
    }

    @ViewBuilder
    private func buildTextField() -> some View {
        if let placeholderText = placeholder {
            TextField(text: $text) {
                Text(placeholderText)
                    .foregroundColor(theme.color.primary.opacity(isEnabled ? InputFieldDefaults.hintOpacity : InputFieldDefaults.disabledOpacity))
            }
            .onReceive(Just(text)) { newValue in
                applyFilters(newValue)
            }
            .focused($isFocused)
            .onChange(of: isFocused) { _, newFocus in
                if !newFocus, let format = formatter {
                    text = format(text)
                }
            }
        } else {
            TextField("", text: $text)
                .onReceive(Just(text)) { newValue in
                    applyFilters(newValue)
                }
                .focused($isFocused)
                .onChange(of: isFocused) { _, newFocus in
                    if !newFocus, let format = formatter {
                        text = format(text)
                    }
                }
        }
    }

    private func applyFilters(_ newValue: String) {
        var modified = newValue

        if let regex = filter?.regex {
            let replaced = modified.replacingOccurrences(of: regex, with: "", options: .regularExpression)
            if replaced != modified {
                modified = replaced
            }
        }

        if let maxCount = maxCharacterCount, modified.count > maxCount {
            modified = String(modified.prefix(maxCount))
        }

        if modified != text {
            text = modified
        }
    }
}
