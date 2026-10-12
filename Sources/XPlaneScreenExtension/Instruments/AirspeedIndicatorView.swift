import SwiftUI

/// Live airspeed indicator: subscribes to `DataRefStore` and renders
/// `RadialGaugeView` over a light-aircraft-sized 0-200kt range.
struct AirspeedIndicatorView: View {
    static let ref = "sim/cockpit2/gauges/indicators/airspeed_kts_pilot"

    let store: DataRefStore

    var body: some View {
        let knots = store.value(for: Self.ref)?.doubleValue ?? 0
        RadialGaugeView(
            title: "IAS",
            valueText: Int(knots.rounded()).formatted(),
            unit: "KT",
            needleValue: knots,
            needleRange: 0 ... 200
        )
        .subscribingDataRefs(store, [.init(ref: Self.ref, accuracy: 0.1)])
    }
}
