import SwiftUI

/// The instruments a `Page` can place, and how each one is actually rendered.
/// Adding a new instrument type means adding a case here plus its live view.
enum InstrumentKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case altimeter
    case airspeedIndicator
    case attitudeIndicator

    var id: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .altimeter: "Altimeter"
        case .airspeedIndicator: "Airspeed Indicator"
        case .attitudeIndicator: "Attitude Indicator"
        }
    }

    @ViewBuilder
    func view(store: DataRefStore) -> some View {
        switch self {
        case .altimeter: AltimeterView(store: store)
        case .airspeedIndicator: AirspeedIndicatorView(store: store)
        case .attitudeIndicator: AttitudeIndicatorView(store: store)
        }
    }
}
