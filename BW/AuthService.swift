import FirebaseAuth
import FirebaseCore
import Foundation

/// A signed-in user, reduced to what the app actually uses.
/// v1 passed `user.email!` around and used the email as a Firestore
/// collection name; v2 keys everything by `uid`, which survives an
/// email change and does not expose the address in the data layout.
struct AuthUser: Equatable, Sendable {
    let uid: String
    let email: String?
}

/// Email/password authentication, behind a protocol so view
/// models and tests can use a fake instead of Firebase.
protocol AuthService: Sendable {
    var currentUser: AuthUser? { get }
    func signIn(email: String, password: String) async throws -> AuthUser
    func register(email: String, password: String) async throws -> AuthUser
    func sendPasswordReset(email: String) async throws
    func signOut() throws
}

/// Firebase Auth, using the async/await API throughout. v1 used
/// completion handlers and force-unwrapped every text field; the
/// view models now pass validated strings and await the result.
final class FirebaseAuthService: AuthService, @unchecked Sendable {
    var currentUser: AuthUser? {
        // ContentView creates its view model before it knows
        // whether Firebase is configured. Touching Auth.auth()
        // with no default app is a crash, so an unconfigured
        // app simply has no current user.
        guard FirebaseApp.app() != nil,
              let user = Auth.auth().currentUser
        else { return nil }
        return AuthUser(uid: user.uid, email: user.email)
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().signIn(
            withEmail: email,
            password: password
        )
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }

    func register(email: String, password: String) async throws -> AuthUser {
        let result = try await Auth.auth().createUser(
            withEmail: email,
            password: password
        )
        return AuthUser(uid: result.user.uid, email: result.user.email)
    }

    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

/// In-memory stand-in for previews and tests. Registering and
/// signing in with the same email succeed; anything else throws.
final class FakeAuthService: AuthService, @unchecked Sendable {
    private var users: [String: String] = [:]
    private(set) var currentUser: AuthUser?

    enum FakeError: Error {
        case wrongPassword
        case userNotFound
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        guard let stored = users[email] else {
            throw FakeError.userNotFound
        }
        guard stored == password else {
            throw FakeError.wrongPassword
        }
        let user = AuthUser(uid: "uid-\(email)", email: email)
        currentUser = user
        return user
    }

    func register(email: String, password: String) async throws -> AuthUser {
        users[email] = password
        let user = AuthUser(uid: "uid-\(email)", email: email)
        currentUser = user
        return user
    }

    func sendPasswordReset(email: String) async throws {
        guard users[email] != nil else {
            throw FakeError.userNotFound
        }
    }

    func signOut() throws {
        currentUser = nil
    }
}
