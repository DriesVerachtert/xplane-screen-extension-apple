import SwiftUI

/// Live altimeter: subscribes to `DataRefStore` and renders `RadialGaugeView`.
/// The needle wraps every 1000ft, like a real altimeter's hundreds pointer;
/// the digital readout underneath shows the full altitude.
struct AltimeterView: View {
    static let ref = "sim/flightmodel/misc/h_ind"

    let store: DataRefStore

    var body: some View {
        let feet = store.value(for: Self.ref)?.doubleValue ?? 0
        RadialGaugeView(
            title: "ALT",
            valueText: Int(feet.rounded()).formatted(),
            unit: "FT",
            needleValue: feet.truncatingRemainder(dividingBy: 1000),
            needleRange: 0 ... 1000
        )
        .subscribingDataRefs(store, [.init(ref: Self.ref, accuracy: 3)])
    }
}
