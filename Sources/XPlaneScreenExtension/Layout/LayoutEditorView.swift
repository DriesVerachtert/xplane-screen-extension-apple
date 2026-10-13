import SwiftUI

/// A freeform canvas of placed instruments, with an "edit mode" toggle that
/// reveals drag-to-move, a resize handle, and a remove button on each item --
/// modeled on ExtPlane-Panel's edit-mode interaction. The page persists via
/// `LayoutStore` after every change.
struct LayoutEditorView: View {
    static let canvasSize = CGSize(width: 1600, height: 1200)

    let dataRefStore: DataRefStore
    @State private var layoutStore = LayoutStore()
    @State private var isEditing = false

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                Color.clear
                ForEach(layoutStore.page.items) { item in
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
        .navigationTitle("Layout")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
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
