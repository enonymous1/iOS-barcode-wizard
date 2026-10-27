import Foundation

/// The camera fires a metadata callback for every video frame that
/// contains a barcode, so v1 called its lookup (and its segue) once
/// per frame. This gate lets a code through the first time, then
/// suppresses repeats of the same code for a short window, so one
/// physical scan produces exactly one lookup. A different code is
/// always accepted immediately.
///
/// Pure and clock-injectable so tests can drive it without waiting.
struct ScanDeduplicator {
    private var lastCode: String?
    private var lastAcceptedAt: Date?
    private let window: TimeInterval

    init(window: TimeInterval = 2) {
        self.window = window
    }

    mutating func shouldAccept(_ code: String, at now: Date = Date()) -> Bool {
        if let lastCode, let lastAcceptedAt,
           lastCode == code, now.timeIntervalSince(lastAcceptedAt) < window {
            return false
        }
        lastCode = code
        lastAcceptedAt = now
        return true
    }
}
