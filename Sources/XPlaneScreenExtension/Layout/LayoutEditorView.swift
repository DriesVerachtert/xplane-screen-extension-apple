import SwiftUI

/// A freeform canvas of placed instruments, with an "edit mode" toggle that
/// reveals drag-to-move, a resize handle, and a remove button on each item --
/// modeled on ExtPlane-Panel's edit-mode interaction. Pages are switched via
/// a tab strip (not swipe, which would fight the canvas's own pan/drag
/// gestures) and persist via `LayoutStore` after every change.
struct LayoutEditorView: View {
    static let canvasSize = CGSize(width: 1600, height: 1200)

    let dataRefStore: DataRefStore
    @State private var layoutStore = LayoutStore()
    @State private var isEditing = false
    @State private var renamingPageID: UUID?
    @State private var renameText = ""

    var body: some View {
        VStack(spacing: 0) {
            pageSwitcher
            Divider()
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    Color.clear
                    ForEach(layoutStore.selectedPage?.items ?? []) { item in
                        PlacedInstrumentView(
                            item: item,
                            dataRefStore: dataRefStore,
                            isEditing: isEditing,
                            onFrameChanged: { layoutStore.updateFrame(id: item.id, frame: $0) },
                            onRemove: { layoutStore.removeInstrument(id: item.id) }
                        )
                    }
                }
                .frame(width: Self.canvasSize.width, height: Self.canvasSize.height, alignment: .topLeading)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                if isEditing {
                    Menu {
                        ForEach(InstrumentKind.allCases) { kind in
                            Button(kind.displayName) { layoutStore.addInstrument(kind) }
                        }
                    } label: {
                        Label("Add Instrument", systemImage: "plus")
                    }
                }
                Button(isEditing ? "Done" : "Edit") { isEditing.toggle() }
            }
        }
        .navigationTitle(layoutStore.selectedPage?.name ?? "Layout")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
            .alert("Rename Page", isPresented: renamingPageBinding) {
                TextField("Page name", text: $renameText)
                Button("Save") {
                    if let id = renamingPageID {
                        layoutStore.renamePage(id: id, name: renameText)
                    }
                    renamingPageID = nil
                }
                Button("Cancel", role: .cancel) { renamingPageID = nil }
            }
    }

    private var renamingPageBinding: Binding<Bool> {
        Binding(get: { renamingPageID != nil }, set: {
            if !$0 {
                renamingPageID = nil
            }
        })
    }

    private var pageSwitcher: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(layoutStore.document.pages) { page in
                    pageChip(page)
                }
                if isEditing {
                    Button {
                        layoutStore.addPage(name: "Page \(layoutStore.document.pages.count + 1)")
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func pageChip(_ page: Page) -> some View {
        let isSelected = page.id == layoutStore.document.selectedPageID
        return HStack(spacing: 6) {
            Button(page.name) { layoutStore.selectPage(id: page.id) }
                .buttonStyle(.plain)
            if isEditing {
                Button {
                    renamingPageID = page.id
                    renameText = page.name
                } label: {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.plain)
                if layoutStore.document.pages.count > 1 {
                    Button {
                        layoutStore.removePage(id: page.id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor : Color.gray.opacity(0.2), in: Capsule())
        .foregroundStyle(isSelected ? Color.white : Color.primary)
    }
}

private struct PlacedInstrumentView: View {
    let item: PlacedInstrument
    let dataRefStore: DataRefStore
    let isEditing: Bool
    let onFrameChanged: (CGRect) -> Void
    let onRemove: () -> Void

    @State private var liveFrame: CGRect?

    private var displayedFrame: CGRect {
        liveFrame ?? item.frame
    }

    var body: some View {
        item.kind.view(store: dataRefStore)
            .frame(width: displayedFrame.width, height: displayedFrame.height)
            .overlay(alignment: .topTrailing) {
                if isEditing {
                    removeButton
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isEditing {
                    resizeHandle
                }
            }
            .position(x: displayedFrame.midX, y: displayedFrame.midY)
            .gesture(isEditing ? moveGesture : nil)
    }

    private var removeButton: some View {
        Button(action: onRemove) {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, .red)
        }
        .buttonStyle(.plain)
        .offset(x: 8, y: -8)
    }

    private var resizeHandle: some View {
        Image(systemName: "arrow.down.right.and.arrow.up.left.circle.fill")
            .font(.title3)
            .foregroundStyle(.white, .blue)
            .offset(x: 8, y: 8)
            .gesture(resizeGesture)
    }

    private var moveGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                var frame = item.frame
                frame.origin.x += value.translation.width
                frame.origin.y += value.translation.height
                liveFrame = frame
            }
            .onEnded { _ in
                if let liveFrame {
                    onFrameChanged(liveFrame)
                }
                liveFrame = nil
            }
    }

    private var resizeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                var frame = item.frame
                frame.size.width = max(80, item.frame.width + value.translation.width)
                frame.size.height = max(80, item.frame.height + value.translation.height)
                liveFrame = frame
            }
            .onEnded { _ in
                if let liveFrame {
                    onFrameChanged(liveFrame)
                }
                liveFrame = nil
            }
    }
}
