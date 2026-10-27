import SwiftUI

/// Sign-in and registration, as one form with a mode switch.
/// v1 had two screens duplicating the same validation (each with
/// its own alert side effects) and no password reset at all.
/// Validation problems render inline under the form; only a real
/// Firebase failure is shown the same way, never as a modal
/// that has to be dismissed before the user can fix the input.
struct AuthView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mode", selection: $viewModel.mode) {
                        Text("Sign In").tag(AuthViewModel.Mode.signIn)
                        Text("Register").tag(AuthViewModel.Mode.register)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(
                            viewModel.mode == .register
                                ? .newPassword : .password
                        )
                    if viewModel.mode == .register {
                        SecureField(
                            "Confirm password",
                            text: $viewModel.passwordConfirmation
                        )
                        .textContentType(.newPassword)
                    }
                }

                if let message = viewModel.message {
                    Section {
                        Text(message)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        Task { await viewModel.submit() }
                    } label: {
                        if viewModel.isBusy {
                            ProgressView()
                        } else {
                            Text(
                                viewModel.mode == .signIn
                                    ? "Sign In" : "Register"
                            )
                        }
                    }
                    .disabled(viewModel.isBusy)

                    if viewModel.mode == .signIn {
                        Button("Forgot password?") {
                            Task { await viewModel.sendPasswordReset() }
                        }
                        .disabled(viewModel.isBusy)
                    }
                }
            }
            .navigationTitle("Barcode Wizard")
        }
    }
}
