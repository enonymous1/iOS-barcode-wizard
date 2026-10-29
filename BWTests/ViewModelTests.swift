import Foundation
import Testing

@testable import BW

/// Fake lookup that records how many times it was called, so the
/// tests can prove the scanner deduplicates instead of firing one
/// lookup per camera frame, as v1 did.
final class FakeLookupService: ProductLookupService, @unchecked Sendable {
    var result: Result<ProductItem, LookupError>
    private(set) var callCount = 0

    init(result: Result<ProductItem, LookupError>) {
        self.result = result
    }

    func lookup(barcode: String) async throws -> ProductItem {
        callCount += 1
        switch result {
        case .success(let item):
            return item
        case .failure(let error):
            throw error
        }
    }
}

@Suite("Scanner and list view models")
@MainActor
struct ViewModelTests {
    @Test("A found barcode becomes the scanned item")
    func foundBarcodeBecomesScannedItem() async {
        let found = ProductItem(
            code: "012345678905",
            company: "Example Co",
            description: "Example Widget"
        )
        let lookup = FakeLookupService(result: .success(found))
        let viewModel = ScannerViewModel(lookup: lookup)
        await viewModel.didScan("012345678905")
        #expect(viewModel.scannedItem == found)
        #expect(viewModel.lookupMessage == nil)
        #expect(lookup.callCount == 1)
    }

    @Test("Scanning the same code twice runs one lookup")
    func duplicateScanRunsOneLookup() async {
        let found = ProductItem(code: "012345678905")
        let lookup = FakeLookupService(result: .success(found))
        let viewModel = ScannerViewModel(lookup: lookup)
        await viewModel.didScan("012345678905")
        await viewModel.didScan("012345678905")
        #expect(lookup.callCount == 1)
    }

    @Test("A not-found barcode becomes an editable placeholder")
    func notFoundBecomesPlaceholder() async {
        let lookup = FakeLookupService(result: .failure(.httpStatus(404)))
        let viewModel = ScannerViewModel(lookup: lookup)
        await viewModel.didScan("012345678905")
        #expect(viewModel.scannedItem?.code == "012345678905")
        #expect(viewModel.scannedItem?.isPlaceholder == true)
        #expect(viewModel.lookupMessage != nil)
    }

    @Test("A network failure is a message, not a blank item")
    func networkFailureIsMessageOnly() async {
        let lookup = FakeLookupService(result: .failure(.network))
        let viewModel = ScannerViewModel(lookup: lookup)
        await viewModel.didScan("012345678905")
        #expect(viewModel.scannedItem == nil)
        #expect(viewModel.lookupMessage != nil)
    }

    @Test("List loads, searches, saves, and deletes")
    func listLifecycle() async {
        let store = InMemoryItemStore(items: [
            ProductItem(
                code: "111",
                company: "Alpha Co",
                description: "Alpha Widget"
            ),
            ProductItem(
                code: "222",
                company: "Beta Co",
                description: "Beta Widget"
            )
        ])
        let viewModel = ItemListViewModel(
            store: store,
            userID: "test-user"
        )
        await viewModel.load()
        #expect(viewModel.items.count == 2)

        viewModel.searchText = "beta"
        #expect(viewModel.filteredItems.count == 1)
        #expect(viewModel.filteredItems[0].code == "222")
        viewModel.searchText = ""

        await viewModel.save(
            ProductItem(code: "333", description: "Gamma Widget")
        )
        #expect(viewModel.items.count == 3)

        await viewModel.delete(ProductItem(code: "111"))
        #expect(viewModel.items.count == 2)
        #expect(viewModel.items.allSatisfy { $0.code != "111" })
    }

    @Test("Auth form reports one problem at a time")
    func authFormValidation() {
        let viewModel = AuthViewModel(service: FakeAuthService())
        viewModel.email = "not-an-email"
        viewModel.password = "long-enough"
        #expect(viewModel.formProblem != nil)

        viewModel.email = "user@example.com"
        viewModel.password = "short"
        #expect(viewModel.formProblem != nil)

        viewModel.password = "long-enough"
        #expect(viewModel.formProblem == nil)
    }
}
