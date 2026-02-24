//
//  AuthService.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation
import AuthenticationServices

@Observable
@MainActor
class AuthService {
    static let shared = AuthService()

    var currentUser: User? = nil
    var isAuthenticated: Bool { currentUser != nil && !(currentUser?.isGuest ?? true) }
    var isGuest: Bool { currentUser?.isGuest ?? false }

    private init() {}

    func signIn(email: String, password: String) async throws {
        try await Task.sleep(for: .seconds(1))
        currentUser = User(
            id: UUID().uuidString,
            name: email.components(separatedBy: "@").first?.capitalized ?? "User",
            email: email,
            avatarURL: nil,
            isGuest: false
        )
    }

    func signUp(name: String, email: String, password: String) async throws {
        try await Task.sleep(for: .seconds(1.2))
        currentUser = User(
            id: UUID().uuidString,
            name: name,
            email: email,
            avatarURL: nil,
            isGuest: false
        )
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
        currentUser = .guest
    }

    func signOut() {
        currentUser = nil
    }
}
