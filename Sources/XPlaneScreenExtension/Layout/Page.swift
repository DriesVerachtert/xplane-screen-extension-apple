import Foundation

/// One instrument placed on a page: what it is, and where/how big it is.
struct PlacedInstrument: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var kind: InstrumentKind
    var frame: CGRect

    init(id: UUID = UUID(), kind: InstrumentKind, frame: CGRect) {
        self.id = id
        self.kind = kind
        self.frame = frame
    }
}

/// A freeform arrangement of instruments. Just one page for now (step 6);
/// multiple named/switchable pages come later (step 7).
struct Page: Codable, Sendable, Equatable {
    var items: [PlacedInstrument]

    static let empty = Page(items: [])
}
