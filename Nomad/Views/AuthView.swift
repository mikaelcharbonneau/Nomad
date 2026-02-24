//
//  AuthView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var isSignUp = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            NomadTheme.offWhite.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(NomadTheme.darkGreen)

                        Text("Nomad")
                            .font(.system(.largeTitle, design: .default, weight: .bold))
                            .foregroundStyle(NomadTheme.darkText)

                        Text("Find your dream home")
                            .font(.subheadline)
                            .foregroundStyle(NomadTheme.lightGrey)
                    }

                    VStack(spacing: 0) {
                        Picker("", selection: $isSignUp) {
                            Text("Sign Up").tag(true)
                            Text("Sign In").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .padding(.bottom, 24)

                        VStack(spacing: 16) {
                            if isSignUp {
                                AuthTextField(icon: "person", placeholder: "Full Name", text: $name)
                                    .textContentType(.name)
                            }

                            AuthTextField(icon: "envelope", placeholder: "Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)

                            AuthTextField(icon: "lock", placeholder: "Password", text: $password, isSecure: true)
                                .textContentType(isSignUp ? .newPassword : .password)
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.top, 8)
                        }

                        Button {
                            Task { await authenticate() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.black, in: .capsule)
                            .foregroundStyle(.white)
                            .font(.headline)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.5)
                        .padding(.top, 24)

                        orDivider
                            .padding(.top, 20)

                        SignInWithAppleButton(
                            .signIn,
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                appVM.authService.handleAppleSignIn(result: result)
                            }
                        )
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 52)
                        .clipShape(.capsule)
                        .padding(.top, 16)
                    }
                    .padding(24)
                    .background(.white, in: .rect(cornerRadius: NomadTheme.pillRadius))
                    .shadow(color: .black.opacity(0.06), radius: 20, y: 10)

                    Spacer()

                    Button {
                        appVM.authService.continueAsGuest()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundStyle(NomadTheme.lightGrey)
                            .underline()
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(NomadTheme.lightGrey.opacity(0.3))
                .frame(height: 1)
            Text("or")
                .font(.subheadline)
                .foregroundStyle(NomadTheme.lightGrey)
            Rectangle()
                .fill(NomadTheme.lightGrey.opacity(0.3))
                .frame(height: 1)
        }
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && password.count >= 6
        }
        return !email.isEmpty && !password.isEmpty
    }

    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        do {
            if isSignUp {
                try await appVM.authService.signUp(name: name, email: email, password: password)
            } else {
                try await appVM.authService.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = "Something went wrong. Please try again."
        }
        isLoading = false
    }
}

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(NomadTheme.lightGrey)
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(16)
        .background(NomadTheme.offWhite, in: .capsule)
    }
}
