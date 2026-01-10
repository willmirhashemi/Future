import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isShowingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    headerSection

                    // Form
                    VStack(spacing: Theme.Spacing.md) {
                        if isShowingSignUp {
                            signUpForm
                        } else {
                            signInForm
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Social Sign In
                    socialSignInSection

                    // Toggle Sign In/Sign Up
                    toggleSection

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(.top, Theme.Spacing.xxl)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.accent)

            Text("Endless Calendar")
                .font(Theme.Fonts.largeTitle())
                .foregroundColor(Theme.Colors.textPrimary)

            Text("Your AI-powered path to achieving your dreams")
                .font(Theme.Fonts.subheadline())
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    // MARK: - Sign In Form
    private var signInForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            CustomTextField(
                icon: "envelope",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )

            CustomSecureField(
                icon: "lock",
                placeholder: "Password",
                text: $password
            )

            Button(action: signIn) {
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Sign In")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)

            Button("Forgot Password?") {
                forgotPassword()
            }
            .font(Theme.Fonts.footnote())
            .foregroundColor(Theme.Colors.accent)
        }
    }

    // MARK: - Sign Up Form
    private var signUpForm: some View {
        VStack(spacing: Theme.Spacing.md) {
            CustomTextField(
                icon: "person",
                placeholder: "Display Name",
                text: $displayName
            )

            CustomTextField(
                icon: "envelope",
                placeholder: "Email",
                text: $email,
                keyboardType: .emailAddress
            )

            CustomSecureField(
                icon: "lock",
                placeholder: "Password",
                text: $password
            )

            CustomSecureField(
                icon: "lock.fill",
                placeholder: "Confirm Password",
                text: $confirmPassword
            )

            Button(action: signUp) {
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Create Account")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(authService.isLoading || !isValidSignUp)
        }
    }

    // MARK: - Social Sign In Section
    private var socialSignInSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Rectangle()
                    .fill(Theme.Colors.textTertiary)
                    .frame(height: 1)

                Text("or continue with")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textTertiary)

                Rectangle()
                    .fill(Theme.Colors.textTertiary)
                    .frame(height: 1)
            }
            .padding(.horizontal, Theme.Spacing.lg)

            HStack(spacing: Theme.Spacing.md) {
                // Apple Sign In
                SignInWithAppleButton(.signIn) { request in
                    let appleRequest = authService.prepareAppleSignInRequest()
                    request.requestedScopes = appleRequest.requestedScopes
                    request.nonce = appleRequest.nonce
                }
                onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(Theme.CornerRadius.medium)

                // Google Sign In Button
                Button(action: signInWithGoogle) {
                    HStack {
                        Image(systemName: "g.circle.fill")
                            .font(.title2)
                        Text("Google")
                            .font(Theme.Fonts.headline())
                    }
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.secondaryBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)
        }
    }

    // MARK: - Toggle Section
    private var toggleSection: some View {
        HStack {
            Text(isShowingSignUp ? "Already have an account?" : "Don't have an account?")
                .font(Theme.Fonts.footnote())
                .foregroundColor(Theme.Colors.textSecondary)

            Button(isShowingSignUp ? "Sign In" : "Sign Up") {
                withAnimation {
                    isShowingSignUp.toggle()
                    clearFields()
                }
            }
            .font(Theme.Fonts.footnote())
            .fontWeight(.semibold)
            .foregroundColor(Theme.Colors.accent)
        }
    }

    // MARK: - Computed Properties
    private var isValidSignUp: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }

    // MARK: - Actions
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func signUp() {
        Task {
            do {
                try await authService.signUp(email: email, password: password, displayName: displayName)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let viewController = windowScene.windows.first?.rootViewController else {
            return
        }

        Task {
            do {
                try await authService.signInWithGoogle(presenting: viewController)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            Task {
                do {
                    try await authService.handleAppleSignIn(authorization: authorization)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func forgotPassword() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            showError = true
            return
        }

        Task {
            do {
                try await authService.resetPassword(email: email)
                errorMessage = "Password reset email sent"
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }

    private func clearFields() {
        email = ""
        password = ""
        displayName = ""
        confirmPassword = ""
    }
}

// MARK: - Custom Text Field
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            TextField(placeholder, text: $text)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Custom Secure Field
struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
            } else {
                TextField(placeholder, text: $text)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthService())
        .environmentObject(ThemeManager())
}
