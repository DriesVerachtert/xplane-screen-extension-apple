import Foundation

/// A command the client can send to ExtPlane, as defined in the ExtPlane README's
/// "Protocol Input" section. `wireFormat` is the line to send, without the
/// trailing newline (`ExtPlaneConnection` appends it).
enum ExtPlaneCommand: Equatable {
    case subscribe(ref: String, modifiers: [String] = [], accuracy: Double? = nil)
    case unsubscribe(ref: String)
    case setScalar(ref: String, value: Double)
    /// `nil` entries are skipped, e.g. `set ... [,1]` to set only the second value.
    case setArray(ref: String, values: [Double?])
    case setString(ref: String, value: String)
    case get(ref: String)
    case key(Int)
    case buttonDown(Int)
    case buttonUp(Int)
    case commandOnce(String)
    case commandBegin(String)
    case commandEnd(String)
    case disconnect
    case setting(name: String, value: String)

    var wireFormat: String {
        switch self {
        case let .subscribe(ref, modifiers, accuracy):
            let modifierSuffix = modifiers.isEmpty ? "" : ":" + modifiers.joined(separator: ",")
            let accuracySuffix = accuracy.map { " \($0)" } ?? ""
            return "sub \(ref)\(modifierSuffix)\(accuracySuffix)"
        case let .unsubscribe(ref):
            return "unsub \(ref)"
        case let .setScalar(ref, value):
            return "set \(ref) \(value)"
        case let .setArray(ref, values):
            let valuesString = values.map { value in value.map { "\($0)" } ?? "" }.joined(separator: ",")
            return "set \(ref) [\(valuesString)]"
        case let .setString(ref, value):
            return "set \(ref) \"\(value)\""
        case let .get(ref):
            return "get \(ref)"
        case let .key(id):
            return "key \(id)"
        case let .buttonDown(id):
            return "but \(id)"
        case let .buttonUp(id):
            return "rel \(id)"
        case let .commandOnce(name):
            return "cmd once \(name)"
        case let .commandBegin(name):
            return "cmd begin \(name)"
        case let .commandEnd(name):
            return "cmd end \(name)"
        case .disconnect:
            return "disconnect"
        case let .setting(name, value):
            return "extplane-set \(name) \(value)"
        }
    }
}
