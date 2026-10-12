import SwiftUI

/// Subscribes to one or more datarefs for as long as the view is on screen,
/// via `DataRefStore`'s reference-counted subscriptions, releasing the
/// tokens (and so unsubscribing) when the view leaves the hierarchy.
struct DataRefSubscribing: ViewModifier {
    struct Subscription {
        let ref: String
        var modifiers: [String] = []
        var accuracy: Double?
    }

    let store: DataRefStore
    let subscriptions: [Subscription]

    @State private var tokens: [DataRefSubscription] = []

    func body(content: Content) -> some View {
        content.task {
            var newTokens: [DataRefSubscription] = []
            for subscription in subscriptions {
                let token = await store.subscribe(
                    ref: subscription.ref,
                    modifiers: subscription.modifiers,
                    accuracy: subscription.accuracy
                )
                newTokens.append(token)
            }
            tokens = newTokens
        }
    }
}

extension View {
    func subscribingDataRefs(_ store: DataRefStore, _ subscriptions: [DataRefSubscribing.Subscription]) -> some View {
        modifier(DataRefSubscribing(store: store, subscriptions: subscriptions))
    }
}
