import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("RadialGaugeView needle angle")
@MainActor
struct RadialGaugeViewTests {
    private func gauge(needleValue: Double, range: ClosedRange<Double> = 0 ... 100) -> RadialGaugeView {
        RadialGaugeView(title: "T", valueText: "0", unit: "U", needleValue: needleValue, needleRange: range)
    }

    @Test("minimum of the range maps to the start angle")
    func minimumMapsToStartAngle() {
        #expect(gauge(needleValue: 0).needleAngle == -130)
    }

    @Test("maximum of the range maps to the end angle")
    func maximumMapsToEndAngle() {
        #expect(gauge(needleValue: 100).needleAngle == 130)
    }

    @Test("midpoint of the range maps to the midpoint angle")
    func midpointMapsToMidpointAngle() {
        #expect(gauge(needleValue: 50).needleAngle == 0)
    }

    @Test("values below the range are clamped to the start angle")
    func belowRangeClamped() {
        #expect(gauge(needleValue: -20).needleAngle == -130)
    }

    @Test("values above the range are clamped to the end angle")
    func aboveRangeClamped() {
        #expect(gauge(needleValue: 150).needleAngle == 130)
    }

    @Test("a zero-width range doesn't divide by zero")
    func zeroWidthRange() {
        #expect(gauge(needleValue: 5, range: 5 ... 5).needleAngle == -130)
    }
}
