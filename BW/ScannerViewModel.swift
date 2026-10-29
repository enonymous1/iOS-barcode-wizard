import Foundation
import Observation

/// Scanner state. The camera view reports raw codes; this view
/// model deduplicates them, looks the product up, and publishes
/// exactly one result: a found item, a placeholder item when the
/// lookup came up empty (so the user can enter details by hand),
/// or an error message when the lookup itself failed. v1 did all
/// three of those things in three near-identical functions and
/// presented a blank item on failure.
@MainActor
@Observable
final class ScannerViewModel {
    /// The item to show in the detail screen, once a lookup
    /// resolves. Nil while scanning or while a lookup is running.
    var scannedItem: ProductItem?
    var isLookingUp = false
    var lookupMessage: String?
    var cameraDenied = false

    private let lookup: any ProductLookupService
    private var deduplicator = ScanDeduplicator()

    init(lookup: any ProductLookupService) {
        self.lookup = lookup
    }

    /// Called for every code the camera reports. Repeats of the
    /// same code inside the deduplication window are ignored, so
    /// one physical scan produces one lookup.
    func didScan(_ rawCode: String) async {
        let code = Barcode.normalized(rawCode)
        guard Barcode.isUsable(code), deduplicator.shouldAccept(code) else {
            return
        }
        isLookingUp = true
        lookupMessage = nil
        defer { isLookingUp = false }
        do {
            scannedItem = try await lookup.lookup(barcode: code)
        } catch let error as LookupError {
            switch error {
            case .httpStatus, .decoding, .noData:
                // The provider has no record for this barcode.
                // Hand the user a placeholder to complete by hand
                // instead of a dead end.
                lookupMessage =
                    "No product found for this barcode. "
                    + "Enter the details yourself."
                scannedItem = ProductItem(code: code)
            case .invalidBarcode:
                lookupMessage = "That barcode could not be read. Try again."
            case .network:
                lookupMessage =
                    "Could not reach the product database. "
                    + "Check your connection and try again."
            }
        } catch {
            lookupMessage = error.localizedDescription
        }
    }

    func reset() {
        scannedItem = nil
        lookupMessage = nil
    }
}
