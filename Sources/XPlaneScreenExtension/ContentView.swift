import SwiftUI

/// The app's first and, for now, only screen: a plain statement of what this
/// app needs to be useful at all, plus the ExtPlane connection form.
struct ContentView: View {
    @State private var viewModel = ConnectionViewModel(transport: ExtPlaneConnection())

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section {
                    prerequisitesNotice
                }

                Section("Connection") {
                    TextField("Host or IP address", text: $viewModel.host)
                        .textFieldAutocapitalizationDisabled()
                        .disabled(isEditingDisabled)
                    TextField("Port", text: $viewModel.port)
                        .textFieldNumberPad()
                        .disabled(isEditingDisabled)
                }

                Section {
                    statusRow
                    actionButton
                    if viewModel.status == .connected {
                        NavigationLink("Instruments") {
                            InstrumentsView(store: viewModel.dataRefStore)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("XPlaneScreenExtension")
        }
    }

    private var isEditingDisabled: Bool {
        viewModel.status == .connecting || viewModel.status == .connected
    }

    private var prerequisitesNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("This app only works together with X-Plane", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            prerequisiteRow(
                icon: "airplane",
                text: "X-Plane must be running, with the ExtPlane plugin installed"
            )
            prerequisiteRow(
                icon: "wifi",
                text: "This device needs to be on the same Wi-Fi network (or otherwise " +
                    "reachable) as the computer running X-Plane"
            )
        }
        .padding(.vertical, 4)
    }

    private func prerequisiteRow(icon: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusRow: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(statusText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch viewModel.status {
        case .disconnected: .gray
        case .connecting: .orange
        case .connected: .green
        case .failed: .red
        }
    }

    private var statusText: String {
        switch viewModel.status {
        case .disconnected: "Not connected"
        case .connecting: "Connecting..."
        case .connected: "Connected"
        case let .failed(message): "Failed: \(message)"
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.status {
        case .connected, .connecting:
            Button("Disconnect", role: .destructive) {
                Task { await viewModel.disconnect() }
            }
        case .disconnected, .failed:
            Button("Connect") {
                Task { await viewModel.connect() }
            }
            .disabled(!viewModel.canConnect)
        }
    }
}

private extension View {
    @ViewBuilder
    func textFieldAutocapitalizationDisabled() -> some View {
        #if os(iOS)
            textInputAutocapitalization(.never).autocorrectionDisabled()
        #else
            autocorrectionDisabled()
        #endif
    }

    @ViewBuilder
    func textFieldNumberPad() -> some View {
        #if os(iOS)
            keyboardType(.numberPad)
        #else
            self
        #endif
    }
}

#Preview {
    ContentView()
}
