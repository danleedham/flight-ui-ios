import SwiftUI

// MARK: - CoordinateField Validation & Data

extension CoordinateField {

    var segmentInputConfig: InputFieldConfig {
        InputFieldConfig(fontColor: config.fontColor, fontStyle: config.fontStyle,
                         backgroundColor: config.backgroundColor,
                         cornerRadius: config.cornerRadius, borderColor: config.borderColor)
    }

    // MARK: Validation

    func validateCurrentFormat() {
        switch format {
        case .signedDecimalDegrees: validateSignedDD()
        case .decimalDegrees:       validateUnsignedDD()
        case .ddm:                  validateDDM()
        case .dms:                  validateDMS()
        }
    }

    func validateSignedDD() {
        latitude = Double(latDecimalDegreesText).flatMap {
            Latitude.isValid(decimalDegrees: $0) ? Latitude(decimalDegrees: $0) : nil
        }
        longitude = Double(lonDecimalDegreesText).flatMap {
            Longitude.isValid(decimalDegrees: $0) ? Longitude(decimalDegrees: $0) : nil
        }
    }

    func validateUnsignedDD() {
        if let val = Double(latDecimalDegreesText), val >= 0, val <= 90 {
            let signed = latDirection == .north ? val : -val
            latitude = Latitude.isValid(decimalDegrees: signed) ? Latitude(decimalDegrees: signed) : nil
        } else { latitude = nil }
        if let val = Double(lonDecimalDegreesText), val >= 0, val <= 180 {
            let signed = lonDirection == .east ? val : -val
            longitude = Longitude.isValid(decimalDegrees: signed) ? Longitude(decimalDegrees: signed) : nil
        } else { longitude = nil }
    }

    func validateDDM() {
        if let degs = Int(latDegreesText), let mins = Double(latMinutesText),
           degs >= 0, degs <= 90, mins >= 0, mins < 60 {
            let signed = (latDirection == .north ? 1.0 : -1.0) * (Double(degs) + mins / 60.0)
            latitude = Latitude.isValid(decimalDegrees: signed) ? Latitude(decimalDegrees: signed) : nil
        } else { latitude = nil }
        if let degs = Int(lonDegreesText), let mins = Double(lonMinutesText),
           degs >= 0, degs <= 180, mins >= 0, mins < 60 {
            let signed = (lonDirection == .east ? 1.0 : -1.0) * (Double(degs) + mins / 60.0)
            longitude = Longitude.isValid(decimalDegrees: signed) ? Longitude(decimalDegrees: signed) : nil
        } else { longitude = nil }
    }

    func validateDMS() {
        if let degs = Int(latDegreesText), let mins = Int(latMinutesText), let secs = Double(latSecondsText),
           degs >= 0, degs <= 90, mins >= 0, mins < 60, secs >= 0, secs < 60 {
            let signed = (latDirection == .north ? 1.0 : -1.0) * (Double(degs) + Double(mins) / 60.0 + secs / 3600.0)
            latitude = Latitude.isValid(decimalDegrees: signed) ? Latitude(decimalDegrees: signed) : nil
        } else { latitude = nil }
        if let degs = Int(lonDegreesText), let mins = Int(lonMinutesText), let secs = Double(lonSecondsText),
           degs >= 0, degs <= 180, mins >= 0, mins < 60, secs >= 0, secs < 60 {
            let signed = (lonDirection == .east ? 1.0 : -1.0) * (Double(degs) + Double(mins) / 60.0 + secs / 3600.0)
            longitude = Longitude.isValid(decimalDegrees: signed) ? Longitude(decimalDegrees: signed) : nil
        } else { longitude = nil }
    }

    // MARK: Assembly & Population

    func assemblePosition() {
        guard let lat = latitude, let lon = longitude else { position = nil; return }
        position = Position2D(latitude: lat, longitude: lon)
    }

    func decomposePosition() {
        guard let pos = position else { return }
        populateSegments(from: pos.latitude, lon: pos.longitude)
    }

    func populateSegments() {
        guard let pos = position else { clearSegments(); return }
        populateSegments(from: pos.latitude, lon: pos.longitude)
    }

    func populateSegments(from lat: Latitude, lon: Longitude) {
        switch format {
        case .signedDecimalDegrees:
            latDecimalDegreesText = String(format: "%.5f", lat.decimalDegrees)
            lonDecimalDegreesText = String(format: "%.5f", lon.decimalDegrees)
        case .decimalDegrees:
            latDirection = lat.direction
            latDecimalDegreesText = String(format: "%.5f", lat.unsignedDecimalDegrees)
            lonDirection = lon.direction
            lonDecimalDegreesText = String(format: "%.5f", lon.unsignedDecimalDegrees)
        case .ddm:
            let latDDM = lat.degreesDecimalMinutes
            latDirection = lat.direction; latDegreesText = String(latDDM.degrees)
            latMinutesText = String(format: "%.3f", latDDM.minutes)
            let lonDDM = lon.degreesDecimalMinutes
            lonDirection = lon.direction; lonDegreesText = String(lonDDM.degrees)
            lonMinutesText = String(format: "%.3f", lonDDM.minutes)
        case .dms:
            let latDMS = lat.degreesMinutesSeconds
            latDirection = lat.direction; latDegreesText = String(latDMS.degrees)
            latMinutesText = String(latDMS.minutes)
            latSecondsText = String(format: "%.\(config.secondsPrecision)f", latDMS.seconds)
            let lonDMS = lon.degreesMinutesSeconds
            lonDirection = lon.direction; lonDegreesText = String(lonDMS.degrees)
            lonMinutesText = String(lonDMS.minutes)
            lonSecondsText = String(format: "%.\(config.secondsPrecision)f", lonDMS.seconds)
        }
    }

