import Foundation

/// Buffers raw bytes from the socket and extracts complete `\n`-terminated
/// lines, holding onto any trailing partial line until more data arrives.
/// ExtPlane terminates lines with a bare `\n`, but a trailing `\r` is
/// stripped defensively in case that ever changes.
struct ExtPlaneLineFramer {
    private var buffer = Data()
    private let newline: UInt8 = 0x0A
    private let carriageReturn: UInt8 = 0x0D

    mutating func append(_ data: Data) -> [String] {
        buffer.append(data)

        var lines: [String] = []
        while let newlineIndex = buffer.firstIndex(of: newline) {
            var lineData = buffer[buffer.startIndex ..< newlineIndex]
            buffer.removeSubrange(buffer.startIndex ... newlineIndex)
            if lineData.last == carriageReturn {
                lineData = lineData.dropLast()
            }
            if let line = String(data: lineData, encoding: .utf8) {
                lines.append(line)
            }
        }
        return lines
    }
}
