//
//  SavedView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct SavedView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var showNewFolder = false
    @State private var newFolderName = ""
    @State private var selectedFolder: SavedFolder?
    @State private var selectedProperty: Property?

    var body: some View {
        NavigationStack {
            ZStack {
                NomadTheme.offWhite.ignoresSafeArea()

                if appVM.savedPropertyIDs.isEmpty {
                    ContentUnavailableView(
                        "No Saved Properties",
                        systemImage: "heart",
                        description: Text("Properties you save will appear here. Swipe right on Match or tap the heart icon to save.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            allSavedSection
                            foldersSection
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showNewFolder = true } label: {
                        Image(systemName: "folder.badge.plus")
                            .foregroundStyle(NomadTheme.darkGreen)
                    }
                }
            }
            .alert("New Folder", isPresented: $showNewFolder) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    if !newFolderName.isEmpty {
                        appVM.addFolder(newFolderName)
                        newFolderName = ""
                    }
                }
                Button("Cancel", role: .cancel) { newFolderName = "" }
            }
            .fullScreenCover(item: $selectedProperty) { property in
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private var allSavedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Saved")
                    .font(.title3.bold())
                    .foregroundStyle(NomadTheme.darkText)
                Text("(\(appVM.savedProperties.count))")
                    .font(.subheadline)
                    .foregroundStyle(NomadTheme.lightGrey)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appVM.savedProperties) { property in
                        Button { selectedProperty = property } label: {
                            SavedPropertyCard(property: property)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var foldersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folders")
                .font(.title3.bold())
                .foregroundStyle(NomadTheme.darkText)

            ForEach(appVM.folders) { folder in
                FolderRow(folder: folder, appVM: appVM, onPropertyTap: { property in
                    selectedProperty = property
                })
            }
            .onDelete { offsets in
                appVM.deleteFolder(at: offsets)
            }
        }
    }
}

struct SavedPropertyCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color(.secondarySystemBackground)
                .frame(width: 160, height: 120)
                .overlay {
                    AsyncImage(url: URL(string: property.imageURLs.first ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        } else {
                            Image(systemName: "photo").foregroundStyle(.tertiary)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 16))

            Text(property.fullFormattedPrice)
                .font(.subheadline.bold())
                .foregroundStyle(NomadTheme.darkText)

            Text(property.city)
                .font(.caption)
                .foregroundStyle(NomadTheme.lightGrey)

            HStack(spacing: 6) {
                if property.bedrooms > 0 { SpecItem(icon: "bed.double.fill", value: "\(property.bedrooms)") }
                if property.bathrooms > 0 { SpecItem(icon: "shower.fill", value: "\(property.bathrooms)") }
            }
        }
        .frame(width: 160)
        .padding(10)
        .background(.white, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

struct FolderRow: View {
    let folder: SavedFolder
    let appVM: AppViewModel
    let onPropertyTap: (Property) -> Void
    @State private var isExpanded = false

    private var folderProperties: [Property] {
        appVM.listingsService.properties.filter { folder.propertyIDs.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) { isExpanded.toggle() }
            } label: {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(NomadTheme.darkGreen)
                    Text(folder.name)
                        .font(.body.weight(.medium))
                        .foregroundStyle(NomadTheme.darkText)
                    Text("(\(folderProperties.count))")
                        .font(.caption)
                        .foregroundStyle(NomadTheme.lightGrey)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NomadTheme.lightGrey)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }

            if isExpanded && !folderProperties.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(folderProperties) { property in
                            Button { onPropertyTap(property) } label: {
                                MiniPropertyCard(property: property)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .contentMargins(.horizontal, 0)
            }
        }
        .background(.white, in: .rect(cornerRadius: 16))
    }
}
