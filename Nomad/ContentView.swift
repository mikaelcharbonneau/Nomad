//
//  ContentView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct ContentView: View {
    @State private var appVM = AppViewModel()
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if appVM.authService.currentUser == nil {
                AuthView()
                    .environment(appVM)
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "magnifyingglass", value: 0) {
                ExploreView()
                    .environment(appVM)
            }

            Tab("Match", systemImage: "heart", value: 1) {
                MatchView()
                    .environment(appVM)
            }

            Tab("Agent", systemImage: "bubble", value: 2) {
                AgentView()
                    .environment(appVM)
            }

            Tab("Saved", systemImage: "bookmark", value: 3) {
                SavedView()
                    .environment(appVM)
            }

            Tab("Settings", systemImage: "gearshape", value: 4) {
                SettingsView()
                    .environment(appVM)
            }
        }
        .tint(NomadColor.Accent.primary)
        .environment(\.symbolVariants, .none)
    }
}
