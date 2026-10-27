import Foundation
import Testing

@testable import BW

@Suite("Product item decoding")
struct ProductItemTests {
    @Test("Decodes the legacy Barcode Monster snake_case payload")
    func decodesLegacyPayload() throws {
        let json = """
        {
          "code": "012345678905",
          "company": "Example Co",
          "description": "Example Widget",
          "img_url": "https://example.com/widget.png",
          "size": "12 oz"
        }
        """
        let item = try ProductItem.decode(from: Data(json.utf8))
        #expect(item.code == "012345678905")
        #expect(item.company == "Example Co")
        #expect(item.description == "Example Widget")
        #expect(item.imageURL == "https://example.com/widget.png")
        #expect(item.size == "12 oz")
        #expect(item.id == item.code)
        #expect(!item.isPlaceholder)
        #expect(item.displayTitle == "Example Widget")
    }

    @Test("Missing optional fields decode to empty values, not failure")
    func missingFieldsDefault() throws {
        let json = """
        { "code": "012345678905" }
        """
        let item = try ProductItem.decode(from: Data(json.utf8))
        #expect(item.company == "")
        #expect(item.description == "")
        #expect(item.imageURL == nil)
        #expect(item.size == "")
        #expect(item.isPlaceholder)
        #expect(item.displayTitle == "012345678905")
    }

    @Test("A record without a code fails to decode")
    func missingCodeThrows() {
        let json = """
        { "company": "Example Co" }
        """
        #expect(throws: DecodingError.self) {
            try ProductItem.decode(from: Data(json.utf8))
        }
    }

    @Test("Malformed JSON fails to decode")
    func malformedJSONThrows() {
        #expect(throws: DecodingError.self) {
            try ProductItem.decode(from: Data("not json".utf8))
        }
    }
}
