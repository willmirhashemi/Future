import SwiftUI
import AuthenticationServices

struct AuthenticationStep: View {
    @EnvironmentObject var authService: AuthService
    let onComplete: () -> Void

    @State private var isSignIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showError = false
    @State private var isProcessing = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                // Header
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(Theme.Colors.accent)

                    Text(isSignIn ? "Welcome Back" : "Create Your Account")
                        .font(Theme.Fonts.title())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(isSignIn ? "Sign in to continue your journey" : "Join us and start achieving your goals")
                        .font(Theme.Fonts.subheadline())
                        .foregroundColor(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                // Form Fields
                VStack(spacing: Theme.Spacing.md) {
                    if !isSignIn {
                        CustomTextField(
                            icon: "person",
                            placeholder: "Display Name",
                            text: $displayName
                        )
                    }

                    CustomTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        textContentType: .emailAddress,
                        autocapitalization: .never
                    )

                    CustomSecureField(
                        icon: "lock",
                        placeholder: "Password",
                        text: $password
                    )

                    if !isSignIn {
                        CustomSecureField(
                            icon: "lock.badge.clock",
                            placeholder: "Confirm Password",
                            text: $confirmPassword
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Error Message
                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                }

                // Email/Password Button
                Button(action: handleEmailAuth) {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isSignIn ? "Sign In" : "Create Account")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isFormValid || isProcessing)
                .padding(.horizontal, Theme.Spacing.lg)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Theme.Colors.textTertiary.opacity(0.3))
                        .frame(height: 1)

                    Text("or continue with")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textTertiary)

                    Rectangle()
                        .fill(Theme.Colors.textTertiary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Social Sign In Buttons
                VStack(spacing: Theme.Spacing.md) {
                    // Google Sign In
                    Button(action: handleGoogleSignIn) {
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Continue with Google")
                                .font(Theme.Fonts.headline())
                        }
                        .foregroundColor(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.cardBackground)
                        .cornerRadius(Theme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(Theme.Colors.textTertiary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(isProcessing)

                    // Apple Sign In
                    SignInWithAppleButton(
                        onRequest: { request in
                            let appleRequest = authService.prepareAppleSignInRequest()
                            request.requestedScopes = appleRequest.requestedScopes
                            request.nonce = appleRequest.nonce
                        },
                        onCompletion: { result in
                            handleAppleSignIn(result: result)
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .disabled(isProcessing)
                }
                .padding(.horizontal, Theme.Spacing.lg)

                // Toggle Sign In / Sign Up
                Button(action: {
                    withAnimation {
                        isSignIn.toggle()
                        authService.errorMessage = nil
                    }
                }) {
                    Text(isSignIn ? "Don't have an account? Create one" : "Already have an account? Sign in")
                        .font(Theme.Fonts.subheadline())
                        .foregroundColor(Theme.Colors.accent)
                }
                .padding(.top, Theme.Spacing.sm)

                // Forgot Password (only in sign in mode)
                if isSignIn {
                    Button(action: handleForgotPassword) {
                        Text("Forgot Password?")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }

                Spacer(minLength: Theme.Spacing.xxl)
            }
        }
        .onChange(of: authService.currentUser) { _, newUser in
            if newUser != nil {
                onComplete()
            }
        }
    }

    // MARK: - Form Validation
    private var isFormValid: Bool {
        if isSignIn {
            return !email.isEmpty && !password.isEmpty && password.count >= 6
        } else {
            return !displayName.isEmpty &&
                   !email.isEmpty &&
                   !password.isEmpty &&
                   password.count >= 6 &&
                   password == confirmPassword
        }
    }

    // MARK: - Email Authentication
    private func handleEmailAuth() {
        isProcessing = true

        Task {
            do {
                if isSignIn {
                    try await authService.signIn(email: email, password: password)
                } else {
                    try await authService.signUp(email: email, password: password, displayName: displayName)
                }
                // onComplete will be called via onChange when currentUser updates
            } catch {
                // Error is handled by authService.errorMessage
            }
            isProcessing = false
        }
    }

    // MARK: - Google Sign In
    private func handleGoogleSignIn() {
        isProcessing = true

        Task {
            do {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let viewController = windowScene.windows.first?.rootViewController else {
                    isProcessing = false
                    return
                }

                try await authService.signInWithGoogle(presenting: viewController)
                // onComplete will be called via onChange when currentUser updates
            } catch {
                // Error is handled by authService.errorMessage
            }
            isProcessing = false
        }
    }

    // MARK: - Apple Sign In
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        isProcessing = true

        Task {
            switch result {
            case .success(let authorization):
                do {
                    try await authService.handleAppleSignIn(authorization: authorization)
                    // onComplete will be called via onChange when currentUser updates
                } catch {
                    // Error is handled by authService.errorMessage
                }
            case .failure(let error):
                authService.errorMessage = error.localizedDescription
            }
            isProcessing = false
        }
    }

    // MARK: - Forgot Password
    private func handleForgotPassword() {
        guard !email.isEmpty else {
            authService.errorMessage = "Please enter your email address first"
            return
        }

        Task {
            do {
                try await authService.resetPassword(email: email)
                authService.errorMessage = "Password reset email sent! Check your inbox."
            } catch {
                // Error is handled by authService.errorMessage
            }
        }
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .textContentType(.password)
            } else {
                TextField(placeholder, text: $text)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Custom Text Field (Extended)
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

#Preview {
    AuthenticationStep(onComplete: {})
        .environmentObject(AuthService())
        .preferredColorScheme(.dark)
        .background(Theme.Colors.background)
}
