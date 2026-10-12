import Foundation

/// A dataref value as reported by ExtPlane's `u{type} {ref} {value}` update lines.
enum ExtPlaneValue: Equatable {
    case int(Int)
    case float(Double)
    case double(Double)
    case intArray([Int])
    case floatArray([Double])
    case data(Data)
    case string(String)
}
