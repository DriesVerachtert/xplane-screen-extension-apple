import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("ExtPlaneCommand wire format")
struct ExtPlaneCommandTests {
    @Test("subscribe without modifiers or accuracy")
    func subscribePlain() {
        let command = ExtPlaneCommand.subscribe(ref: "sim/cockpit/electrical/night_vision_on")
        #expect(command.wireFormat == "sub sim/cockpit/electrical/night_vision_on")
    }

    @Test("subscribe with accuracy")
    func subscribeWithAccuracy() {
        let command = ExtPlaneCommand.subscribe(ref: "sim/flightmodel/misc/h_ind", accuracy: 10.0)
        #expect(command.wireFormat == "sub sim/flightmodel/misc/h_ind 10.0")
    }

    @Test("subscribe with modifiers")
    func subscribeWithModifiers() {
        let command = ExtPlaneCommand.subscribe(ref: "sim/aircraft/view/acf_descrip", modifiers: ["string"])
        #expect(command.wireFormat == "sub sim/aircraft/view/acf_descrip:string")
    }

    @Test("subscribe with modifiers and accuracy")
    func subscribeWithModifiersAndAccuracy() {
        let command = ExtPlaneCommand.subscribe(ref: "a/b", modifiers: ["udp", "string"], accuracy: 1.5)
        #expect(command.wireFormat == "sub a/b:udp,string 1.5")
    }

    @Test("unsubscribe")
    func unsubscribe() {
        #expect(ExtPlaneCommand.unsubscribe(ref: "a/b").wireFormat == "unsub a/b")
    }

    @Test("get")
    func get() {
        let command = ExtPlaneCommand.get(ref: "sim/aircraft/engine/acf_num_engines")
        #expect(command.wireFormat == "get sim/aircraft/engine/acf_num_engines")
    }

    @Test("set scalar")
    func setScalar() {
        let command = ExtPlaneCommand.setScalar(ref: "sim/flightmodel/misc/h_ind", value: 267.32)
        #expect(command.wireFormat == "set sim/flightmodel/misc/h_ind 267.32")
    }

    @Test("set array, all values")
    func setArrayAll() {
        let command = ExtPlaneCommand.setArray(ref: "sim/flightmodel/engine/ENGN_thro", values: [1, 1])
        #expect(command.wireFormat == "set sim/flightmodel/engine/ENGN_thro [1.0,1.0]")
    }

    @Test("set array, skipping an index")
    func setArraySkippingIndex() {
        let command = ExtPlaneCommand.setArray(ref: "sim/flightmodel/engine/ENGN_thro", values: [nil, 1])
        #expect(command.wireFormat == "set sim/flightmodel/engine/ENGN_thro [,1.0]")
    }

    @Test("set string")
    func setString() {
        let command = ExtPlaneCommand.setString(ref: "sim/aircraft/view/acf_descrip", value: "This is an example")
        #expect(command.wireFormat == "set sim/aircraft/view/acf_descrip \"This is an example\"")
    }

    @Test("key")
    func key() {
        #expect(ExtPlaneCommand.key(0).wireFormat == "key 0")
    }

    @Test("button down/up")
    func buttonDownUp() {
        #expect(ExtPlaneCommand.buttonDown(5).wireFormat == "but 5")
        #expect(ExtPlaneCommand.buttonUp(5).wireFormat == "rel 5")
    }

    @Test("command once/begin/end")
    func commandLifecycle() {
        let gearToggle = ExtPlaneCommand.commandOnce("sim/flight_controls/landing_gear_toggle")
        #expect(gearToggle.wireFormat == "cmd once sim/flight_controls/landing_gear_toggle")
        #expect(ExtPlaneCommand.commandBegin("sim/engines/starter_1").wireFormat == "cmd begin sim/engines/starter_1")
        #expect(ExtPlaneCommand.commandEnd("sim/engines/starter_1").wireFormat == "cmd end sim/engines/starter_1")
    }

    @Test("disconnect")
    func disconnect() {
        #expect(ExtPlaneCommand.disconnect.wireFormat == "disconnect")
    }

    @Test("extplane setting")
    func setting() {
        let command = ExtPlaneCommand.setting(name: "update_interval", value: "0.1")
        #expect(command.wireFormat == "extplane-set update_interval 0.1")
    }
}
