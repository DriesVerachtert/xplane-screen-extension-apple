import Foundation

/// A fake `ExtPlaneTransport` for unit tests and, later, SwiftUI Previews --
/// stands in for a real socket. Records every command sent and every
/// connect/disconnect call, and lets the caller push events/status in on
/// demand via `emit`.
actor MockExtPlaneTransport: ExtPlaneTransport {
    struct ConnectCall: Equatable, Sendable {
        let host: String
        let port: UInt16
    }

    nonisolated let events: AsyncStream<ExtPlaneEvent>
    nonisolated let status: AsyncStream<ExtPlaneConnectionStatus>

    private let eventsContinuation: AsyncStream<ExtPlaneEvent>.Continuation
    private let statusContinuation: AsyncStream<ExtPlaneConnectionStatus>.Continuation
    private(set) var sentCommands: [ExtPlaneCommand] = []
    private(set) var connectCalls: [ConnectCall] = []
    private(set) var disconnectCallCount = 0

    init() {
        var eventsContinuation: AsyncStream<ExtPlaneEvent>.Continuation!
        events = AsyncStream { eventsContinuation = $0 }
        self.eventsContinuation = eventsContinuation

        var statusContinuation: AsyncStream<ExtPlaneConnectionStatus>.Continuation!
        status = AsyncStream { statusContinuation = $0 }
        self.statusContinuation = statusContinuation
    }

    func connect(host: String, port: UInt16) async throws {
        connectCalls.append(ConnectCall(host: host, port: port))
    }

    func disconnect() async {
        disconnectCallCount += 1
    }

    func send(_ command: ExtPlaneCommand) async throws {
        sentCommands.append(command)
    }

    func emit(_ event: ExtPlaneEvent) {
        eventsContinuation.yield(event)
    }

    func emit(_ status: ExtPlaneConnectionStatus) {
        statusContinuation.yield(status)
    }
}
