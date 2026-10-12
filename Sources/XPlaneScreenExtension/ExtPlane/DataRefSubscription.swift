import Foundation

/// A handle returned by `DataRefStore.subscribe`. Unsubscribes automatically
/// when released, so a view can just hold this in `@State` for as long as it
/// wants live updates.
final class DataRefSubscription {
    private let ref: String
    private let store: DataRefStore

    init(ref: String, store: DataRefStore) {
        self.ref = ref
        self.store = store
    }

    deinit {
        let store = store
        let ref = ref
        Task { await store.unsubscribe(ref: ref) }
    }
}
