import Foundation

/// What `DataRefStore` needs from a connection to ExtPlane: send commands,
/// receive events. `ExtPlaneConnection` is the real, `NWConnection`-backed
/// implementation; `MockExtPlaneTransport` stands in for it in tests and
/// SwiftUI Previews.
protocol ExtPlaneTransport: Sendable {
    var events: AsyncStream<ExtPlaneEvent> { get }
    func send(_ command: ExtPlaneCommand) async throws
}
