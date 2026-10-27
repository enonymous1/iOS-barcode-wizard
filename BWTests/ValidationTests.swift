import Testing

@testable import BW

@Suite("Validation and barcode normalization")
struct ValidationTests {
    @Test("Valid emails pass, invalid ones fail")
    func emailValidation() {
        #expect(Validation.isValidEmail("user@example.com"))
        #expect(Validation.isValidEmail("first.last+tag@example.co.uk"))
        #expect(!Validation.isValidEmail("not-an-email"))
        #expect(!Validation.isValidEmail("user@"))
        #expect(!Validation.isValidEmail("@example.com"))
        #expect(!Validation.isValidEmail(""))
    }

    @Test("Passwords under 8 characters are rejected")
    func passwordLength() {
        #expect(Validation.passwordProblem("short") != nil)
        #expect(Validation.passwordProblem("1234567") != nil)
        #expect(Validation.passwordProblem("12345678") == nil)
    }

    @Test("Password confirmation must match exactly")
    func passwordMatch() {
        #expect(Validation.passwordsMatch("same-password", "same-password"))
        #expect(!Validation.passwordsMatch("one", "two"))
    }

    @Test("Barcode normalization trims but never drops characters")
    func barcodeNormalization() {
        // v1's dead lookup dropped the first character of every
        // barcode; normalization must never do that.
        #expect(Barcode.normalized("  012345678905  ") == "012345678905")
        #expect(Barcode.normalized("012345678905") == "012345678905")
        #expect(Barcode.isUsable("012345678905"))
        #expect(!Barcode.isUsable("   "))
        #expect(!Barcode.isUsable(""))
    }
}
