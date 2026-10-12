import Foundation
import Network

/// A TCP connection to the ExtPlane plugin: sends `ExtPlaneCommand`s and
/// publishes parsed `ExtPlaneEvent`s as they arrive.
actor ExtPlaneConnection: ExtPlaneTransport {
    enum Failure: Error {
        case notConnected
        case invalidPort(UInt16)
    }

    nonisolated let events: AsyncStream<ExtPlaneEvent>
    nonisolated let status: AsyncStream<ExtPlaneConnectionStatus>

    private let eventsContinuation: AsyncStream<ExtPlaneEvent>.Continuation
    private let statusContinuation: AsyncStream<ExtPlaneConnectionStatus>.Continuation
    private let queue = DispatchQueue(label: "eu.dries.xplanescreenextension.extplane-connection")
    private var connection: NWConnection?
    private var framer = ExtPlaneLineFramer()

    init() {
        var eventsContinuation: AsyncStream<ExtPlaneEvent>.Continuation!
        events = AsyncStream { eventsContinuation = $0 }
        self.eventsContinuation = eventsContinuation

        var statusContinuation: AsyncStream<ExtPlaneConnectionStatus>.Continuation!
        status = AsyncStream { statusContinuation = $0 }
        self.statusContinuation = statusContinuation
    }

    deinit {
        eventsContinuation.finish()
        statusContinuation.finish()
    }

    func connect(host: String, port: UInt16) async throws {
        await disconnect()
        statusContinuation.yield(.connecting)

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            let failure = Failure.invalidPort(port)
            statusContinuation.yield(.failed("Invalid port \(port)"))
            throw failure
        }

        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
        self.connection = connection
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { await self.handleStateUpdate(state) }
        }
        connection.start(queue: queue)
        receiveNext(on: connection)
    }

    func disconnect() async {
        connection?.cancel()
        connection = nil
        framer = ExtPlaneLineFramer()
        statusContinuation.yield(.disconnected)
    }

    func send(_ command: ExtPlaneCommand) async throws {
        guard let connection else { throw Failure.notConnected }
        guard let data = (command.wireFormat + "\n").data(using: .utf8) else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            connection.send(
                content: data,
                completion: .contentProcessed { error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            )
        }
    }

    private func receiveNext(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task { await self.handleReceive(connection: connection, data: data, isComplete: isComplete, error: error) }
        }
    }

    private func handleReceive(connection: NWConnection, data: Data?, isComplete: Bool, error: Error?) {
        if let data, !data.isEmpty {
            for line in framer.append(data) {
                eventsContinuation.yield(.parse(line: line))
            }
        }
        if isComplete || error != nil {
            // Don't finish `events` here: it's shared across reconnects, and a
            // finished AsyncStream can never deliver again. Just stop reading
            // from this now-dead connection; `handleStateUpdate` reports the
            // lifecycle change via `status`.
            return
        }
        // Another call to connect() may have replaced self.connection while
        // this receive was in flight; don't keep reading from a stale one.
        guard self.connection === connection else { return }
        receiveNext(on: connection)
    }

    private func handleStateUpdate(_ state: NWConnection.State) {
        switch state {
        case .ready:
            statusContinuation.yield(.connected)
        case let .failed(error):
            statusContinuation.yield(.failed(error.localizedDescription))
        case .cancelled:
            statusContinuation.yield(.disconnected)
        default:
            break
        }
    }
}
