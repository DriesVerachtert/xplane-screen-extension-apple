import Foundation
import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("Page / LayoutDocument Codable round-trip")
struct PageCodableTests {
    @Test("a page with several items survives an encode/decode round trip")
    func pageRoundTrip() throws {
        let page = Page(name: "Cruise", items: [
            PlacedInstrument(kind: .altimeter, frame: CGRect(x: 0, y: 0, width: 200, height: 200)),
            PlacedInstrument(kind: .airspeedIndicator, frame: CGRect(x: 220, y: 0, width: 200, height: 200)),
            PlacedInstrument(kind: .attitudeIndicator, frame: CGRect(x: 440, y: 10, width: 180, height: 180))
        ])

        let data = try JSONEncoder().encode(page)
        let decoded = try JSONDecoder().decode(Page.self, from: data)

        #expect(decoded == page)
    }

    @Test("an empty page survives an encode/decode round trip")
    func emptyPageRoundTrip() throws {
        let page = Page(name: "Empty")
        let data = try JSONEncoder().encode(page)
        let decoded = try JSONDecoder().decode(Page.self, from: data)
        #expect(decoded == page)
    }

    @Test("a document with several pages survives an encode/decode round trip")
    func documentRoundTrip() throws {
        let item = PlacedInstrument(kind: .altimeter, frame: CGRect(x: 0, y: 0, width: 200, height: 200))
        let pageA = Page(name: "A", items: [item])
        let pageB = Page(name: "B")
        let document = LayoutDocument(pages: [pageA, pageB], selectedPageID: pageB.id)

        let data = try JSONEncoder().encode(document)
        let decoded = try JSONDecoder().decode(LayoutDocument.self, from: data)

        #expect(decoded == document)
    }

    @Test("the default empty document has exactly one page, selected")
    func emptyDocumentDefault() {
        let document = LayoutDocument.empty
        #expect(document.pages.count == 1)
        #expect(document.selectedPageID == document.pages[0].id)
    }
}
