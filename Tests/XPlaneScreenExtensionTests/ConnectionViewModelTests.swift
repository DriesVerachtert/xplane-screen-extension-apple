import Foundation
import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("ConnectionViewModel")
@MainActor
struct ConnectionViewModelTests {
    private func freshDefaults() -> UserDefaults {
        let suiteName = "ConnectionViewModelTests.\(UUID().uuidString)"
        // Always succeeds for a well-formed suite name; the fallback just
        // avoids a force-unwrap.
        return UserDefaults(suiteName: suiteName) ?? .standard
    }

    @Test("defaults to port 51000 with no stored connection")
    func defaultsWithNoStoredConnection() {
        let viewModel = ConnectionViewModel(transport: MockExtPlaneTransport(), defaults: freshDefaults())
        #expect(viewModel.host == "")
        #expect(viewModel.port == "51000")
        #expect(viewModel.status == .disconnected)
    }

    @Test("loads a previously saved host and port")
    func loadsPersistedConnection() {
        let defaults = freshDefaults()
        defaults.set("192.168.1.50", forKey: "eu.dries.xplanescreenextension.lastHost")
        defaults.set("51001", forKey: "eu.dries.xplanescreenextension.lastPort")

        let viewModel = ConnectionViewModel(transport: MockExtPlaneTransport(), defaults: defaults)

        #expect(viewModel.host == "192.168.1.50")
        #expect(viewModel.port == "51001")
    }

    @Test("canConnect requires a non-empty host and a valid port number")
    func canConnectValidation() {
        let viewModel = ConnectionViewModel(transport: MockExtPlaneTransport(), defaults: freshDefaults())

        viewModel.host = ""
        viewModel.port = "51000"
        #expect(!viewModel.canConnect)

        viewModel.host = "192.168.1.50"
        viewModel.port = "not-a-number"
        #expect(!viewModel.canConnect)

        viewModel.host = "192.168.1.50"
        viewModel.port = "51000"
        #expect(viewModel.canConnect)
    }

    @Test("connect() with a valid host/port connects the transport and persists the values")
    func connectSendsToTransportAndPersists() async {
        let transport = MockExtPlaneTransport()
        let defaults = freshDefaults()
        let viewModel = ConnectionViewModel(transport: transport, defaults: defaults)
        viewModel.host = "  192.168.1.50  "
        viewModel.port = "51000"

        await viewModel.connect()

        let calls = await transport.connectCalls
        #expect(calls == [MockExtPlaneTransport.ConnectCall(host: "192.168.1.50", port: 51000)])
        #expect(defaults.string(forKey: "eu.dries.xplanescreenextension.lastHost") == "192.168.1.50")
        #expect(defaults.string(forKey: "eu.dries.xplanescreenextension.lastPort") == "51000")
    }

    @Test("connect() with an invalid port fails locally without calling the transport")
    func connectWithInvalidPortFailsLocally() async {
        let transport = MockExtPlaneTransport()
        let viewModel = ConnectionViewModel(transport: transport, defaults: freshDefaults())
        viewModel.host = "192.168.1.50"
        viewModel.port = "not-a-number"

        await viewModel.connect()

        let calls = await transport.connectCalls
        #expect(calls.isEmpty)
        #expect(viewModel.status == .failed("Enter a valid host and port"))
    }

    @Test("disconnect() calls through to the transport")
    func disconnectCallsTransport() async {
        let transport = MockExtPlaneTransport()
        let viewModel = ConnectionViewModel(transport: transport, defaults: freshDefaults())

        await viewModel.disconnect()

        let count = await transport.disconnectCallCount
        #expect(count == 1)
    }

    @Test("status updates pushed by the transport are reflected on the view model")
    func statusFlowsThroughTransport() async {
        let transport = MockExtPlaneTransport()
        let viewModel = ConnectionViewModel(transport: transport, defaults: freshDefaults())

        await transport.emit(ExtPlaneConnectionStatus.connecting)

        var observed: ExtPlaneConnectionStatus?
        for _ in 0 ..< 100 {
            observed = viewModel.status
            if observed == .connecting {
                break
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(observed == .connecting)

        await transport.emit(ExtPlaneConnectionStatus.connected)
        for _ in 0 ..< 100 {
            observed = viewModel.status
            if observed == .connected {
                break
            }
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(observed == .connected)
    }
}
