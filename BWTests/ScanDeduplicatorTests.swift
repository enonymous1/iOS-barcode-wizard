import Foundation
import Testing

@testable import BW

@Suite("Scan deduplication")
struct ScanDeduplicatorTests {
    @Test("First scan of a code is accepted")
    func firstScanAccepted() {
        var gate = ScanDeduplicator()
        #expect(gate.shouldAccept("012345678905", at: Date()))
    }

    @Test("Repeats of the same code inside the window are suppressed")
    func repeatsSuppressed() {
        var gate = ScanDeduplicator(window: 2)
        let now = Date()
        #expect(gate.shouldAccept("012345678905", at: now))
        #expect(!gate.shouldAccept("012345678905", at: now.addingTimeInterval(1)))
        #expect(!gate.shouldAccept("012345678905", at: now.addingTimeInterval(1.9)))
    }

    @Test("A different code is always accepted immediately")
    func differentCodeAccepted() {
        var gate = ScanDeduplicator()
        let now = Date()
        #expect(gate.shouldAccept("012345678905", at: now))
        #expect(gate.shouldAccept("999999999999", at: now))
    }

    @Test("The same code is accepted again after the window passes")
    func codeAcceptedAfterWindow() {
        var gate = ScanDeduplicator(window: 2)
        let now = Date()
        #expect(gate.shouldAccept("012345678905", at: now))
        #expect(gate.shouldAccept("012345678905", at: now.addingTimeInterval(2.1)))
    }
}
