import Foundation

extension ExtPlaneValue {
    /// The value as a `Double`, for the scalar numeric types (int/float/
    /// double) instruments care about. `nil` for arrays/data/string.
    var doubleValue: Double? {
        switch self {
        case let .int(value): Double(value)
        case let .float(value): value
        case let .double(value): value
        case .intArray, .floatArray, .data, .string: nil
        }
    }
}
