import Foundation

/// The lifecycle of a connection attempt, as reported on `ExtPlaneTransport.status`.
enum ExtPlaneConnectionStatus: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}
