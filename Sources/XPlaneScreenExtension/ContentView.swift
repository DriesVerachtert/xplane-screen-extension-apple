import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.system(size: 48))
            Text("X-Plane Screen Extension")
                .font(.title2)
            Text("Scaffolding placeholder — connection setup and instruments come next.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
