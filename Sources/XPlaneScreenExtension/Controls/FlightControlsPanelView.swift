import SwiftUI

/// A small panel of frequently used flight controls, so the pilot doesn't
/// need to remember X-Plane's default keyboard shortcuts.
///
/// The parking brake is toggled by setting its dataref directly (rather than
/// firing X-Plane's "B" key command, which actually toggles *regular* wheel
/// braking, a different system with no simple on/off state to read back) --
/// this gives a reliable, real state to display. Max brakes ("V") has no
/// dataref confirmed to reliably reflect its on/off state, so it's a plain
/// momentary action button instead of a faked toggle indicator.
struct FlightControlsPanelView: View {
    static let parkBrakeRef = "sim/flightmodel/controls/parkbrake"
    static let gearHandleRef = "sim/cockpit/switches/gear_handle_status"
    static let flapRatioRef = "sim/cockpit2/controls/flap_ratio"

    let store: DataRefStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            toggleRow(
                title: "Parking Brake",
                badge: Self.isParkingBrakeOn(store.value(for: Self.parkBrakeRef))
                    ? StateBadge(text: "ON", color: .red) : StateBadge(text: "OFF", color: .secondary)
            ) {
                let newValue: Double = Self.isParkingBrakeOn(store.value(for: Self.parkBrakeRef)) ? 0 : 1
                await store.send(.setScalar(ref: Self.parkBrakeRef, value: newValue))
            }

            actionRow(title: "Max Brakes", caption: "momentary") {
                await store.send(.commandOnce("sim/flight_controls/brakes_toggle_max"))
            }

            toggleRow(
                title: "Landing Gear",
                badge: Self.isGearDown(store.value(for: Self.gearHandleRef))
                    ? StateBadge(text: "DOWN", color: .green) : StateBadge(text: "UP", color: .secondary)
            ) {
                await store.send(.commandOnce("sim/flight_controls/landing_gear_toggle"))
            }

            flapsRow
        }
        .padding(12)
        .background(Color(white: 0.12), in: RoundedRectangle(cornerRadius: 12))
        .foregroundStyle(.white)
        .subscribingDataRefs(store, [
            .init(ref: Self.parkBrakeRef),
            .init(ref: Self.gearHandleRef),
            .init(ref: Self.flapRatioRef, accuracy: 0.01)
        ])
    }

    static func isParkingBrakeOn(_ value: ExtPlaneValue?) -> Bool {
        (value?.doubleValue ?? 0) >= 0.5
    }

    static func isGearDown(_ value: ExtPlaneValue?) -> Bool {
        (value?.doubleValue ?? 1) >= 0.5
    }

    static func flapPercent(_ value: ExtPlaneValue?) -> Int {
        Int(((value?.doubleValue ?? 0) * 100).rounded())
    }

    private var flapsRow: some View {
        HStack {
            Text("Flaps")
                .font(.subheadline)
            Text("\(Self.flapPercent(store.value(for: Self.flapRatioRef)))%")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                Task { await store.send(.commandOnce("sim/flight_controls/flaps_up")) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
            }
            Button {
                Task { await store.send(.commandOnce("sim/flight_controls/flaps_down")) }
            } label: {
                Image(systemName: "arrow.down.circle.fill")
            }
        }
        .buttonStyle(.plain)
        .font(.title3)
    }

    private func toggleRow(
        title: String,
        badge: StateBadge,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                badge
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func actionRow(title: String, caption: String, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct StateBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.25), in: Capsule())
            .foregroundStyle(color)
    }
}

#Preview {
    VStack {
        FlightControlsPanelView(store: DataRefStore(transport: MockExtPlaneTransport()))
    }
    .frame(width: 220)
    .padding()
}
