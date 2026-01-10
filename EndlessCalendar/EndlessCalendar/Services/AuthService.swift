import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import GoogleSignIn
import CryptoKit

// MARK: - Auth Service
@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: User?
    @Published var firebaseUser: FirebaseAuth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasCompletedOnboarding = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var currentNonce: String?

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            auth.removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listener
    private func setupAuthStateListener() {
        authStateListener = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.firebaseUser = user
                if let user = user {
                    await self?.fetchUserData(userId: user.uid)
                } else {
                    self?.currentUser = nil
                    self?.hasCompletedOnboarding = false
                }
            }
        }
    }

    // MARK: - Check Current User
    func checkCurrentUser() async {
        guard let firebaseUser = auth.currentUser else {
            currentUser = nil
            hasCompletedOnboarding = false
            return
        }

        await fetchUserData(userId: firebaseUser.uid)
    }

    // MARK: - Fetch User Data
    private func fetchUserData(userId: String) async {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if let user = try? document.data(as: User.self) {
                currentUser = user
                hasCompletedOnboarding = user.hasCompletedOnboarding
            }
        } catch {
            print("Error fetching user data: \(error)")
        }
    }

    // MARK: - Email/Password Sign Up
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let newUser = User(
                id: result.user.uid,
                email: email,
                displayName: displayName
            )

            try await createUserDocument(user: newUser)
            currentUser = newUser
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Email/Password Sign In
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchUserData(userId: result.user.uid)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Google Sign In
    func signInWithGoogle(presenting viewController: UIViewController) async throws {
        isLoading = true
        errorMessage = nil

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            isLoading = false
            throw AuthError.missingClientID
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: viewController)
            guard let idToken = result.user.idToken?.tokenString else {
                isLoading = false
                throw AuthError.missingIDToken
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await auth.signIn(with: credential)
            await handleSocialSignIn(authResult: authResult, displayName: result.user.profile?.name)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Apple Sign In
    func handleAppleSignIn(authorization: ASAuthorization) async throws {
        isLoading = true
        errorMessage = nil

        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            isLoading = false
            throw AuthError.invalidCredential
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )

        do {
            let authResult = try await auth.signIn(with: credential)
            let displayName = [
                appleIDCredential.fullName?.givenName,
                appleIDCredential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")

            await handleSocialSignIn(authResult: authResult, displayName: displayName.isEmpty ? nil : displayName)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func prepareAppleSignInRequest() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }

    // MARK: - Handle Social Sign In
    private func handleSocialSignIn(authResult: AuthDataResult, displayName: String?) async {
        let userId = authResult.user.uid

        do {
            let document = try await db.collection("users").document(userId).getDocument()

            if document.exists {
                await fetchUserData(userId: userId)
            } else {
                let newUser = User(
                    id: userId,
                    email: authResult.user.email ?? "",
                    displayName: displayName ?? authResult.user.displayName ?? "User"
                )
                try await createUserDocument(user: newUser)
                currentUser = newUser
            }
        } catch {
            print("Error handling social sign in: \(error)")
        }
    }

    // MARK: - Create User Document
    private func createUserDocument(user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user)
    }

    // MARK: - Update User
    func updateUser(_ user: User) async throws {
        guard let userId = user.id else { return }
        try db.collection("users").document(userId).setData(from: user, merge: true)
        currentUser = user
        hasCompletedOnboarding = user.hasCompletedOnboarding
    }

    // MARK: - Complete Onboarding
    func completeOnboarding(category: GoalCategory, responses: QuestionnaireResponses) async throws {
        guard var user = currentUser else { return }

        user.selectedCategory = category
        user.questionnaireResponses = responses
        user.hasCompletedOnboarding = true

        try await updateUser(user)
    }

    // MARK: - Reset Goals
    func resetGoals() async throws {
        guard var user = currentUser else { return }

        user.selectedCategory = nil
        user.questionnaireResponses = nil
        user.hasCompletedOnboarding = false

        try await updateUser(user)
    }

    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        hasCompletedOnboarding = false
    }

    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }

    // MARK: - Update Last Active
    func updateLastActive() async {
        guard var user = currentUser, let userId = user.id else { return }
        user.lastActiveAt = Date()

        do {
            try db.collection("users").document(userId).setData(from: user, merge: true)
        } catch {
            print("Error updating last active: \(error)")
        }
    }

    // MARK: - Helper Functions
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case missingClientID
    case missingIDToken
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Missing Google client ID"
        case .missingIDToken:
            return "Missing ID token"
        case .invalidCredential:
            return "Invalid credential"
        }
    }
}
