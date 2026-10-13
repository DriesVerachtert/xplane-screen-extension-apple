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

/// A single named, freeform arrangement of instruments. A `LayoutDocument`
/// holds several, switchable via the layout editor's page strip.
struct Page: Identifiable, Codable, Sendable, Equatable {
    let id: UUID
    var name: String
    var items: [PlacedInstrument]

    init(id: UUID = UUID(), name: String, items: [PlacedInstrument] = []) {
        self.id = id
        self.name = name
        self.items = items
    }
}

/// The whole persisted layout: every page, and which one is currently shown.
struct LayoutDocument: Codable, Sendable, Equatable {
    var pages: [Page]
    var selectedPageID: UUID

    static let empty: LayoutDocument = {
        let page = Page(name: "Page 1")
        return LayoutDocument(pages: [page], selectedPageID: page.id)
    }()
}
