import Foundation
import Observation

/// Persists the `LayoutDocument` (every page, and which is selected) as a
/// JSON file on disk, and holds the mutating operations the layout editor
/// needs: switch/add/remove/rename pages, and add/remove/move/resize
/// instruments on whichever page is currently selected.
@MainActor
@Observable
final class LayoutStore {
    private(set) var document: LayoutDocument

    @ObservationIgnored
    private let fileURL: URL

    static var defaultFileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("layout.json")
    }

    init(fileURL: URL = LayoutStore.defaultFileURL) {
        self.fileURL = fileURL
        document = Self.load(from: fileURL)
    }

    private static func load(from url: URL) -> LayoutDocument {
        guard let data = try? Data(contentsOf: url),
              let document = try? JSONDecoder().decode(LayoutDocument.self, from: data)
        else {
            return .empty
        }
        return document
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(document) else { return }
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    var selectedPage: Page? {
        document.pages.first { $0.id == document.selectedPageID }
    }

    private var selectedPageIndex: Int? {
        document.pages.firstIndex { $0.id == document.selectedPageID }
    }

    func selectPage(id: UUID) {
        guard document.pages.contains(where: { $0.id == id }) else { return }
        document.selectedPageID = id
        save()
    }

    @discardableResult
    func addPage(name: String) -> UUID {
        let page = Page(name: name)
        document.pages.append(page)
        document.selectedPageID = page.id
        save()
        return page.id
    }

    /// No-op if `id` is the last remaining page -- there must always be at
    /// least one page to show.
    func removePage(id: UUID) {
        guard document.pages.count > 1 else { return }
        document.pages.removeAll { $0.id == id }
        if document.selectedPageID == id {
            document.selectedPageID = document.pages[0].id
        }
        save()
    }

    func renamePage(id: UUID, name: String) {
        guard let index = document.pages.firstIndex(where: { $0.id == id }) else { return }
        document.pages[index].name = name
        save()
    }

    func addInstrument(_ kind: InstrumentKind) {
        guard let pageIndex = selectedPageIndex else { return }
        let size = kind.defaultSize
        let cascade = CGFloat(document.pages[pageIndex].items.count % 5) * 24
        let frame = CGRect(x: 20 + cascade, y: 20 + cascade, width: size.width, height: size.height)
        document.pages[pageIndex].items.append(PlacedInstrument(kind: kind, frame: frame))
        save()
    }

    func removeInstrument(id: UUID) {
        guard let pageIndex = selectedPageIndex else { return }
        document.pages[pageIndex].items.removeAll { $0.id == id }
        save()
    }

    func updateFrame(id: UUID, frame: CGRect) {
        guard let pageIndex = selectedPageIndex,
              let itemIndex = document.pages[pageIndex].items.firstIndex(where: { $0.id == id })
        else {
            return
        }
        document.pages[pageIndex].items[itemIndex].frame = frame
        save()
    }
}
