import SwiftUI

/// A first, minimal instrument screen: the three v1 gauges side by side.
/// Placeholder for the real layout editor (a later step) -- just enough to
/// validate that live data actually reaches an instrument end to end.
struct InstrumentsView: View {
    let store: DataRefStore

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 16) {
                AltimeterView(store: store)
                    .frame(width: 200, height: 200)
                AirspeedIndicatorView(store: store)
                    .frame(width: 200, height: 200)
                AttitudeIndicatorView(store: store)
                    .frame(width: 200, height: 200)
            }
            .padding()
        }
        .navigationTitle("Instruments")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
