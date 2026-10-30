import Foundation
import Testing

@testable import BW

@Suite("Scan deduplication")
struct ScanDeduplicatorTests {
    @Test("First scan of a code is accepted")
    func firstScanAccepted() {
        var gate = ScanDeduplicator()
        // Hoisted out of #expect on purpose: the #expect macro
        // captures its expression with an immutable receiver, so
        // a mutating call like shouldAccept cannot live inside
        // it ("cannot use mutating member on immutable value").
        let accepted = gate.shouldAccept("012345678905", at: Date())
        #expect(accepted)
    }

    @Test("Repeats of the same code inside the window are suppressed")
    func repeatsSuppressed() {
        var gate = ScanDeduplicator(window: 2)
        let now = Date()
        let first = gate.shouldAccept("012345678905", at: now)
        #expect(first)
        let repeatAfter1s = gate.shouldAccept(
            "012345678905", at: now.addingTimeInterval(1))
        #expect(!repeatAfter1s)
        let repeatAfter1_9s = gate.shouldAccept(
            "012345678905", at: now.addingTimeInterval(1.9))
        #expect(!repeatAfter1_9s)
    }

    @Test("A different code is always accepted immediately")
    func differentCodeAccepted() {
        var gate = ScanDeduplicator()
        let now = Date()
        let first = gate.shouldAccept("012345678905", at: now)
        #expect(first)
        let different = gate.shouldAccept("999999999999", at: now)
        #expect(different)
    }

    @Test("The same code is accepted again after the window passes")
    func codeAcceptedAfterWindow() {
        var gate = ScanDeduplicator(window: 2)
        let now = Date()
        let first = gate.shouldAccept("012345678905", at: now)
        #expect(first)
        let afterWindow = gate.shouldAccept(
            "012345678905", at: now.addingTimeInterval(2.1))
        #expect(afterWindow)
    }
}
