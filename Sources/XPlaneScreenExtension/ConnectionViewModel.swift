import Foundation
import Observation

/// Owns the connection to ExtPlane and the `DataRefStore` fed by it, and
/// tracks connection status for the connection screen. This is the app's
/// single long-lived piece of state -- created once, reused across
/// connect/disconnect cycles.
@MainActor
@Observable
final class ConnectionViewModel {
    static let defaultPort = "51000"

    private static let hostDefaultsKey = "eu.dries.xplanescreenextension.lastHost"
    private static let portDefaultsKey = "eu.dries.xplanescreenextension.lastPort"

    var host: String
    var port: String
    private(set) var status: ExtPlaneConnectionStatus = .disconnected

    let dataRefStore: DataRefStore

    @ObservationIgnored
    private let transport: any ExtPlaneTransport
    @ObservationIgnored
    private let defaults: UserDefaults
    @ObservationIgnored
    private nonisolated(unsafe) var statusTask: Task<Void, Never>?

    init(transport: any ExtPlaneTransport, defaults: UserDefaults = .standard) {
        self.transport = transport
        self.defaults = defaults
        dataRefStore = DataRefStore(transport: transport)
        host = defaults.string(forKey: Self.hostDefaultsKey) ?? ""
        port = defaults.string(forKey: Self.portDefaultsKey) ?? Self.defaultPort

        statusTask = Task { [weak self] in
            for await status in transport.status {
                self?.status = status
            }
        }
    }

    deinit {
        statusTask?.cancel()
    }

    var canConnect: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty && UInt16(port) != nil
    }

    func connect() async {
        let trimmedHost = host.trimmingCharacters(in: .whitespaces)
        guard let portNumber = UInt16(port), !trimmedHost.isEmpty else {
            status = .failed("Enter a valid host and port")
            return
        }
        defaults.set(trimmedHost, forKey: Self.hostDefaultsKey)
        defaults.set(port, forKey: Self.portDefaultsKey)
        do {
            try await transport.connect(host: trimmedHost, port: portNumber)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func disconnect() async {
        await transport.disconnect()
    }
}
