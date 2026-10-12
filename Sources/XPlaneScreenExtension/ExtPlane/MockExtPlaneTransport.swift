import Foundation

/// A fake `ExtPlaneTransport` for unit tests and, later, SwiftUI Previews --
/// stands in for a real socket. Records every command sent to it, and lets
/// the caller push server events in on demand via `emit`.
actor MockExtPlaneTransport: ExtPlaneTransport {
    nonisolated let events: AsyncStream<ExtPlaneEvent>

    private let continuation: AsyncStream<ExtPlaneEvent>.Continuation
    private(set) var sentCommands: [ExtPlaneCommand] = []

    init() {
        var continuation: AsyncStream<ExtPlaneEvent>.Continuation!
        events = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    func send(_ command: ExtPlaneCommand) async throws {
        sentCommands.append(command)
    }

    func emit(_ event: ExtPlaneEvent) {
        continuation.yield(event)
    }
}
