import SwiftUI

/// A circular dial with tick marks, a needle, and a digital readout.
/// Pure rendering -- no data-fetching, so it's trivially previewable and
/// testable with plain numbers. Shared by the altimeter and airspeed
/// indicator, which differ only in range and labeling.
struct RadialGaugeView: View {
    let title: String
    let valueText: String
    let unit: String
    let needleValue: Double
    let needleRange: ClosedRange<Double>
    var majorTicks: Int = 10
    /// An optional "do not exceed" value, marked with a red tick distinct
    /// from the regular white ones (e.g. an aircraft's Vne on the airspeed
    /// indicator). `nil` draws nothing.
    var redlineValue: Double?

    private let startAngle: Double = -130
    private let endAngle: Double = 130

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                Circle().fill(.black)

                ForEach(0 ... majorTicks, id: \.self) { tick in
                    tickMark(index: tick, size: size)
                }

                redlineMark(size: size)

                readout(size: size)

                Capsule()
                    .fill(.red)
                    .frame(width: size * 0.025, height: size * 0.4)
                    .offset(y: -size * 0.2)
                    .rotationEffect(.degrees(angle(forValue: needleValue)))

                Circle()
                    .fill(.white)
                    .frame(width: size * 0.06, height: size * 0.06)
            }
            .frame(width: size, height: size)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Internal rather than private so it's directly unit-testable.
    var needleAngle: Double {
        angle(forValue: needleValue)
    }

    private func angle(forValue value: Double) -> Double {
        let clamped = min(max(value, needleRange.lowerBound), needleRange.upperBound)
        let span = needleRange.upperBound - needleRange.lowerBound
        let fraction = span == 0 ? 0 : (clamped - needleRange.lowerBound) / span
        return startAngle + fraction * (endAngle - startAngle)
    }

    private func tickMark(index: Int, size: Double) -> some View {
        let fraction = Double(index) / Double(majorTicks)
        let angle = startAngle + fraction * (endAngle - startAngle)
        return Rectangle()
            .fill(.white)
            .frame(width: size * 0.015, height: size * 0.08)
            .offset(y: -size * 0.44)
            .rotationEffect(.degrees(angle))
    }

    @ViewBuilder
    private func redlineMark(size: Double) -> some View {
        if let redlineValue, needleRange.contains(redlineValue) {
            Rectangle()
                .fill(.red)
                .frame(width: size * 0.025, height: size * 0.1)
                .offset(y: -size * 0.44)
                .rotationEffect(.degrees(angle(forValue: redlineValue)))
        }
    }

    private func readout(size: Double) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: size * 0.07, weight: .semibold))
            Text(valueText)
                .font(.system(size: size * 0.11, weight: .bold, design: .monospaced))
            Text(unit)
                .font(.system(size: size * 0.06))
        }
        .foregroundStyle(.white)
        .offset(y: size * 0.22)
    }
}

#Preview("Altimeter-style") {
    RadialGaugeView(title: "ALT", valueText: "3,450", unit: "FT", needleValue: 450, needleRange: 0 ... 1000)
        .frame(width: 220, height: 220)
        .padding()
        .background(Color.gray.opacity(0.2))
}

#Preview("Airspeed-style, approaching Vne") {
    RadialGaugeView(
        title: "IAS",
        valueText: "340",
        unit: "KT",
        needleValue: 340,
        needleRange: 0 ... 345,
        redlineValue: 300
    )
    .frame(width: 220, height: 220)
    .padding()
    .background(Color.gray.opacity(0.2))
}
