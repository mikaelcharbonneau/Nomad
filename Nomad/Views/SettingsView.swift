//
//  SettingsView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct SettingsView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showAuth = false
    @State private var seedStatus: String?

    var body: some View {
        NavigationStack {
            ZStack {
                NomadTheme.offWhite.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profileCard
                        accountSection
                        preferencesSection
                        aboutSection
                        developerSection
                        if appVM.authService.isAuthenticated {
                            signOutButton
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAuth) {
                AuthView()
                    .environment(appVM)
            }
        }
    }

    private var profileCard: some View {
        VStack(spacing: 16) {
            Image(systemName: appVM.authService.isAuthenticated ? "person.crop.circle.fill" : "person.crop.circle")
                .font(.system(size: 60))
                .foregroundStyle(NomadTheme.darkGreen)

            if let user = appVM.authService.currentUser {
                VStack(spacing: 4) {
                    Text(user.name)
                        .font(.title3.bold())
                        .foregroundStyle(NomadTheme.darkText)
                    if !user.email.isEmpty {
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(NomadTheme.lightGrey)
                    }
                    if user.isGuest {
                        Text("Guest Account")
                            .font(.caption)
                            .foregroundStyle(NomadTheme.lightGrey)
                            .padding(.top, 2)
                    }
                }
            }

            if !appVM.authService.isAuthenticated {
                Button { showAuth = true } label: {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(color: NomadTheme.darkGreen))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.white, in: .rect(cornerRadius: NomadTheme.pillRadius))
        .shadow(color: .black.opacity(0.04), radius: 16, y: 8)
    }

    private var accountSection: some View {
        SettingsSection(title: "Account") {
            SettingsRow(icon: "heart.fill", title: "Saved Properties", detail: "\(appVM.savedPropertyIDs.count)")
            SettingsRow(icon: "folder.fill", title: "Folders", detail: "\(appVM.folders.count)")
            SettingsRow(icon: "bell.fill", title: "Notifications", detail: appVM.savedSearchNotifications ? "On" : "Off")
        }
    }

    private var preferencesSection: some View {
        SettingsSection(title: "Preferences") {
            SettingsRow(icon: "globe", title: "Language", detail: "English")
            SettingsRow(icon: "dollarsign.circle.fill", title: "Currency", detail: "USD")
            SettingsRow(icon: "ruler.fill", title: "Unit System", detail: "Imperial")
        }
    }

    private var aboutSection: some View {
        SettingsSection(title: "About") {
            SettingsRow(icon: "info.circle.fill", title: "Version", detail: "1.0.0")
            SettingsRow(icon: "doc.text.fill", title: "Terms of Service", detail: "")
            SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", detail: "")
            SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", detail: "")
        }
    }

    private var developerSection: some View {
        SettingsSection(title: "Developer") {
            Button {
                Task { await seedListings() }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.body)
                        .foregroundStyle(NomadTheme.darkGreen)
                        .frame(width: 28)

                    Text("Seed Sample Listings")
                        .font(.body)
                        .foregroundStyle(NomadTheme.darkText)

                    Spacer()

                    if let seedStatus {
                        Text(seedStatus)
                            .font(.caption)
                            .foregroundStyle(NomadTheme.lightGrey)
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)
        }
    }

    private var signOutButton: some View {
        Button {
            appVM.authService.signOut()
        } label: {
            Text("Sign Out")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PillButtonStyle(filled: false, color: .red))
    }

    private func seedListings() async {
        seedStatus = "Seeding..."
        do {
            try await appVM.listingsService.seedSampleListings()
            seedStatus = "Done"
        } catch {
            seedStatus = "Failed"
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(NomadTheme.lightGrey)
                .padding(.horizontal, 4)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(.white, in: .rect(cornerRadius: 16))
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(NomadTheme.darkGreen)
                .frame(width: 28)

            Text(title)
                .font(.body)
                .foregroundStyle(NomadTheme.darkText)

            Spacer()

            if !detail.isEmpty {
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(NomadTheme.lightGrey)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(NomadTheme.lightGrey)
        }
        .padding(16)
    }
}