    func clearSegments() {
        latDecimalDegreesText = ""; lonDecimalDegreesText = ""
        latDegreesText = "";        lonDegreesText = ""
        latMinutesText = "";        lonMinutesText = ""
        latSecondsText = "";        lonSecondsText = ""
    }

    // MARK: Smart Paste

    func parseCoordinateString(_ text: String) {
        let pattern = #"[-+]?\d+\.?\d*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        guard matches.count >= 2 else { return }
        let nums = matches.prefix(2).compactMap { match -> Double? in
            guard let range = Range(match.range, in: text) else { return nil }
            return Double(String(text[range]))
        }
        guard nums.count == 2,
              abs(nums[0]) <= 90, abs(nums[1]) <= 180,
              Latitude.isValid(decimalDegrees: nums[0]),
              Longitude.isValid(decimalDegrees: nums[1]) else { return }
        populateSegments(from: Latitude(decimalDegrees: nums[0]), lon: Longitude(decimalDegrees: nums[1]))
    }

    // MARK: Preview Strings

    func signedDDString(_ pos: Position2D) -> String {
        String(format: "%.5f°, %.5f°", pos.latitude.decimalDegrees, pos.longitude.decimalDegrees)
    }

    func decimalDDString(_ pos: Position2D) -> String {
        let lat = pos.latitude; let lon = pos.longitude
        return "\(lat.direction.rawValue) \(String(format: "%.5f", lat.unsignedDecimalDegrees))°, "
             + "\(lon.direction.rawValue) \(String(format: "%.5f", lon.unsignedDecimalDegrees))°"
    }

    func ddmString(_ pos: Position2D) -> String {
        let latComp = pos.latitude.degreesDecimalMinutes
        let lonComp = pos.longitude.degreesDecimalMinutes
        return "\(pos.latitude.direction.rawValue) \(latComp.degrees)° \(String(format: "%.3f", latComp.minutes))', "
             + "\(pos.longitude.direction.rawValue) \(lonComp.degrees)° \(String(format: "%.3f", lonComp.minutes))'"
    }

    func dmsString(_ pos: Position2D) -> String {
        let latComp = pos.latitude.degreesMinutesSeconds
        let lonComp = pos.longitude.degreesMinutesSeconds
        let fmt = "%.\(config.secondsPrecision)f"
        return "\(pos.latitude.direction.rawValue) \(latComp.degrees)° \(latComp.minutes)' "
             + "\(String(format: fmt, latComp.seconds))\", "
             + "\(pos.longitude.direction.rawValue) \(lonComp.degrees)° \(lonComp.minutes)' "
             + "\(String(format: fmt, lonComp.seconds))\""
    }

    // MARK: Segment Alerting States

    var latDDState: InputAlertingState {
        let limit: ClosedRange<Double> = format == .signedDecimalDegrees ? -90...90 : 0...90
        return segmentState(text: latDecimalDegreesText, parse: Double.init, range: limit)
    }

    var lonDDState: InputAlertingState {
        let limit: ClosedRange<Double> = format == .signedDecimalDegrees ? -180...180 : 0...180
        return segmentState(text: lonDecimalDegreesText, parse: Double.init, range: limit)
    }

    var latDegreesState: InputAlertingState { segmentState(text: latDegreesText, parse: Int.init, range: 0...90) }
    var lonDegreesState: InputAlertingState { segmentState(text: lonDegreesText, parse: Int.init, range: 0...180) }
    var latMinDecState: InputAlertingState  { segmentState(text: latMinutesText, parse: Double.init, range: 0.0..<60.0) }
    var lonMinDecState: InputAlertingState  { segmentState(text: lonMinutesText, parse: Double.init, range: 0.0..<60.0) }
    var latMinIntState: InputAlertingState  { segmentState(text: latMinutesText, parse: Int.init, range: 0..<60) }
    var lonMinIntState: InputAlertingState  { segmentState(text: lonMinutesText, parse: Int.init, range: 0..<60) }
    var latSecondsState: InputAlertingState { segmentState(text: latSecondsText, parse: Double.init, range: 0.0..<60.0) }
    var lonSecondsState: InputAlertingState { segmentState(text: lonSecondsText, parse: Double.init, range: 0.0..<60.0) }

    private func segmentState<T: Comparable, R: RangeExpression>(
        text: String, parse: (String) -> T?, range: R
    ) -> InputAlertingState where R.Bound == T {
        guard !text.isEmpty, let val = parse(text) else { return alertingState }
        return range.contains(val) ? alertingState : .warning
    }
}
