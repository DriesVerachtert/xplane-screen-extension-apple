import SwiftUI

/// Live attitude indicator: subscribes to the vacuum-instrument pitch/roll
/// datarefs (what the gauge itself would show, matching ExtPlane-Panel's
/// convention) and renders `AttitudeHorizonView`.
struct AttitudeIndicatorView: View {
    static let pitchRef = "sim/cockpit2/gauges/indicators/pitch_vacuum_deg_pilot"
    static let rollRef = "sim/cockpit2/gauges/indicators/roll_vacuum_deg_pilot"

    let store: DataRefStore

    var body: some View {
        let pitch = store.value(for: Self.pitchRef)?.doubleValue ?? 0
        let roll = store.value(for: Self.rollRef)?.doubleValue ?? 0
        AttitudeHorizonView(pitchDegrees: pitch, rollDegrees: roll)
            .subscribingDataRefs(store, [
                .init(ref: Self.pitchRef, accuracy: 0.05),
                .init(ref: Self.rollRef, accuracy: 0.05)
            ])
    }
}
