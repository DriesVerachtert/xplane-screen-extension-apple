import Foundation
import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("ExtPlaneEvent parsing")
struct ExtPlaneEventTests {
    @Test("handshake lines")
    func handshake() {
        #expect(ExtPlaneEvent.parse(line: "EXTPLANE 1") == .connected(protocolVersion: 1))
        #expect(ExtPlaneEvent.parse(line: "EXTPLANE-VERSION 1003") == .serverVersion(1003))
        #expect(ExtPlaneEvent.parse(line: "CLIENT-ID abc123") == .clientID("abc123"))
    }

    @Test("warning, including one with spaces")
    func warning() {
        #expect(ExtPlaneEvent.parse(line: "EXTPLANE-WARNING something went wrong") == .warning("something went wrong"))
    }

    @Test("int update")
    func intUpdate() {
        let event = ExtPlaneEvent.parse(line: "ui sim/aircraft/engine/acf_num_engines 2")
        #expect(event == .update(ref: "sim/aircraft/engine/acf_num_engines", value: .int(2)))
    }

    @Test("float update, including negative values")
    func floatUpdate() {
        let event = ExtPlaneEvent.parse(line: "uf sim/cockpit2/gauges/indicators/slip_deg -0.023")
        #expect(event == .update(ref: "sim/cockpit2/gauges/indicators/slip_deg", value: .float(-0.023)))
    }

    @Test("double update")
    func doubleUpdate() {
        let event = ExtPlaneEvent.parse(line: "ud sim/flightmodel/misc/h_ind 267.32")
        #expect(event == .update(ref: "sim/flightmodel/misc/h_ind", value: .double(267.32)))
    }

    @Test("float array update")
    func floatArrayUpdate() {
        let event = ExtPlaneEvent.parse(line: "ufa sim/flightmodel/position/q [0.84599,-0.00730657,0.00933933,0.533067]")
        #expect(event == .update(ref: "sim/flightmodel/position/q", value: .floatArray([0.84599, -0.00730657, 0.00933933, 0.533067])))
    }

    @Test("int array update")
    func intArrayUpdate() {
        let event = ExtPlaneEvent.parse(line: "uia sim/cockpit2/engine/indicators/N1_percent [99,97]")
        #expect(event == .update(ref: "sim/cockpit2/engine/indicators/N1_percent", value: .intArray([99, 97])))
    }

    @Test("empty array update")
    func emptyArrayUpdate() {
        let event = ExtPlaneEvent.parse(line: "uia some/ref []")
        #expect(event == .update(ref: "some/ref", value: .intArray([])))
    }

    @Test("base64 data update")
    func dataUpdate() throws {
        let event = ExtPlaneEvent.parse(line: "ub sim/aircraft/view/acf_descrip RXh0UGxhbmUgU2ltdWxhdGVkIENvbm5lY3Rpb24=")
        let expectedData = try #require(Data(base64Encoded: "RXh0UGxhbmUgU2ltdWxhdGVkIENvbm5lY3Rpb24="))
        #expect(event == .update(ref: "sim/aircraft/view/acf_descrip", value: .data(expectedData)))
    }

    @Test("string-modifier data update, ref keeps the modifier suffix")
    func stringDataUpdate() {
        let event = ExtPlaneEvent.parse(line: "ub sim/aircraft/view/acf_descrip:string \"Boeing 737-800\"")
        #expect(event == .update(ref: "sim/aircraft/view/acf_descrip:string", value: .string("Boeing 737-800")))
    }

    @Test("malformed lines are kept as unrecognized rather than dropped or crashing")
    func malformedLines() {
        #expect(ExtPlaneEvent.parse(line: "nonsense") == .unrecognized("nonsense"))
        #expect(ExtPlaneEvent.parse(line: "EXTPLANE not-a-number") == .unrecognized("EXTPLANE not-a-number"))
        #expect(ExtPlaneEvent.parse(line: "ui some/ref not-a-number") == .unrecognized("ui some/ref not-a-number"))
        #expect(ExtPlaneEvent.parse(line: "uia some/ref [1,not-a-number]") == .unrecognized("uia some/ref [1,not-a-number]"))
        #expect(ExtPlaneEvent.parse(line: "uz some/ref 1") == .unrecognized("uz some/ref 1"))
    }
}
