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

    @Test("starts with a single default page when no file exists yet")
    func startsWithDefaultPage() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        #expect(store.document.pages.count == 1)
        #expect(store.document.pages[0].name == "Page 1")
        #expect(store.selectedPage?.id == store.document.pages[0].id)
    }

    @Test("starts with a default page when the file contains corrupt JSON")
    func startsWithDefaultPageOnCorruptFile() throws {
        let url = temporaryFileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)

        let store = LayoutStore(fileURL: url)
        #expect(store.document.pages.count == 1)
    }

    @Test("addInstrument appends to the selected page only")
    func addInstrumentAppendsToSelectedPage() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        let secondPageID = store.addPage(name: "Second")
        store.selectPage(id: store.document.pages[0].id)

        store.addInstrument(.altimeter)

        #expect(store.document.pages[0].items.count == 1)
        #expect(store.document.pages.first { $0.id == secondPageID }?.items.isEmpty == true)
    }

    @Test("removeInstrument and updateFrame only affect the selected page's items")
    func removeAndUpdateFrameScopedToSelectedPage() throws {
        let store = LayoutStore(fileURL: temporaryFileURL())
        store.addInstrument(.altimeter)
        let id = try #require(store.selectedPage?.items.first?.id)

        store.updateFrame(id: id, frame: CGRect(x: 1, y: 2, width: 3, height: 4))
        #expect(store.selectedPage?.items[0].frame == CGRect(x: 1, y: 2, width: 3, height: 4))

        store.removeInstrument(id: id)
        #expect(store.selectedPage?.items.isEmpty == true)
    }

    @Test("addPage appends a new page and selects it")
    func addPageAppendsAndSelects() {
        let store = LayoutStore(fileURL: temporaryFileURL())

        let newID = store.addPage(name: "Cruise")

        #expect(store.document.pages.count == 2)
        #expect(store.document.pages[1].id == newID)
        #expect(store.document.pages[1].name == "Cruise")
        #expect(store.document.selectedPageID == newID)
    }

    @Test("selectPage switches the selection, and ignores an unknown id")
    func selectPageSwitchesSelection() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        let firstID = store.document.pages[0].id
        let secondID = store.addPage(name: "Second")

        store.selectPage(id: firstID)
        #expect(store.document.selectedPageID == firstID)

        store.selectPage(id: UUID())
        #expect(store.document.selectedPageID == firstID)

        store.selectPage(id: secondID)
        #expect(store.document.selectedPageID == secondID)
    }

    @Test("removePage removes the page and falls back to the first remaining page if it was selected")
    func removePageFallsBackSelection() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        let firstID = store.document.pages[0].id
        let secondID = store.addPage(name: "Second")
        #expect(store.document.selectedPageID == secondID)

        store.removePage(id: secondID)

        #expect(store.document.pages.map(\.id) == [firstID])
        #expect(store.document.selectedPageID == firstID)
    }

    @Test("removePage is a no-op when it's the last remaining page")
    func removePageNoOpOnLastPage() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        let onlyID = store.document.pages[0].id

        store.removePage(id: onlyID)

        #expect(store.document.pages.map(\.id) == [onlyID])
    }

    @Test("renamePage renames only the matching page")
    func renamePageRenamesMatch() {
        let store = LayoutStore(fileURL: temporaryFileURL())
        let secondID = store.addPage(name: "Second")

        store.renamePage(id: secondID, name: "Renamed")

        #expect(store.document.pages[1].name == "Renamed")
        #expect(store.document.pages[0].name == "Page 1")
    }

    @Test("changes persist to disk and are reloaded by a new store over the same file")
    func persistsAndReloads() throws {
        let url = temporaryFileURL()
        let store = LayoutStore(fileURL: url)
        store.addPage(name: "Second")
        store.addInstrument(.attitudeIndicator)
        let id = try #require(store.selectedPage?.items.first?.id)
        store.updateFrame(id: id, frame: CGRect(x: 5, y: 6, width: 220, height: 220))

        let reloaded = LayoutStore(fileURL: url)

        #expect(reloaded.document == store.document)
    }
}
