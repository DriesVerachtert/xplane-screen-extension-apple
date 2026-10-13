import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("FlightControlsPanelView state mapping")
struct FlightControlsPanelViewTests {
    @Test("parking brake is off when the dataref hasn't arrived yet")
    func parkingBrakeDefaultsOff() {
        #expect(FlightControlsPanelView.isParkingBrakeOn(nil) == false)
    }

    @Test("parking brake on/off thresholds")
    func parkingBrakeThreshold() {
        #expect(FlightControlsPanelView.isParkingBrakeOn(.float(0)) == false)
        #expect(FlightControlsPanelView.isParkingBrakeOn(.float(0.4)) == false)
        #expect(FlightControlsPanelView.isParkingBrakeOn(.float(0.5)) == true)
        #expect(FlightControlsPanelView.isParkingBrakeOn(.float(1)) == true)
    }

    @Test("gear is assumed down when the dataref hasn't arrived yet, the safer default to display")
    func gearDefaultsDown() {
        #expect(FlightControlsPanelView.isGearDown(nil) == true)
    }

    @Test("gear up/down thresholds")
    func gearThreshold() {
        #expect(FlightControlsPanelView.isGearDown(.int(0)) == false)
        #expect(FlightControlsPanelView.isGearDown(.int(1)) == true)
    }

    @Test("flap percent defaults to 0 when the dataref hasn't arrived yet")
    func flapPercentDefault() {
        #expect(FlightControlsPanelView.flapPercent(nil) == 0)
    }

    @Test("flap percent converts a 0-1 ratio to a rounded whole percentage")
    func flapPercentConversion() {
        #expect(FlightControlsPanelView.flapPercent(.float(0)) == 0)
        #expect(FlightControlsPanelView.flapPercent(.float(0.4)) == 40)
        #expect(FlightControlsPanelView.flapPercent(.float(1)) == 100)
        #expect(FlightControlsPanelView.flapPercent(.float(0.333)) == 33)
    }
}
