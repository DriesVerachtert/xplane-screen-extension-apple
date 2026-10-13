import Foundation
import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("LayoutStore")
@MainActor
struct LayoutStoreTests {
    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("LayoutStoreTests-\(UUID().uuidString)")
            .appendingPathComponent("layout.json")
    }

    @Test("starts empty when no file exists yet")
    func startsEmptyWithNoFile() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        #expect(store.page == .empty)
    }

    @Test("starts empty when the file contains corrupt JSON")
    func startsEmptyWithCorruptFile() throws {
        let url = temporaryFileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)

        let store = LayoutStore(fileURL: url)
        #expect(store.page == .empty)
    }

    @Test("addInstrument appends an item with a positive-size frame")
    func addInstrumentAppends() {
        let store = LayoutStore(fileURL: temporaryFileURL())

        store.addInstrument(.altimeter)

        #expect(store.page.items.count == 1)
        #expect(store.page.items[0].kind == .altimeter)
        #expect(store.page.items[0].frame.width > 0)
        #expect(store.page.items[0].frame.height > 0)
    }

    @Test("removeInstrument removes only the matching item")
    func removeInstrumentRemovesOnlyMatch() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        store.addInstrument(.altimeter)
        store.addInstrument(.airspeedIndicator)
        let keptID = store.page.items[1].id

        store.removeInstrument(id: store.page.items[0].id)

        #expect(store.page.items.map(\.id) == [keptID])
    }

    @Test("updateFrame changes only the matching item's frame")
    func updateFrameChangesMatch() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        store.addInstrument(.altimeter)
        let id = store.page.items[0].id
        let newFrame = CGRect(x: 10, y: 20, width: 300, height: 150)

        store.updateFrame(id: id, frame: newFrame)

        #expect(store.page.items[0].frame == newFrame)
    }

    @Test("updateFrame for an unknown id is a no-op")
    func updateFrameUnknownIDIsNoOp() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        store.addInstrument(.altimeter)
        let original = store.page

        store.updateFrame(id: UUID(), frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        #expect(store.page == original)
    }

    @Test("changes persist to disk and are reloaded by a new store over the same file")
    func persistsAndReloads() {
        let url = temporaryFileURL()
        let store = LayoutStore(fileURL: url)
        store.addInstrument(.attitudeIndicator)
        store.updateFrame(id: store.page.items[0].id, frame: CGRect(x: 5, y: 6, width: 220, height: 220))

        let reloaded = LayoutStore(fileURL: url)

        #expect(reloaded.page == store.page)
    }
}
