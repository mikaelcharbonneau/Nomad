import SwiftUI

struct ExploreView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var filter = PropertyFilter()
    @State private var searchText = ""
    @State private var showFilter = false
    @State private var showSearch = false
    @State private var showMap = false
    @State private var showSaveSearch = false
    @State private var showCreateListing = false
    @State private var selectedProperty: Property?
    @State private var sortOption: SortOption = .newest

    private var filteredProperties: [Property] {
        var results = appVM.listingsService.filteredProperties(with: filter)
        if !searchText.isEmpty {
            results = results.filter {
                $0.city.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText) ||
                $0.region.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case .newest:
            results.sort { $0.listingDate > $1.listingDate }
        case .priceLow:
            results.sort { $0.price < $1.price }
        case .priceHigh:
            results.sort { $0.price > $1.price }
        case .largest:
            results.sort { $0.squareFeet > $1.squareFeet }
        }

        return results
    }

    private var featuredProperties: [Property] {
        appVM.listingsService.properties.filter { $0.isFeatured }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NomadSpacing.sectionVertical) {
                    headerSection
                    searchBarSection
                    resultsHeader
                    propertyList

                    if !featuredProperties.isEmpty {
                        featuredSection
                    }
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.top, NomadSpacing.sm)
                .padding(.bottom, NomadSpacing.xxl)
            }
            .safeAreaInset(edge: .bottom) {
                NomadPrimaryCTA(title: "View map", icon: "map.fill") {
                    showMap = true
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.vertical, NomadSpacing.sm)
                .background(.ultraThinMaterial)
            }
            .nomadScreenBackground()
            .navigationBarHidden(true)
            .sheet(isPresented: $showFilter) {
                FilterView(filter: $filter, onApply: {
                    showFilter = false
                    if filter.isActive {
                        showSaveSearch = true
                    }
                })
            }
            .sheet(isPresented: $showSearch) {
                RegionSearchView(selectedCities: $filter.selectedCities, searchText: $searchText)
            }
            .sheet(isPresented: $showSaveSearch) {
                SaveSearchSheet(appVM: appVM)
            }
            .fullScreenCover(isPresented: $showCreateListing) {
                CreateListingView()
                    .environment(appVM)
            }
            .fullScreenCover(isPresented: $showMap) {
                MapExploreView(properties: filteredProperties, appVM: appVM)
            }
            .fullScreenCover(item: $selectedProperty) { property in
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private var headerSection: some View {
        HStack(spacing: NomadSpacing.md) {
            Image("NomadLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 44)

            Spacer(minLength: 0)

            NomadIconCircleButton(icon: "plus", emphasis: .accent) {
                showCreateListing = true
            }
            .accessibilityLabel("Create listing")
        }
    }

    private var searchBarSection: some View {
        HStack(spacing: NomadSpacing.sm) {
            NomadSearchField(placeholder: "Search by region, city, street...") {
                showSearch = true
            }

            NomadIconCircleButton(
                icon: "slider.horizontal.3",
                emphasis: filter.isActive ? .accent : .neutral,
                size: 52
            ) {
                showFilter = true
            }
            .accessibilityLabel("Open filters")
        }
    }

    private var resultsHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: NomadSpacing.sm) {
            Text("\(filteredProperties.count) properties for \(filter.listingType.rawValue.lowercased())")
                .font(NomadTypography.body)
                .foregroundStyle(NomadColor.Text.secondary)

            Spacer(minLength: NomadSpacing.sm)

            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button {
                        sortOption = option
                    } label: {
                        HStack {
                            Text(option.title)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: NomadSpacing.xxs) {
                    Text(sortOption.title)
                        .font(NomadTypography.caption)
                    Image(systemName: "chevron.down")
                        .font(NomadTypography.meta)
                }
                .foregroundStyle(NomadColor.Text.primary)
                .padding(.horizontal, NomadSpacing.md)
                .padding(.vertical, NomadSpacing.xs)
                .background(NomadColor.Background.surface, in: .capsule)
                .overlay {
                    Capsule()
                        .stroke(NomadColor.Border.default, lineWidth: 1)
                }
            }
        }
    }

    private var propertyList: some View {
        LazyVStack(spacing: NomadSpacing.md) {
            ForEach(filteredProperties) { property in
                Button {
                    selectedProperty = property
                } label: {
                    NomadPropertyCard(
                        property: property,
                        variant: .full,
                        isSaved: appVM.isSaved(property),
                        onToggleSave: { appVM.toggleSaved(property) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.md) {
            NomadSectionHeader(title: "Featured", subtitle: "Hand-picked homes")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NomadSpacing.sm) {
                    ForEach(featuredProperties) { property in
                        Button {
                            selectedProperty = property
                        } label: {
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
}

nonisolated enum SortOption: String, CaseIterable, Sendable {
    case newest
    case priceLow
    case priceHigh
    case largest

    var title: String {
        switch self {
        case .newest: return "Newest"
        case .priceLow: return "Price Low"
        case .priceHigh: return "Price High"
        case .largest: return "Largest"
        }
    }
}

struct SaveSearchSheet: View {
    let appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var emailEnabled = true
    @State private var notifEnabled = true
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: NomadSpacing.xl) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(NomadColor.Accent.primary)
                    .padding(.top, NomadSpacing.sm)

                VStack(spacing: NomadSpacing.xs) {
                    Text("Don’t miss new listings")
                        .font(NomadTypography.title2)
                        .foregroundStyle(NomadColor.Text.primary)

                    Text("Choose how you want to hear about matching properties.")
                        .font(NomadTypography.body)
                        .foregroundStyle(NomadColor.Text.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 0) {
                    ToggleRow(title: "Email", subtitle: "Daily summary", isOn: $emailEnabled)
                    Divider().padding(.leading, NomadSpacing.md)
                    ToggleRow(title: "Notifications", subtitle: "Real-time alerts", isOn: $notifEnabled)
                }
                .nomadCardSurface(level: .level1, radius: NomadRadius.card)

                if showSuccess {
                    HStack(spacing: NomadSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Search saved")
                    }
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Background.surface)
                    .padding(.vertical, NomadSpacing.sm)
                    .frame(maxWidth: .infinity)
                    .background(NomadColor.Accent.primary, in: .capsule)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                NomadPrimaryCTA(title: "Confirm", icon: nil) {
                    appVM.savedSearchEmail = emailEnabled
                    appVM.savedSearchNotifications = notifEnabled
                    withAnimation { showSuccess = true }

                    Task {
                        try? await Task.sleep(for: .seconds(1.3))
                        dismiss()
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(NomadSpacing.pageHorizontal)
            .nomadScreenBackground()
            .navigationTitle("Save Search")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: NomadSpacing.xxs) {
                Text(title)
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Text.primary)
                Text(subtitle)
                    .font(NomadTypography.caption)
                    .foregroundStyle(NomadColor.Text.secondary)
            }
        }
        .tint(NomadColor.Accent.primary)
        .padding(.horizontal, NomadSpacing.md)
        .padding(.vertical, NomadSpacing.sm)
    }
}
