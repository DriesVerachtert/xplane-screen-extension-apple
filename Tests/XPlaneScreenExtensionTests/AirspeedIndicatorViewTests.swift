import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("AirspeedIndicatorView Vne-based scaling")
struct AirspeedIndicatorViewTests {
    @Test("falls back to 200kt max with no redline when Vne hasn't arrived yet")
    func fallsBackWhenNil() {
        #expect(AirspeedIndicatorView.maxKnots(vne: nil) == 200)
        #expect(AirspeedIndicatorView.redlineValue(vne: nil) == nil)
    }

    @Test("falls back to 200kt max with no redline when Vne is zero or negative (not yet valid)")
    func fallsBackWhenNonPositive() {
        #expect(AirspeedIndicatorView.maxKnots(vne: 0) == 200)
        #expect(AirspeedIndicatorView.maxKnots(vne: -5) == 200)
        #expect(AirspeedIndicatorView.redlineValue(vne: 0) == nil)
        #expect(AirspeedIndicatorView.redlineValue(vne: -5) == nil)
    }

    @Test("uses 115% of Vne as the dial max, with Vne itself as the redline, when Vne is valid")
    func usesVneWithHeadroomWhenPositive() {
        #expect(AirspeedIndicatorView.maxKnots(vne: 300) == 345)
        #expect(AirspeedIndicatorView.redlineValue(vne: 300) == 300)

        #expect(AirspeedIndicatorView.maxKnots(vne: 160) == 184)
        #expect(AirspeedIndicatorView.redlineValue(vne: 160) == 160)
    }
}
