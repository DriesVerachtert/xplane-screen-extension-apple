import Foundation

/// A line received from ExtPlane, as defined in the README's "Protocol Output"
/// section, parsed into a typed event.
enum ExtPlaneEvent: Equatable, Sendable {
    case connected(protocolVersion: Int)
    case serverVersion(Int)
    case clientID(String)
    case warning(String)
    case update(ref: String, value: ExtPlaneValue)
    /// A line that didn't match any known format, kept rather than dropped,
    /// so callers can log/surface unexpected server behavior instead of it
    /// silently vanishing.
    case unrecognized(String)

    static func parse(line: String) -> ExtPlaneEvent {
        guard let spaceIndex = line.firstIndex(of: " ") else {
            return .unrecognized(line)
        }
        let tag = String(line[line.startIndex ..< spaceIndex])
        let rest = String(line[line.index(after: spaceIndex)...])

        switch tag {
        case "EXTPLANE":
            guard let version = Int(rest) else { return .unrecognized(line) }
            return .connected(protocolVersion: version)
        case "EXTPLANE-VERSION":
            guard let version = Int(rest) else { return .unrecognized(line) }
            return .serverVersion(version)
        case "CLIENT-ID":
            return .clientID(rest)
        case "EXTPLANE-WARNING":
            return .warning(rest)
        default:
            if tag.hasPrefix("u"), tag.count > 1 {
                return parseUpdate(typeCode: String(tag.dropFirst()), rest: rest, line: line)
            }
            return .unrecognized(line)
        }
    }

    private static func parseUpdate(typeCode: String, rest: String, line: String) -> ExtPlaneEvent {
        guard let spaceIndex = rest.firstIndex(of: " ") else {
            return .unrecognized(line)
        }
        let ref = String(rest[rest.startIndex ..< spaceIndex])
        let valueString = String(rest[rest.index(after: spaceIndex)...])

        guard let value = parseValue(typeCode: typeCode, valueString: valueString) else {
            return .unrecognized(line)
        }
        return .update(ref: ref, value: value)
    }

    private static func parseValue(typeCode: String, valueString: String) -> ExtPlaneValue? {
        switch typeCode {
        case "i":
            Int(valueString).map(ExtPlaneValue.int)
        case "f":
            Double(valueString).map(ExtPlaneValue.float)
        case "d":
            Double(valueString).map(ExtPlaneValue.double)
        case "ia":
            parseArray(valueString) { Int($0) }.map(ExtPlaneValue.intArray)
        case "fa":
            parseArray(valueString) { Double($0) }.map(ExtPlaneValue.floatArray)
        case "b":
            parseDataValue(valueString)
        default:
            nil
        }
    }

    private static func parseDataValue(_ valueString: String) -> ExtPlaneValue? {
        if valueString.count >= 2, valueString.hasPrefix("\""), valueString.hasSuffix("\"") {
            return .string(String(valueString.dropFirst().dropLast()))
        }
        guard let data = Data(base64Encoded: valueString) else { return nil }
        return .data(data)
    }

    /// Parses a `[v1,v2,v3]` list. Any unparsable element fails the whole array
    /// (empty elements like `[,1]` are a `set`-only partial-write syntax, not
    /// expected in values the server reports back).
    private static func parseArray<T>(_ bracketed: String, element: (Substring) -> T?) -> [T]? {
        guard bracketed.count >= 2, bracketed.hasPrefix("["), bracketed.hasSuffix("]") else { return nil }
        let inner = bracketed.dropFirst().dropLast()
        if inner.isEmpty {
            return []
        }
        var result: [T] = []
        for part in inner.split(separator: ",", omittingEmptySubsequences: false) {
            guard let value = element(part) else { return nil }
            result.append(value)
        }
        return result
    }
}
