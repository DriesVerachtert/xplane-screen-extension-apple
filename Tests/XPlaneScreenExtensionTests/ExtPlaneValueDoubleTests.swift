import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("ExtPlaneValue.doubleValue")
struct ExtPlaneValueDoubleTests {
    @Test("scalar numeric cases convert to Double")
    func scalarCases() {
        #expect(ExtPlaneValue.int(42).doubleValue == 42)
        #expect(ExtPlaneValue.float(1.5).doubleValue == 1.5)
        #expect(ExtPlaneValue.double(-3.25).doubleValue == -3.25)
    }

    @Test("non-scalar cases have no Double representation")
    func nonScalarCases() {
        #expect(ExtPlaneValue.intArray([1, 2]).doubleValue == nil)
        #expect(ExtPlaneValue.floatArray([1.0]).doubleValue == nil)
        #expect(ExtPlaneValue.string("hello").doubleValue == nil)
    }
}
