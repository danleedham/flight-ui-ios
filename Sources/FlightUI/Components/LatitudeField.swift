import SwiftUI

// MARK: - Latitude Field

/// A segmented input field for entering a geographic latitude.
///
/// Supports four entry formats controlled by the `format` binding:
/// - `.signedDecimalDegrees`: Single signed decimal field (positive = N, negative = S)
/// - `.decimalDegrees`: Hemisphere toggle + unsigned decimal degrees (e.g. N 51.47520°)
/// - `.ddm`: Hemisphere toggle + degrees + decimal minutes (e.g. N 51° 28.741')
/// - `.dms`: Hemisphere toggle + degrees + minutes + decimal seconds
///
/// The `latitude` binding receives a valid `Latitude` once all segments are filled
/// and in-range, or `nil` while typing or when any segment is out of range.
///
/// Example:
/// ```swift
/// @State var latitude: Latitude? = nil
/// @State var format: CoordinateFormat = .ddm
///
/// LatitudeField(latitude: $latitude, format: $format, topLabel: "Latitude")
/// ```
///
public struct LatitudeField: View {
    @Environment(\.theme) var theme
    @Environment(\.isEnabled) private var isEnabled

    @Binding var latitude: Latitude?
    @Binding var format: CoordinateFormat

    let topLabel: String?
    let topLabelSpacer: Bool
    let bottomLabelConfig: BottomLabelConfig
    let alertingState: InputAlertingState
    let config: CoordinateFieldConfig
    /// Called when a segment reaches its maximum character count.
    /// No-op by default — implement to drive custom `@FocusState` advancement.
    let onSegmentFilled: (@Sendable () -> Void)?

    @State private var direction: LatitudeDirection = .north
    @State private var degreesText: String = ""
    @State private var minutesText: String = ""
    @State private var secondsText: String = ""
    /// Shared by both `.signedDecimalDegrees` and `.decimalDegrees` formats.
    @State private var decimalDegreesText: String = ""

