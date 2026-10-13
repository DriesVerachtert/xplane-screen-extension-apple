import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("DataRefStore")
@MainActor
struct DataRefStoreTests {
    @Test("subscribing sends a sub command")
    func subscribeSendsCommand() async {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        let subscription = await store.subscribe(ref: "sim/flightmodel/misc/h_ind", accuracy: 10.0)

        let sent = await transport.sentCommands
        #expect(sent == [.subscribe(ref: "sim/flightmodel/misc/h_ind", accuracy: 10.0)])
        _ = subscription
    }

    @Test("a second subscriber to the same ref doesn't send a second sub")
    func secondSubscriberDoesNotResubscribe() async {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        let first = await store.subscribe(ref: "sim/flightmodel/misc/h_ind")
        let second = await store.subscribe(ref: "sim/flightmodel/misc/h_ind")

        let sent = await transport.sentCommands
        #expect(sent == [.subscribe(ref: "sim/flightmodel/misc/h_ind")])
        _ = (first, second)
    }

    @Test("unsubscribing while another subscriber remains doesn't send unsub")
    func unsubscribeWithRemainingSubscriberKeepsSubscription() async {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        let first = await store.subscribe(ref: "a/b")
        _ = await store.subscribe(ref: "a/b")

        await store.unsubscribe(ref: "a/b")

        let sent = await transport.sentCommands
        #expect(sent == [.subscribe(ref: "a/b")])
        _ = first
    }

    @Test("unsubscribing the last subscriber sends unsub and drops the cached value")
    func unsubscribeLastSubscriberSendsUnsub() async {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        _ = await store.subscribe(ref: "a/b")
        store.handle(.update(ref: "a/b", value: .int(1)))
        #expect(store.value(for: "a/b") == .int(1))

        await store.unsubscribe(ref: "a/b")

        let sent = await transport.sentCommands
        #expect(sent == [.subscribe(ref: "a/b"), .unsubscribe(ref: "a/b")])
        #expect(store.value(for: "a/b") == nil)
    }

    @Test("handling an update event stores the value")
    func handleUpdateStoresValue() {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        store.handle(.update(ref: "sim/cockpit2/gauges/indicators/slip_deg", value: .float(-0.023)))

        #expect(store.value(for: "sim/cockpit2/gauges/indicators/slip_deg") == .float(-0.023))
    }

    @Test("handling a non-update event (e.g. a warning) is a no-op")
    func handleNonUpdateEventIsNoOp() {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        store.handle(.warning("something"))

        #expect(store.value(for: "a/b") == nil)
    }

    @Test("send forwards a one-off command without subscribing")
    func sendForwardsCommandWithoutSubscribing() async {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        await store.send(.commandOnce("sim/flight_controls/landing_gear_toggle"))

        let sent = await transport.sentCommands
        #expect(sent == [.commandOnce("sim/flight_controls/landing_gear_toggle")])
    }

    @Test("an update event pushed through the transport's event stream updates the store")
    func eventsFlowThroughTransport() async {
        let transport = MockExtPlaneTransport()
        let store = DataRefStore(transport: transport)

        await transport.emit(.update(ref: "a/b", value: .int(42)))

        // The store consumes `transport.events` on a background Task; give it
        // a moment to actually run before asserting.
        var observed: ExtPlaneValue?
        for _ in 0 ..< 100 {
            observed = store.value(for: "a/b")
            if observed != nil {
                break
            }
            try? await Task.sleep(for: .milliseconds(5))
        }

        #expect(observed == .int(42))
    }
}
