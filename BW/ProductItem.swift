import Foundation

/// One scanned product. This is the v1 `upcData` struct, renamed and
/// made tolerant: every field except `code` is optional in the wire
/// format, and a record missing any of them still decodes instead of
/// failing the whole lookup, which is what v1's `try?` plus blank
/// fallback was papering over.
///
/// The wire keys stay snake_case (`img_url`) so the Barcode Monster
/// payload decodes unchanged. Swift-side code uses `imageURL`.
/// `id` is the barcode itself, which is also the Firestore document
/// ID in `FirebaseItemStore`, so an item's identity is stable
/// across the list, the detail screen, and the cloud store.
struct ProductItem: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { code }

    var code: String
    var company: String
    var description: String
    var imageURL: String?
    var size: String

    init(
        code: String,
        company: String = "",
        description: String = "",
        imageURL: String? = nil,
        size: String = ""
    ) {
        self.code = code
        self.company = company
        self.description = description
        self.imageURL = imageURL
        self.size = size
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decode(String.self, forKey: .code)
        company = try container.decodeIfPresent(String.self, forKey: .company) ?? ""
        description =
            try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        size = try container.decodeIfPresent(String.self, forKey: .size) ?? ""
    }

    /// Explicit encode, so Firestore's `setData(from:)` encodes
    /// exactly the wire fields above and never depends on which
    /// half of `Codable` the compiler chose to synthesize
    /// alongside the custom decoder.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(code, forKey: .code)
        try container.encode(company, forKey: .company)
        try container.encode(description, forKey: .description)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encode(size, forKey: .size)
    }

    private enum CodingKeys: String, CodingKey {
        case code
        case company
        case description
        case imageURL = "img_url"
        case size
    }

    /// A record created because a lookup found nothing: only the
    /// barcode is known, and the detail screen opens in edit mode
    /// so the user can fill the rest in by hand.
    var isPlaceholder: Bool {
        company.isEmpty && description.isEmpty && size.isEmpty
            && (imageURL ?? "").isEmpty
    }

    /// What the list row shows first: the description when there is
    /// one, otherwise the barcode, so a row is never blank.
    var displayTitle: String {
        description.isEmpty ? code : description
    }

    /// The Barcode Monster payload, decoded the same way the app
    /// decodes it. Kept as a pure function so tests can exercise
    /// decoding without a network call.
    static func decode(from data: Data) throws -> ProductItem {
        try JSONDecoder().decode(ProductItem.self, from: data)
    }
}
