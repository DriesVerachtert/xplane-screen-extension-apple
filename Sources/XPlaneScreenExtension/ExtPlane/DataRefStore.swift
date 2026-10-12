import Foundation
import Observation

/// The in-memory registry of current dataref values -- what instrument
/// widgets actually observe. Reference-counts subscriptions so that two
/// gauges wanting the same dataref result in a single `sub`/`unsub` to
/// ExtPlane, not two.
@MainActor
@Observable
final class DataRefStore {
    private(set) var values: [String: ExtPlaneValue] = [:]

    private let transport: any ExtPlaneTransport
    private var subscriptionCounts: [String: Int] = [:]
    /// `Task.cancel()` is thread-safe by design, so it's fine to call from
    /// `deinit`, which (unlike the rest of this MainActor class) isn't
    /// guaranteed to run on the main actor. Not observed, so it's exempted
    /// from `@Observable`'s tracking (which isn't compatible with `nonisolated`).
    @ObservationIgnored
    private nonisolated(unsafe) var eventTask: Task<Void, Never>?

    init(transport: any ExtPlaneTransport) {
        self.transport = transport
        eventTask = Task { [weak self] in
            for await event in transport.events {
                self?.handle(event)
            }
        }
    }

    deinit {
        eventTask?.cancel()
    }

    func value(for ref: String) -> ExtPlaneValue? {
        values[ref]
    }

    /// Subscribes to `ref`, sending `sub` to ExtPlane only if no other caller
    /// is already subscribed to it. Release the returned token to unsubscribe.
    @discardableResult
    func subscribe(ref: String, modifiers: [String] = [], accuracy: Double? = nil) async -> DataRefSubscription {
        let count = (subscriptionCounts[ref] ?? 0) + 1
        subscriptionCounts[ref] = count
        if count == 1 {
            try? await transport.send(.subscribe(ref: ref, modifiers: modifiers, accuracy: accuracy))
        }
        return DataRefSubscription(ref: ref, store: self)
    }

    /// Called by `DataRefSubscription` on release. Sends `unsub` to ExtPlane
    /// once the last subscriber for `ref` is gone.
    func unsubscribe(ref: String) async {
        guard let count = subscriptionCounts[ref] else { return }
        if count <= 1 {
            subscriptionCounts.removeValue(forKey: ref)
            values.removeValue(forKey: ref)
            try? await transport.send(.unsubscribe(ref: ref))
        } else {
            subscriptionCounts[ref] = count - 1
        }
    }

    func handle(_ event: ExtPlaneEvent) {
        guard case let .update(ref, value) = event else { return }
        values[ref] = value
    }
}
