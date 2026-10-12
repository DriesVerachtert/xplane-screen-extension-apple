import Foundation
import Testing
@testable import XPlaneScreenExtension_macOS

@Suite("ExtPlaneLineFramer buffering")
struct ExtPlaneLineFramerTests {
    @Test("a single chunk with one complete line")
    func singleCompleteLine() {
        var framer = ExtPlaneLineFramer()
        let lines = framer.append(Data("EXTPLANE 1\n".utf8))
        #expect(lines == ["EXTPLANE 1"])
    }

    @Test("a single chunk with multiple lines")
    func multipleLinesInOneChunk() {
        var framer = ExtPlaneLineFramer()
        let lines = framer.append(Data("EXTPLANE 1\nEXTPLANE-VERSION 1003\n".utf8))
        #expect(lines == ["EXTPLANE 1", "EXTPLANE-VERSION 1003"])
    }

    @Test("a line split across two chunks produces no line until it's complete")
    func lineSplitAcrossChunks() {
        var framer = ExtPlaneLineFramer()
        let firstChunk = framer.append(Data("EXTPLANE".utf8))
        #expect(firstChunk == [])
        let secondChunk = framer.append(Data(" 1\n".utf8))
        #expect(secondChunk == ["EXTPLANE 1"])
    }

    @Test("a trailing partial line stays buffered until the rest arrives, even across several following complete lines")
    func trailingPartialLineAcrossMultipleAppends() {
        var framer = ExtPlaneLineFramer()
        #expect(framer.append(Data("ui a/b 1\nui c/d ".utf8)) == ["ui a/b 1"])
        #expect(framer.append(Data("2\nui e/f 3\nui g/h ".utf8)) == ["ui c/d 2", "ui e/f 3"])
        #expect(framer.append(Data("4\n".utf8)) == ["ui g/h 4"])
    }

    @Test("a trailing carriage return before the newline is stripped")
    func carriageReturnStripped() {
        var framer = ExtPlaneLineFramer()
        let lines = framer.append(Data("EXTPLANE 1\r\n".utf8))
        #expect(lines == ["EXTPLANE 1"])
    }

    @Test("an empty line between two newlines comes through as an empty string")
    func emptyLine() {
        var framer = ExtPlaneLineFramer()
        let lines = framer.append(Data("\n\nui a/b 1\n".utf8))
        #expect(lines == ["", "", "ui a/b 1"])
    }

    @Test("no data at all produces no lines")
    func noData() {
        var framer = ExtPlaneLineFramer()
        #expect(framer.append(Data()) == [])
    }
}
