import Foundation
import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("Page Codable round-trip")
struct PageCodableTests {
    @Test("a page with several items survives an encode/decode round trip")
    func roundTrip() throws {
        let page = Page(items: [
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
        let data = try JSONEncoder().encode(Page.empty)
        let decoded = try JSONDecoder().decode(Page.self, from: data)
        #expect(decoded == Page.empty)
    }
}
