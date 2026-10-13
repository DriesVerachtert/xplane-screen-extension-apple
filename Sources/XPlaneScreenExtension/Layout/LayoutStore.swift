import Foundation
import Observation

/// Persists the layout `Page` as a JSON file on disk, and holds the
/// mutating operations the layout editor needs (add/remove/move/resize).
@MainActor
@Observable
final class LayoutStore {
    private(set) var page: Page

    @ObservationIgnored
    private let fileURL: URL

    static var defaultFileURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent("layout.json")
    }

    init(fileURL: URL = LayoutStore.defaultFileURL) {
        self.fileURL = fileURL
        page = Self.load(from: fileURL)
    }

    private static func load(from url: URL) -> Page {
        guard let data = try? Data(contentsOf: url),
              let page = try? JSONDecoder().decode(Page.self, from: data)
        else {
            return .empty
        }
        return page
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(page) else { return }
        let directory = fileURL.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    func addInstrument(_ kind: InstrumentKind) {
        let size = kind.defaultSize
        let cascade = CGFloat(page.items.count % 5) * 24
        let frame = CGRect(x: 20 + cascade, y: 20 + cascade, width: size.width, height: size.height)
        page.items.append(PlacedInstrument(kind: kind, frame: frame))
        save()
    }

    func removeInstrument(id: UUID) {
        page.items.removeAll { $0.id == id }
        save()
    }

    func updateFrame(id: UUID, frame: CGRect) {
        guard let index = page.items.firstIndex(where: { $0.id == id }) else { return }
        page.items[index].frame = frame
        save()
    }
}
