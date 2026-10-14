import SwiftUI

/// Live airspeed indicator: subscribes to `DataRefStore` and renders
/// `RadialGaugeView`, scaled to the loaded aircraft's never-exceed speed
/// (`acf_Vne`) rather than a fixed range -- matching ExtPlane-Panel's own
/// airspeed indicator, which uses the same dataref for the same reason
/// (a light GA default range pins at max on anything faster).
///
/// The dial extends a bit past Vne (X-Plane doesn't expose a reliable
/// "design dive speed" dataref to use as a real upper bound) with a red
/// line marking Vne itself, so overspeed shows as "past the red line"
/// rather than being indistinguishable from flying exactly at the limit.
struct AirspeedIndicatorView: View {
    static let ref = "sim/cockpit2/gauges/indicators/airspeed_kts_pilot"
    static let vneRef = "sim/aircraft/view/acf_Vne"
    static let fallbackMaxKnots: Double = 200
    static let headroomFactor: Double = 1.15

    let store: DataRefStore

    var body: some View {
        let knots = store.value(for: Self.ref)?.doubleValue ?? 0
        let vne = store.value(for: Self.vneRef)?.doubleValue
        RadialGaugeView(
            title: "IAS",
            valueText: Int(knots.rounded()).formatted(),
            unit: "KT",
            needleValue: knots,
            needleRange: 0 ... Self.maxKnots(vne: vne),
            redlineValue: Self.redlineValue(vne: vne)
        )
        .subscribingDataRefs(store, [
            .init(ref: Self.ref, accuracy: 0.1),
            .init(ref: Self.vneRef)
        ])
    }

    static func maxKnots(vne: Double?) -> Double {
        guard let vne, vne > 0 else { return fallbackMaxKnots }
        return vne * headroomFactor
    }

    static func redlineValue(vne: Double?) -> Double? {
        guard let vne, vne > 0 else { return nil }
        return vne
    }
}
