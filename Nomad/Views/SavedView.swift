import SwiftUI

struct SavedView: View {
    @Environment(AppViewModel.self) private var appVM

    @State private var showNewFolder = false
    @State private var newFolderName = ""
    @State private var selectedProperty: Property?

    var body: some View {
        NavigationStack {
            Group {
                if appVM.savedPropertyIDs.isEmpty {
                    ContentUnavailableView(
                        "No Saved Properties",
                        systemImage: "heart",
                        description: Text("Properties you save will appear here. Swipe right on Match or tap the heart icon to save.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: NomadSpacing.sectionVertical) {
                            allSavedSection
                            foldersSection
                        }
                        .padding(.horizontal, NomadSpacing.pageHorizontal)
                        .padding(.top, NomadSpacing.md)
                        .padding(.bottom, NomadSpacing.xxl)
                    }
                }
            }
            .nomadScreenBackground()
            .navigationTitle("Saved")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NomadIconCircleButton(icon: "folder.badge.plus", emphasis: .neutral) {
                        showNewFolder = true
                    }
                    .accessibilityLabel("Create folder")
                }
            }
            .alert("New Folder", isPresented: $showNewFolder) {
                TextField("Folder name", text: $newFolderName)
                Button("Create") {
                    let trimmed = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        appVM.addFolder(trimmed)
                        newFolderName = ""
                    }
                }
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                }
            }
            .fullScreenCover(item: $selectedProperty) { property in
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private var allSavedSection: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.md) {
            NomadSectionHeader(
                title: "All Saved",
                subtitle: "\(appVM.savedProperties.count) properties"
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NomadSpacing.sm) {
                    ForEach(appVM.savedProperties) { property in
                        Button { selectedProperty = property } label: {
                            NomadPropertyCard(property: property, variant: .compact)
                                .frame(width: 220)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var foldersSection: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.md) {
            NomadSectionHeader(title: "Folders", subtitle: "Organized collections")

            VStack(spacing: NomadSpacing.sm) {
                ForEach(appVM.folders) { folder in
                    FolderRow(folder: folder, appVM: appVM, onPropertyTap: { property in
                        selectedProperty = property
                    })
                }
            }
        }
    }
}

private struct FolderRow: View {
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
                withAnimation(.snappy) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: NomadSpacing.sm) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(NomadColor.Accent.primary)

                    Text(folder.name)
                        .font(NomadTypography.bodyStrong)
                        .foregroundStyle(NomadColor.Text.primary)

                    Text("(\(folderProperties.count))")
                        .font(NomadTypography.caption)
                        .foregroundStyle(NomadColor.Text.secondary)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NomadColor.Text.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(NomadSpacing.md)
            }
            .buttonStyle(.plain)

            if isExpanded {
                if folderProperties.isEmpty {
                    Text("No properties in this folder yet.")
                        .font(NomadTypography.caption)
                        .foregroundStyle(NomadColor.Text.secondary)
                        .padding(.horizontal, NomadSpacing.md)
                        .padding(.bottom, NomadSpacing.md)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: NomadSpacing.sm) {
                            ForEach(folderProperties) { property in
                                Button { onPropertyTap(property) } label: {
                                    NomadPropertyCard(property: property, variant: .mini)
                                        .frame(width: 190)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, NomadSpacing.md)
                        .padding(.bottom, NomadSpacing.md)
                    }
                    .contentMargins(.horizontal, 0)
                }
            }
        }
        .nomadCardSurface(level: .level1, radius: NomadRadius.card)
    }
}