    public init(
        latitude: Binding<Latitude?>,
        format: Binding<CoordinateFormat>,
        topLabel: String? = nil,
        topLabelSpacer: Bool = false,
        bottomLabelConfig: BottomLabelConfig = .init(isVisible: false),
        alertingState: InputAlertingState = .default,
        config: CoordinateFieldConfig = .standard,
        onSegmentFilled: (@Sendable () -> Void)? = nil
    ) {
        self._latitude = latitude
        self._format = format
        self.topLabel = topLabel
        self.topLabelSpacer = topLabelSpacer
        self.bottomLabelConfig = bottomLabelConfig
        self.alertingState = alertingState
        self.config = config
        self.onSegmentFilled = onSegmentFilled
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.grid0_5x) {
            buildTopLabel()
            buildSegments()
            BottomLabel(bottomLabelConfig)
        }
        .onAppear { populateFromBinding() }
        .onChange(of: format) { _, _ in populateFromBinding() }
        .onChange(of: direction) { _, _ in validate() }
        .onChange(of: degreesText) { _, _ in validate() }
        .onChange(of: minutesText) { _, _ in validate() }
        .onChange(of: secondsText) { _, _ in validate() }
        .onChange(of: decimalDegreesText) { _, _ in validate() }
    }

    // MARK: - Top Label

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

    // MARK: - Segments

    @ViewBuilder
    private func buildSegments() -> some View {
        switch format {
        case .signedDecimalDegrees: buildSignedDDSegment()
        case .decimalDegrees:       buildUnsignedDDSegments()
        case .ddm:                  buildDDMSegments()
        case .dms:                  buildDMSSegments()
        }
    }

    // ±DD: single signed decimal field — expands to fill available width
    private func buildSignedDDSegment() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            InputField(text: $decimalDegreesText, placeholder: "±0.00000",
                       filter: .custom("[^0-9.-]"), maxCharacterCount: 9)
                .textFieldStyle(InputFieldStyle(signedDDState, config: segmentInputConfig))
            delimiterText("°")
        }
    }

    // DD: unsigned decimal degrees + hemisphere indicator (ISO 6709 — indicator follows digits)
    private func buildUnsignedDDSegments() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            CoordinateSegmentField($decimalDegreesText, placeholder: "0.00000", suffix: "°",
                                   filter: .doubleOnly, maxChar: 8,
                                   state: unsignedDDState, config: segmentInputConfig)
            cardinalControl
        }
    }

    // DDM: degrees + decimal minutes + hemisphere indicator (ISO 6709)
    private func buildDDMSegments() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            CoordinateSegmentField($degreesText, placeholder: "00", suffix: "°",
                                   filter: .integerOnly, maxChar: 2,
                                   state: degreesState, config: segmentInputConfig)
            CoordinateSegmentField($minutesText, placeholder: "00.000", suffix: "'",
                                   filter: .doubleOnly, maxChar: 7,
                                   state: minutesDecimalState, config: segmentInputConfig)
            cardinalControl
        }
    }

    // DMS: always single row — compact fixedSize fields fit even on iPhone (ISO 6709)
    private func buildDMSSegments() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            CoordinateSegmentField($degreesText, placeholder: "00", suffix: "°",
                                   filter: .integerOnly, maxChar: 2,
                                   state: degreesState, config: segmentInputConfig)
            CoordinateSegmentField($minutesText, placeholder: "00", suffix: "'",
                                   filter: .integerOnly, maxChar: 2,
                                   state: minutesIntState, config: segmentInputConfig)
            CoordinateSegmentField($secondsText, placeholder: secondsPlaceholder, suffix: "\"",
                                   filter: .doubleOnly, maxChar: secondsMaxChar,
                                   state: secondsState, config: segmentInputConfig)
            cardinalControl
        }
    }

    // MARK: - Cardinal Control

    @ViewBuilder
    private var cardinalControl: some View {
        switch config.cardinalStyle {
        case .button:  CardinalButton(selection: $direction, highlightColor: config.cardinalColor)
        case .segment: CardinalSegmentControl(selection: $direction, highlightColor: config.cardinalColor)
        }
    }

    // MARK: - Delimiter (±DD only)

    private func delimiterText(_ symbol: String) -> some View {
        Text(symbol)
            .foregroundColor(theme.color.secondary)
            .fontStyle(theme.typography.body)
    }

    // MARK: - Seconds Precision

    private var secondsPlaceholder: String {
        config.secondsPrecision == 0 ? "00" : "00." + String(repeating: "0", count: config.secondsPrecision)
    }

    private var secondsMaxChar: Int {
        config.secondsPrecision == 0 ? 2 : 2 + 1 + config.secondsPrecision
    }

    // MARK: - Validation

    private func validate() {
        switch format {
        case .signedDecimalDegrees: validateSignedDD()
        case .decimalDegrees:       validateUnsignedDD()
        case .ddm:                  validateDDM()
        case .dms:                  validateDMS()
        }
    }

    private func validateSignedDD() {
        guard let value = Double(decimalDegreesText), Latitude.isValid(decimalDegrees: value) else {
            latitude = nil; return
        }
        latitude = Latitude(decimalDegrees: value)
    }

    private func validateUnsignedDD() {
        guard let value = Double(decimalDegreesText), value >= 0, value <= 90 else {
            latitude = nil; return
        }
        let signed = direction == .north ? value : -value
        guard Latitude.isValid(decimalDegrees: signed) else { latitude = nil; return }
        latitude = Latitude(decimalDegrees: signed)
    }

    private func validateDDM() {
        guard let degs = Int(degreesText),
              let mins = Double(minutesText),
              degs >= 0, degs <= 90,
              mins >= 0, mins < 60 else { latitude = nil; return }
        let decDeg = Double(degs) + mins / 60.0
        let signed = direction == .north ? decDeg : -decDeg
        guard Latitude.isValid(decimalDegrees: signed) else { latitude = nil; return }
        latitude = Latitude(decimalDegrees: signed)
    }

    private func validateDMS() {
        guard let degs = Int(degreesText),
              let mins = Int(minutesText),
              let secs = Double(secondsText),
              degs >= 0, degs <= 90,
              mins >= 0, mins < 60,
              secs >= 0, secs < 60 else { latitude = nil; return }
        let decDeg = Double(degs) + Double(mins) / 60.0 + secs / 3600.0
        let signed = direction == .north ? decDeg : -decDeg
        guard Latitude.isValid(decimalDegrees: signed) else { latitude = nil; return }
        latitude = Latitude(decimalDegrees: signed)
    }

    // MARK: - Populate from Binding

    private func populateFromBinding() {
        guard let lat = latitude else { clearSegments(); return }
        switch format {
        case .signedDecimalDegrees:
            decimalDegreesText = String(format: "%.5f", lat.decimalDegrees)
        case .decimalDegrees:
            direction = lat.direction
            decimalDegreesText = String(format: "%.5f", lat.unsignedDecimalDegrees)
        case .ddm:
            let ddm = lat.degreesDecimalMinutes
            direction = lat.direction
            degreesText = String(ddm.degrees)
            minutesText = String(format: "%.3f", ddm.minutes)
        case .dms:
            let dms = lat.degreesMinutesSeconds
            direction = lat.direction
            degreesText = String(dms.degrees)
            minutesText = String(dms.minutes)
            secondsText = String(format: "%.\(config.secondsPrecision)f", dms.seconds)
        }
    }

    private func clearSegments() {
        degreesText = ""
        minutesText = ""
        secondsText = ""
        decimalDegreesText = ""
    }

    // MARK: - Segment Alerting State

    private var segmentInputConfig: InputFieldConfig {
        InputFieldConfig(fontColor: config.fontColor, fontStyle: config.fontStyle,
                         backgroundColor: config.backgroundColor,
                         cornerRadius: config.cornerRadius, borderColor: config.borderColor)
    }

    private var signedDDState: InputAlertingState {
        guard !decimalDegreesText.isEmpty, let val = Double(decimalDegreesText) else { return alertingState }
        return (-90...90).contains(val) ? alertingState : .warning
    }

    private var unsignedDDState: InputAlertingState {
        guard !decimalDegreesText.isEmpty, let val = Double(decimalDegreesText) else { return alertingState }
        return (val >= 0 && val <= 90) ? alertingState : .warning
    }

    private var degreesState: InputAlertingState {
        guard !degreesText.isEmpty, let val = Int(degreesText) else { return alertingState }
        return (val >= 0 && val <= 90) ? alertingState : .warning
    }

    private var minutesDecimalState: InputAlertingState {
        guard !minutesText.isEmpty, let val = Double(minutesText) else { return alertingState }
        return (val >= 0 && val < 60) ? alertingState : .warning
    }

    private var minutesIntState: InputAlertingState {
        guard !minutesText.isEmpty, let val = Int(minutesText) else { return alertingState }
        return (val >= 0 && val < 60) ? alertingState : .warning
    }

    private var secondsState: InputAlertingState {
        guard !secondsText.isEmpty, let val = Double(secondsText) else { return alertingState }
        return (val >= 0 && val < 60) ? alertingState : .warning
    }
}
