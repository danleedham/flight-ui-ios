import SwiftUI
import AviationMaths

// MARK: - Coordinate Field

/// A composite input field for entering a full geographic position (latitude + longitude).
///
/// Renders both axes inside a unified card, with a built-in format picker (±DD / DD / DDM / DMS)
/// and a live cross-format preview that updates as the user types. On iPad (`.regular` width),
/// the ±DD and DD formats place both axes on a single row.
///
/// The `format` binding is still useful for persistence and offset display — the built-in picker
/// handles switching, so apps should not add a second external picker.
///
/// When embedded in a SwiftUI `Form`, the component automatically clears the list row background
/// so only the card background is visible. No `.listRowInsets` override is needed.
///
/// Example:
/// ```swift
/// @State var position: Position2D? = nil
/// @State var format: CoordinateFormat = .ddm
///
/// CoordinateField(position: $position, format: $format, topLabel: "Position")
/// ```
///
public struct CoordinateField: View {
    @Environment(\.theme) var theme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding var position: Position2D?
    @Binding var format: CoordinateFormat

    let topLabel: String?
    let topLabelSpacer: Bool
    let bottomLabelConfig: BottomLabelConfig
    let alertingState: InputAlertingState
    let config: CoordinateFieldConfig

    // Internal validated values — set by segment validation, read for assembly
    @State var latitude: Latitude?
    @State var longitude: Longitude?

    // Segment text state — latitude
    @State var latDecimalDegreesText: String = ""
    @State var latDegreesText: String = ""
    @State var latMinutesText: String = ""
    @State var latSecondsText: String = ""
    @State var latDirection: LatitudeDirection = .north

    // Segment text state — longitude
    @State var lonDecimalDegreesText: String = ""
    @State var lonDegreesText: String = ""
    @State var lonMinutesText: String = ""
    @State var lonSecondsText: String = ""
    @State var lonDirection: LongitudeDirection = .east

    // Column-alignment state (iPhone stacked DDM/DMS card)
    @State var cardDegreesWidth: CGFloat = 0

    public init(
        position: Binding<Position2D?>,
        format: Binding<CoordinateFormat>,
        topLabel: String? = nil,
        topLabelSpacer: Bool = false,
        bottomLabelConfig: BottomLabelConfig = .init(isVisible: false),
        alertingState: InputAlertingState = .default,
        config: CoordinateFieldConfig = .standard
    ) {
        self._position = position
        self._format = format
        self.topLabel = topLabel
        self.topLabelSpacer = topLabelSpacer
        self.bottomLabelConfig = bottomLabelConfig
        self.alertingState = alertingState
        self.config = config

        // Synchronously populate segments from the initial binding value so the first
        // render shows filled fields and avoids a nil→non-nil flash on the caller's side.
        guard let pos = position.wrappedValue else { return }
        let fmt = format.wrappedValue
        let secsPrec = config.secondsPrecision
        self._latitude = State(initialValue: pos.latitude)
        self._longitude = State(initialValue: pos.longitude)
        switch fmt {
        case .signedDecimalDegrees:
            self._latDecimalDegreesText = State(initialValue: String(format: "%.5f", pos.latitude.decimalDegrees))
            self._lonDecimalDegreesText = State(initialValue: String(format: "%.5f", pos.longitude.decimalDegrees))
        case .decimalDegrees:
            self._latDirection = State(initialValue: pos.latitude.direction)
            self._latDecimalDegreesText = State(initialValue: String(format: "%.5f", pos.latitude.unsignedDecimalDegrees))
            self._lonDirection = State(initialValue: pos.longitude.direction)
            self._lonDecimalDegreesText = State(initialValue: String(format: "%.5f", pos.longitude.unsignedDecimalDegrees))
        case .ddm:
            let latDDM = pos.latitude.degreesDecimalMinutes
            let lonDDM = pos.longitude.degreesDecimalMinutes
            self._latDirection = State(initialValue: pos.latitude.direction)
            self._latDegreesText = State(initialValue: String(latDDM.degrees))
            self._latMinutesText = State(initialValue: String(format: "%.3f", latDDM.minutes))
            self._lonDirection = State(initialValue: pos.longitude.direction)
            self._lonDegreesText = State(initialValue: String(lonDDM.degrees))
            self._lonMinutesText = State(initialValue: String(format: "%.3f", lonDDM.minutes))
        case .dms:
            let latDMS = pos.latitude.degreesMinutesSeconds
            let lonDMS = pos.longitude.degreesMinutesSeconds
            self._latDirection = State(initialValue: pos.latitude.direction)
            self._latDegreesText = State(initialValue: String(latDMS.degrees))
            self._latMinutesText = State(initialValue: String(latDMS.minutes))
            self._latSecondsText = State(initialValue: String(format: "%.\(secsPrec)f", latDMS.seconds))
            self._lonDirection = State(initialValue: pos.longitude.direction)
            self._lonDegreesText = State(initialValue: String(lonDMS.degrees))
            self._lonMinutesText = State(initialValue: String(lonDMS.minutes))
            self._lonSecondsText = State(initialValue: String(format: "%.\(secsPrec)f", lonDMS.seconds))
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.grid1x) {
            buildTopLabel()
            buildHeader()
            buildCard()
            buildPreview()
            BottomLabel(bottomLabelConfig)
        }
        .listRowBackground(Color.clear)
        .onChange(of: format) { _, _ in populateSegments() }
        .onChange(of: latitude) { _, _ in assemblePosition() }
        .onChange(of: longitude) { _, _ in assemblePosition() }
        .onChange(of: latDecimalDegreesText) { _, _ in validateCurrentFormat() }
        .onChange(of: latDegreesText) { _, _ in validateCurrentFormat() }
        .onChange(of: latMinutesText) { _, _ in validateCurrentFormat() }
        .onChange(of: latSecondsText) { _, _ in validateCurrentFormat() }
        .onChange(of: latDirection) { _, _ in validateCurrentFormat() }
        .onChange(of: lonDecimalDegreesText) { _, _ in validateCurrentFormat() }
        .onChange(of: lonDegreesText) { _, _ in validateCurrentFormat() }
        .onChange(of: lonMinutesText) { _, _ in validateCurrentFormat() }
        .onChange(of: lonSecondsText) { _, _ in validateCurrentFormat() }
        .onChange(of: lonDirection) { _, _ in validateCurrentFormat() }
    }
}

