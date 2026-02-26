//
//  AuthService.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation
import AuthenticationServices
import FirebaseAuth

@Observable
@MainActor
class AuthService {
    static let shared = AuthService()

    var currentUser: User? = nil
    var isAuthenticated: Bool { currentUser != nil && !(currentUser?.isGuest ?? true) }
    var isGuest: Bool { currentUser?.isGuest ?? false }

    private var authListener: AuthStateDidChangeListenerHandle?
    private var isGuestSession = false

    private init() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let user {
                isGuestSession = false
                currentUser = mapUser(user)
            } else if isGuestSession {
                currentUser = .guest
            } else {
                currentUser = nil
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        isGuestSession = false
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUser = mapUser(result.user)
    }

    func signUp(name: String, email: String, password: String) async throws {
        isGuestSession = false
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let changeRequest = result.user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
        currentUser = mapUser(result.user, fallbackName: name)
    }

    func handleAppleSignIn(result: Result<ASAuthorization, any Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

            let userID = credential.user
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let email = credential.email ?? ""

            let storedName = fullName.isEmpty ? (UserDefaults.standard.string(forKey: "appleUserName") ?? "Apple User") : fullName
            if !fullName.isEmpty {
                UserDefaults.standard.set(fullName, forKey: "appleUserName")
            }
            if !email.isEmpty {
                UserDefaults.standard.set(email, forKey: "appleUserEmail")
            }

            let storedEmail = email.isEmpty ? (UserDefaults.standard.string(forKey: "appleUserEmail") ?? "") : email

            currentUser = User(
                id: userID,
                name: storedName,
                email: storedEmail,
                avatarURL: nil,
                isGuest: false
            )

        case .failure:
            break
        }
    }

    func continueAsGuest() {
        isGuestSession = true
        currentUser = .guest
    }

    func signOut() {
        isGuestSession = false
        try? Auth.auth().signOut()
        currentUser = nil
    }

    private func mapUser(_ user: FirebaseAuth.User, fallbackName: String? = nil) -> User {
        let name = user.displayName ?? fallbackName ?? user.email?.components(separatedBy: "@").first?.capitalized ?? "User"
        return User(
            id: user.uid,
            name: name,
            email: user.email ?? "",
            avatarURL: nil,
            isGuest: false
        )
    }
}
