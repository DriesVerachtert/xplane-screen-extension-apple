import SwiftUI

/// The instruments a `Page` can place, and how each one is actually rendered.
/// Adding a new instrument type means adding a case here plus its live view.
enum InstrumentKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case altimeter
    case airspeedIndicator
    case attitudeIndicator
    case flightControls

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .altimeter: "Altimeter"
        case .airspeedIndicator: "Airspeed Indicator"
        case .attitudeIndicator: "Attitude Indicator"
        case .flightControls: "Flight Controls"
        }
    }

    /// The size a newly-added item starts at -- gauges want a square, the
    /// controls panel wants room for its rows of buttons.
    var defaultSize: CGSize {
        switch self {
        case .altimeter, .airspeedIndicator, .attitudeIndicator: CGSize(width: 200, height: 200)
        case .flightControls: CGSize(width: 220, height: 260)
        }
    }

    @ViewBuilder
    func view(store: DataRefStore) -> some View {
        switch self {
        case .altimeter: AltimeterView(store: store)
        case .airspeedIndicator: AirspeedIndicatorView(store: store)
        case .attitudeIndicator: AttitudeIndicatorView(store: store)
        case .flightControls: FlightControlsPanelView(store: store)
        }
    }
}
