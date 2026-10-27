import Foundation
import Observation

/// Auth screen state. v1 validated by presenting alerts from
/// inside the validation functions and force-unwrapping the text
/// fields; here validation produces a message string (or nil) and
/// the view renders it inline, and Firebase only ever sees
/// strings that have already passed validation.
@MainActor
@Observable
final class AuthViewModel {
    enum Mode {
        case signIn
        case register
    }

    var mode: Mode = .signIn
    var email = ""
    var password = ""
    var passwordConfirmation = ""
    var message: String?
    var isBusy = false

    /// Set after a successful sign-in or registration; ContentView
    /// switches to the main tabs when this becomes non-nil.
    var user: AuthUser?

    private let service: any AuthService

    init(service: any AuthService) {
        self.service = service
        self.user = service.currentUser
    }

    /// The one validation message for the current form, or nil.
    /// Checked in order so the form reports a single problem.
    var formProblem: String? {
        if email.isEmpty || password.isEmpty {
            return "Please fill in all fields."
        }
        if !Validation.isValidEmail(email) {
            return "Please enter a valid email address."
        }
        if let problem = Validation.passwordProblem(password) {
            return problem
        }
        if mode == .register {
            if passwordConfirmation.isEmpty {
                return "Please confirm your password."
            }
            if !Validation.passwordsMatch(password, passwordConfirmation) {
                return "Passwords don't match."
            }
        }
        return nil
    }

    func submit() async {
        guard formProblem == nil else {
            message = formProblem
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            switch mode {
            case .signIn:
                user = try await service.signIn(
                    email: email,
                    password: password
                )
            case .register:
                user = try await service.register(
                    email: email,
                    password: password
                )
            }
            message = nil
        } catch {
            message = error.localizedDescription
        }
    }

    func sendPasswordReset() async {
        guard Validation.isValidEmail(email) else {
            message = "Enter a valid email address first."
            return
        }
        isBusy = true
        defer { isBusy = false }
        do {
            try await service.sendPasswordReset(email: email)
            message = "Password reset email sent."
        } catch {
            message = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try service.signOut()
            user = nil
        } catch {
            message = error.localizedDescription
        }
    }
}
