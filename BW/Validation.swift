import Foundation

/// Pure input validation. v1 duplicated this regex in SignInVC and
/// RegistrationVC, and each copy presented its own alert as a side
/// effect, so the result depended on which screen you were on.
/// These functions return a value and nothing else; the views decide
/// how to display a failure.
enum Validation {
    /// The same shape v1 accepted, minus the alert: a local part, an
    /// @, a domain, and a TLD of at least two characters.
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return email.range(
            of: "^" + pattern + "$",
            options: .regularExpression
        ) != nil
    }

    /// Firebase accepts six characters; this app asks for eight,
    /// which is the current minimum worth enforcing in the UI.
    /// Returns a human-readable reason, or nil when the password
    /// is acceptable.
    static func passwordProblem(_ password: String) -> String? {
        if password.count < 8 {
            return "Passwords must be at least 8 characters."
        }
        return nil
    }

    /// Registration check, kept separate from the length check so
    /// the form can report exactly one problem at a time.
    static func passwordsMatch(_ first: String, _ second: String) -> Bool {
        first == second
    }
}

/// Barcode cleanup. v1's dead `findWithBarcodeMonster` dropped the
/// first character of every barcode (`dropFirst()`), which would
/// have corrupted every lookup that used it. A scanned code is
/// used exactly as scanned, apart from surrounding whitespace.
enum Barcode {
    static func normalized(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isUsable(_ raw: String) -> Bool {
        !normalized(raw).isEmpty
    }
}
