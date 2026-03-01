import SwiftUI

// MARK: - Longitude Field

/// A segmented input field for entering a geographic longitude.
///
/// Supports four entry formats controlled by the `format` binding:
/// - `.signedDecimalDegrees`: Single signed decimal field (positive = E, negative = W)
/// - `.decimalDegrees`: Hemisphere toggle + unsigned decimal degrees (e.g. E 001.47520°)
/// - `.ddm`: Hemisphere toggle + degrees + decimal minutes (e.g. E 001° 52.624')
/// - `.dms`: Hemisphere toggle + degrees + minutes + decimal seconds
///
/// The `longitude` binding receives a valid `Longitude` once all segments are filled
/// and in-range, or `nil` while typing or when any segment is out of range.
///
/// Example:
/// ```swift
/// @State var longitude: Longitude? = nil
/// @State var format: CoordinateFormat = .ddm
///
/// LongitudeField(longitude: $longitude, format: $format, topLabel: "Longitude")
/// ```
///
public struct LongitudeField: View {
    @Environment(\.theme) var theme
    @Environment(\.isEnabled) private var isEnabled

    @Binding var longitude: Longitude?
    @Binding var format: CoordinateFormat

    let topLabel: String?
    let topLabelSpacer: Bool
    let bottomLabelConfig: BottomLabelConfig
    let alertingState: InputAlertingState
    let config: CoordinateFieldConfig
    /// Called when a segment reaches its maximum character count.
    /// No-op by default — implement to drive custom `@FocusState` advancement.
    let onSegmentFilled: (@Sendable () -> Void)? = nil

    @State private var direction: LongitudeDirection = .east
    @State private var degreesText: String = ""
    @State private var minutesText: String = ""
    @State private var secondsText: String = ""
    /// Shared by both `.signedDecimalDegrees` and `.decimalDegrees` formats.
    @State private var decimalDegreesText: String = ""

    public init(
        longitude: Binding<Longitude?>,
        format: Binding<CoordinateFormat>,
        topLabel: String? = nil,
        topLabelSpacer: Bool = false,
        bottomLabelConfig: BottomLabelConfig = .init(isVisible: false),
        alertingState: InputAlertingState = .default,
        config: CoordinateFieldConfig = .standard
    ) {
        self._longitude = longitude
        self._format = format
        self.topLabel = topLabel
        self.topLabelSpacer = topLabelSpacer
        self.bottomLabelConfig = bottomLabelConfig
        self.alertingState = alertingState
        self.config = config
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
                       filter: .custom("[^0-9.-]"), maxCharacterCount: 10)
                .textFieldStyle(InputFieldStyle(signedDDState, config: segmentInputConfig))
            delimiterText("°")
        }
    }

    // DD: unsigned decimal degrees + hemisphere indicator (ISO 6709 — indicator follows digits)
    private func buildUnsignedDDSegments() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            CoordinateSegmentField($decimalDegreesText, placeholder: "0.00000", suffix: "°",
                                   filter: .doubleOnly, maxChar: 9,
                                   state: unsignedDDState, config: segmentInputConfig)
            cardinalControl
        }
    }

    // DDM: degrees + decimal minutes + hemisphere indicator (ISO 6709)
    private func buildDDMSegments() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            CoordinateSegmentField($degreesText, placeholder: "000", suffix: "°",
                                   filter: .integerOnly, maxChar: 3,
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
            CoordinateSegmentField($degreesText, placeholder: "000", suffix: "°",
                                   filter: .integerOnly, maxChar: 3,
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
        guard let value = Double(decimalDegreesText), Longitude.isValid(decimalDegrees: value) else {
            longitude = nil; return
        }
        longitude = Longitude(decimalDegrees: value)
    }

    private func validateUnsignedDD() {
        guard let value = Double(decimalDegreesText), value >= 0, value <= 180 else {
            longitude = nil; return
        }
        let signed = direction == .east ? value : -value
        guard Longitude.isValid(decimalDegrees: signed) else { longitude = nil; return }
        longitude = Longitude(decimalDegrees: signed)
    }

    private func validateDDM() {
        guard let degs = Int(degreesText),
              let mins = Double(minutesText),
              degs >= 0, degs <= 180,
              mins >= 0, mins < 60 else { longitude = nil; return }
        let decDeg = Double(degs) + mins / 60.0
        let signed = direction == .east ? decDeg : -decDeg
        guard Longitude.isValid(decimalDegrees: signed) else { longitude = nil; return }
        longitude = Longitude(decimalDegrees: signed)
    }

    private func validateDMS() {
        guard let degs = Int(degreesText),
              let mins = Int(minutesText),
              let secs = Double(secondsText),
              degs >= 0, degs <= 180,
              mins >= 0, mins < 60,
              secs >= 0, secs < 60 else { longitude = nil; return }
        let decDeg = Double(degs) + Double(mins) / 60.0 + secs / 3600.0
        let signed = direction == .east ? decDeg : -decDeg
        guard Longitude.isValid(decimalDegrees: signed) else { longitude = nil; return }
        longitude = Longitude(decimalDegrees: signed)
    }

    // MARK: - Populate from Binding

    private func populateFromBinding() {
        guard let lon = longitude else { clearSegments(); return }
        switch format {
        case .signedDecimalDegrees:
            decimalDegreesText = String(format: "%.5f", lon.decimalDegrees)
        case .decimalDegrees:
            direction = lon.direction
            decimalDegreesText = String(format: "%.5f", lon.unsignedDecimalDegrees)
        case .ddm:
            let ddm = lon.degreesDecimalMinutes
            direction = lon.direction
            degreesText = String(ddm.degrees)
            minutesText = String(format: "%.3f", ddm.minutes)
        case .dms:
            let dms = lon.degreesMinutesSeconds
            direction = lon.direction
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
        return (-180...180).contains(val) ? alertingState : .warning
    }

    private var unsignedDDState: InputAlertingState {
        guard !decimalDegreesText.isEmpty, let val = Double(decimalDegreesText) else { return alertingState }
        return (val >= 0 && val <= 180) ? alertingState : .warning
    }

    private var degreesState: InputAlertingState {
        guard !degreesText.isEmpty, let val = Int(degreesText) else { return alertingState }
        return (val >= 0 && val <= 180) ? alertingState : .warning
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