// MARK: - Layout

extension CoordinateField {

    @ViewBuilder
    func buildTopLabel() -> some View {
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

    func buildHeader() -> some View {
        Picker("Format", selection: $format) {
            Text("±DD").tag(CoordinateFormat.signedDecimalDegrees)
            Text("DD").tag(CoordinateFormat.decimalDegrees)
            Text("DDM").tag(CoordinateFormat.ddm)
            Text("DMS").tag(CoordinateFormat.dms)
        }
        .pickerStyle(.segmented)
    }

    func buildCard() -> some View {
        VStack(spacing: 0) {
            if horizontalSizeClass == .regular {
                switch format {
                case .signedDecimalDegrees, .decimalDegrees: buildCombinedDDRow()
                case .ddm:                                   buildCombinedDDMRow()
                case .dms:                                   buildCombinedDMSRow()
                }
            } else {
                switch format {
                case .signedDecimalDegrees, .decimalDegrees:
                    buildLatRow()
                    cardSeparator()
                    buildLonRow()
                case .ddm: buildAlignedDDMCard()
                case .dms: buildAlignedDMSCard()
                }
            }
        }
        .background(theme.color.surfaceHigh)
        .cornerRadius(theme.radius.medium)
    }

    func cardSeparator() -> some View {
        theme.color.secondary.opacity(0.2).frame(height: 1)
    }

    func buildCombinedDDRow() -> some View {
        HStack(spacing: theme.spacing.grid2x) {
            HStack(spacing: theme.spacing.grid0_5x) {
                axisLabel("Lat")
                buildLatSegmentsDD()
            }
            HStack(spacing: theme.spacing.grid0_5x) {
                axisLabel("Lon")
                buildLonSegmentsDD()
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.grid2x)
    }

    func buildCombinedDDMRow() -> some View {
        HStack(spacing: theme.spacing.grid2x) {
            HStack(spacing: theme.spacing.grid0_5x) {
                axisLabel("Lat")
                buildLatSegmentsDDM()
            }
            HStack(spacing: theme.spacing.grid0_5x) {
                axisLabel("Lon")
                buildLonSegmentsDDM()
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.grid2x)
    }

    func buildCombinedDMSRow() -> some View {
        HStack(spacing: theme.spacing.grid2x) {
            HStack(spacing: theme.spacing.grid0_5x) {
                axisLabel("Lat")
                buildLatSegmentsDMS()
            }
            HStack(spacing: theme.spacing.grid0_5x) {
                axisLabel("Lon")
                buildLonSegmentsDMS()
            }
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.grid2x)
    }

    func buildLatRow() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            axisLabel("Lat")
            buildLatSegments()
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.grid2x)
    }

    func buildLonRow() -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            axisLabel("Lon")
            buildLonSegments()
            Spacer(minLength: 0)
        }
        .padding(theme.spacing.grid2x)
    }

    func axisLabel(_ text: String) -> some View {
        Text(text)
            .foregroundColor(theme.color.primary)
            .fontStyle(theme.typography.bodyBold)
            .frame(minWidth: 28, alignment: .leading)
    }

    @ViewBuilder
    func buildLatSegments() -> some View {
        switch format {
        case .signedDecimalDegrees, .decimalDegrees: buildLatSegmentsDD()
        case .ddm:                                   buildLatSegmentsDDM()
        case .dms:                                   buildLatSegmentsDMS()
        }
    }

    @ViewBuilder
    func buildLatSegmentsDD() -> some View {
        if format == .decimalDegrees {
            CoordinateSegmentField($latDecimalDegreesText, placeholder: "0.00000", suffix: "°",
                                   filter: .doubleOnly, maxChar: 8,
                                   state: latDDState, config: segmentInputConfig)
            cardinalLat()
        } else {
            InputField(text: $latDecimalDegreesText, placeholder: "±0.00000",
                       filter: .custom("[^0-9.-]"), maxCharacterCount: 9)
                .textFieldStyle(InputFieldStyle(latDDState, config: segmentInputConfig))
            delimiterText("°")
        }
    }

    func buildLatSegmentsDDM() -> some View {
        buildDDMSegmentsRow(degrees: $latDegreesText, degreesPlaceholder: "00", degreesMaxChar: 2,
                            degreesState: latDegreesState, minutes: $latMinutesText,
                            minutesState: latMinDecState) { cardinalLat() }
    }

    func buildLatSegmentsDMS() -> some View {
        buildDMSSegmentsRow(degrees: $latDegreesText, degreesPlaceholder: "00", degreesMaxChar: 2,
                            degreesState: latDegreesState, minutes: $latMinutesText,
                            minutesState: latMinIntState, seconds: $latSecondsText,
                            secondsPlaceholder: latSecondsPlaceholder, secondsMaxChar: latSecondsMaxChar,
                            secondsState: latSecondsState) { cardinalLat() }
    }

    @ViewBuilder
    func buildLonSegments() -> some View {
        switch format {
        case .signedDecimalDegrees, .decimalDegrees: buildLonSegmentsDD()
        case .ddm:                                   buildLonSegmentsDDM()
        case .dms:                                   buildLonSegmentsDMS()
        }
    }

    @ViewBuilder
    func buildLonSegmentsDD() -> some View {
        if format == .decimalDegrees {
            CoordinateSegmentField($lonDecimalDegreesText, placeholder: "0.00000", suffix: "°",
                                   filter: .doubleOnly, maxChar: 9,
                                   state: lonDDState, config: segmentInputConfig)
            cardinalLon()
        } else {
            InputField(text: $lonDecimalDegreesText, placeholder: "±0.00000",
                       filter: .custom("[^0-9.-]"), maxCharacterCount: 10)
                .textFieldStyle(InputFieldStyle(lonDDState, config: segmentInputConfig))
            delimiterText("°")
        }
    }

    func buildLonSegmentsDDM() -> some View {
        buildDDMSegmentsRow(degrees: $lonDegreesText, degreesPlaceholder: "000", degreesMaxChar: 3,
                            degreesState: lonDegreesState, minutes: $lonMinutesText,
                            minutesState: lonMinDecState) { cardinalLon() }
    }

    func buildLonSegmentsDMS() -> some View {
        buildDMSSegmentsRow(degrees: $lonDegreesText, degreesPlaceholder: "000", degreesMaxChar: 3,
                            degreesState: lonDegreesState, minutes: $lonMinutesText,
                            minutesState: lonMinIntState, seconds: $lonSecondsText,
                            secondsPlaceholder: lonSecondsPlaceholder, secondsMaxChar: lonSecondsMaxChar,
                            secondsState: lonSecondsState) { cardinalLon() }
    }

    private func buildDDMSegmentsRow<C: View>(
        degrees: Binding<String>, degreesPlaceholder: String, degreesMaxChar: Int,
        degreesState: InputAlertingState, minutes: Binding<String>, minutesState: InputAlertingState,
        @ViewBuilder cardinal: () -> C
    ) -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            CoordinateSegmentField(degrees, placeholder: degreesPlaceholder, suffix: "°",
                                   filter: .integerOnly, maxChar: degreesMaxChar,
                                   state: degreesState, config: segmentInputConfig)
            CoordinateSegmentField(minutes, placeholder: "00.000", suffix: "'",
                                   filter: .doubleOnly, maxChar: 7,
                                   state: minutesState, config: segmentInputConfig)
            cardinal()
        }
    }

    private func buildDMSSegmentsRow<C: View>(
        degrees: Binding<String>, degreesPlaceholder: String, degreesMaxChar: Int,
        degreesState: InputAlertingState, minutes: Binding<String>, minutesState: InputAlertingState,
        seconds: Binding<String>, secondsPlaceholder: String, secondsMaxChar: Int,
        secondsState: InputAlertingState, @ViewBuilder cardinal: () -> C
    ) -> some View {
        HStack(spacing: theme.spacing.grid0_5x) {
            CoordinateSegmentField(degrees, placeholder: degreesPlaceholder, suffix: "°",
                                   filter: .integerOnly, maxChar: degreesMaxChar,
                                   state: degreesState, config: segmentInputConfig)
            CoordinateSegmentField(minutes, placeholder: "00", suffix: "'",
                                   filter: .integerOnly, maxChar: 2,
                                   state: minutesState, config: segmentInputConfig)
            CoordinateSegmentField(seconds, placeholder: secondsPlaceholder, suffix: "\"",
                                   filter: .doubleOnly, maxChar: secondsMaxChar,
                                   state: secondsState, config: segmentInputConfig)
            cardinal()
        }
    }

    // MARK: - Cardinal Controls

    @ViewBuilder
    func cardinalLat() -> some View {
        switch config.cardinalStyle {
        case .button:  CardinalButton(selection: $latDirection, highlightColor: config.cardinalColor)
        case .segment: CardinalSegmentControl(selection: $latDirection, highlightColor: config.cardinalColor)
        }
    }

    @ViewBuilder
    func cardinalLon() -> some View {
        switch config.cardinalStyle {
        case .button:  CardinalButton(selection: $lonDirection, highlightColor: config.cardinalColor)
        case .segment: CardinalSegmentControl(selection: $lonDirection, highlightColor: config.cardinalColor)
        }
    }

    // MARK: - Helpers

    func delimiterText(_ symbol: String) -> some View {
        Text(symbol).foregroundColor(theme.color.secondary).fontStyle(theme.typography.body)
    }

    var latSecondsPlaceholder: String {
        config.secondsPrecision == 0 ? "00" : "00." + String(repeating: "0", count: config.secondsPrecision)
    }

    var latSecondsMaxChar: Int {
        config.secondsPrecision == 0 ? 2 : 2 + 1 + config.secondsPrecision
    }

    var lonSecondsPlaceholder: String { latSecondsPlaceholder }
    var lonSecondsMaxChar: Int { latSecondsMaxChar }

    // MARK: - Preview

    @ViewBuilder
    func buildPreview() -> some View {
        if let pos = position {
            VStack(alignment: .leading, spacing: theme.spacing.grid1x) {
                previewRow("±DD", signedDDString(pos))
                previewRow("DD", decimalDDString(pos))
                previewRow("DDM", ddmString(pos))
                previewRow("DMS", dmsString(pos))
            }
            .padding(theme.spacing.grid2x)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.color.surfaceHigh.opacity(0.6))
            .cornerRadius(theme.radius.medium)
        }
    }

    func previewRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: theme.spacing.grid1x) {
            Text(label)
                .foregroundColor(theme.color.secondary)
                .fontStyle(theme.typography.caption1)
                .frame(minWidth: 36, alignment: .leading)
            Text(value)
                .foregroundColor(theme.color.inputOutput)
                .fontStyle(theme.typography.caption1)
        }
    }
}
