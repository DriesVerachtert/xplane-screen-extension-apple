import SwiftUI

/// A classic artificial horizon: a sky/ground card that translates with
/// pitch and rotates with roll, under a fixed aircraft reference symbol.
/// Pure rendering -- no data-fetching, so it's trivially previewable with
/// static angles. Sign conventions (card rotates by `-roll`) match a real
/// attitude indicator: on a right roll the card appears to counter-rotate
/// relative to the fixed aircraft symbol.
struct AttitudeHorizonView: View {
    let pitchDegrees: Double
    let rollDegrees: Double

    /// Pixels of card movement per degree of pitch, at a 220pt reference size.
    private let referenceSize: Double = 220
    private let pixelsPerDegreeAtReferenceSize: Double = 6

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            ZStack {
                horizonCard(size: size)
                pitchLadder(size: size)
                aircraftSymbol(size: size)
                Circle().stroke(.black, lineWidth: size * 0.02)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func horizonCard(size: Double) -> some View {
        let cardSize = size * 2.4
        return ZStack {
            Color(red: 0.25, green: 0.55, blue: 0.9) // sky
            Color(red: 0.45, green: 0.3, blue: 0.15) // ground
                .frame(height: cardSize)
                .offset(y: cardSize / 2)
        }
        .frame(width: cardSize, height: cardSize)
        .rotationEffect(.degrees(-rollDegrees))
        .offset(y: clampedPitchOffset(size: size))
    }

    private func pitchLadder(size: Double) -> some View {
        ZStack {
            ForEach([-20, -10, 10, 20], id: \.self) { degrees in
                Rectangle()
                    .fill(.white)
                    .frame(width: size * 0.3, height: size * 0.012)
                    .offset(y: -pixels(forDegrees: Double(degrees), size: size))
            }
        }
        .frame(width: size * 2.4, height: size * 2.4)
        .rotationEffect(.degrees(-rollDegrees))
        .offset(y: clampedPitchOffset(size: size))
    }

    private func aircraftSymbol(size: Double) -> some View {
        HStack(spacing: size * 0.08) {
            Capsule().fill(.yellow).frame(width: size * 0.3, height: size * 0.03)
            Circle().fill(.yellow).frame(width: size * 0.04, height: size * 0.04)
            Capsule().fill(.yellow).frame(width: size * 0.3, height: size * 0.03)
        }
    }

    private func pixels(forDegrees degrees: Double, size: Double) -> Double {
        degrees * pixelsPerDegreeAtReferenceSize * (size / referenceSize)
    }

    private func clampedPitchOffset(size: Double) -> Double {
        let maxOffset = size * 0.5
        let offset = pixels(forDegrees: pitchDegrees, size: size)
        return min(max(offset, -maxOffset), maxOffset)
    }
}

#Preview("Level") {
    AttitudeHorizonView(pitchDegrees: 0, rollDegrees: 0)
        .frame(width: 220, height: 220)
        .padding()
}

#Preview("Climbing right turn") {
    AttitudeHorizonView(pitchDegrees: 12, rollDegrees: 25)
        .frame(width: 220, height: 220)
        .padding()
}

#Preview("Diving left turn") {
    AttitudeHorizonView(pitchDegrees: -15, rollDegrees: -35)
        .frame(width: 220, height: 220)
        .padding()
}
