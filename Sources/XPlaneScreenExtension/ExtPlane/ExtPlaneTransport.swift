import Foundation

/// A connection to ExtPlane: connect/disconnect, its lifecycle status, send
/// commands, receive events. `ExtPlaneConnection` is the real, `NWConnection`-
/// backed implementation; `MockExtPlaneTransport` stands in for it in tests
/// and SwiftUI Previews.
protocol ExtPlaneTransport: Sendable {
    var events: AsyncStream<ExtPlaneEvent> { get }
    var status: AsyncStream<ExtPlaneConnectionStatus> { get }
    func connect(host: String, port: UInt16) async throws
    func disconnect() async
    func send(_ command: ExtPlaneCommand) async throws
}
