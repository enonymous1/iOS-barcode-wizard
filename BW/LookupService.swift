import Foundation

/// What can go wrong in a product lookup. v1 swallowed all of these
/// into `print` statements and then presented a blank item as if
/// the lookup had succeeded. Callers now get a typed error and can
/// tell the user "not found, enter it yourself" instead.
enum LookupError: Error, Equatable {
    case invalidBarcode
    case httpStatus(Int)
    case noData
    case decoding
    case network
}

/// Looks a barcode up in a product database. Behind a protocol so
/// the scanner view model and the tests can substitute a fake
/// without touching the network.
protocol ProductLookupService: Sendable {
    func lookup(barcode: String) async throws -> ProductItem
}

/// Barcode Monster, the provider v1 used, reached over plain
/// URLSession with a 30-second timeout and an HTTP-status check.
/// A non-200 response is an error, not a blank item: the scanner
/// view model turns a 404/decoding failure into a placeholder item
/// the user can complete by hand, and surfaces any other failure
/// as an error message.
struct BarcodeMonsterService: ProductLookupService {
    private let session: URLSession
    private let baseURL: URL

    init(
        session: URLSession = .shared,
        baseURL: URL = URL(string: "https://barcode.monster/api/")!
    ) {
        self.session = session
        self.baseURL = baseURL
    }

    func lookup(barcode: String) async throws -> ProductItem {
        let code = Barcode.normalized(barcode)
        guard Barcode.isUsable(code) else {
            throw LookupError.invalidBarcode
        }
        guard let url = URL(string: code, relativeTo: baseURL) else {
            throw LookupError.invalidBarcode
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 30
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw LookupError.network
        }
        guard let http = response as? HTTPURLResponse else {
            throw LookupError.noData
        }
        guard http.statusCode == 200 else {
            throw LookupError.httpStatus(http.statusCode)
        }
        do {
            return try ProductItem.decode(from: data)
        } catch {
            throw LookupError.decoding
        }
    }
}
