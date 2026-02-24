//
//  ExploreView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct ExploreView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var filter = PropertyFilter()
    @State private var searchText = ""
    @State private var showFilter = false
    @State private var showSearch = false
    @State private var showMap = false
    @State private var showSaveSearch = false
    @State private var selectedProperty: Property?
    @State private var sortOption: SortOption = .newest

    private var filteredProperties: [Property] {
        var results = appVM.database.filteredProperties(with: filter)
        if !searchText.isEmpty {
            results = results.filter {
                $0.city.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText) ||
                $0.region.localizedCaseInsensitiveContains(searchText)
            }
        }
        switch sortOption {
        case .newest: results.sort { $0.listingDate > $1.listingDate }
        case .priceLow: results.sort { $0.price < $1.price }
        case .priceHigh: results.sort { $0.price > $1.price }
        case .largest: results.sort { $0.squareFeet > $1.squareFeet }
        }
        return results
    }

    private var featuredProperties: [Property] {
        appVM.database.properties.filter { $0.isFeatured }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NomadTheme.offWhite.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        searchBarSection
                        resultsHeader
                        propertyList
                        featuredSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                }

                VStack {
                    Spacer()
                    mapButton
                }
            }
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
            .fullScreenCover(isPresented: $showMap) {
                MapExploreView(properties: filteredProperties, appVM: appVM)
            }
            .fullScreenCover(item: $selectedProperty) { property in
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(NomadTheme.greeting)
                .font(.title.bold())
                .foregroundStyle(NomadTheme.darkText)
                .padding(.top, 8)
        }
    }

    private var searchBarSection: some View {
        HStack(spacing: 10) {
            Button { showSearch = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(NomadTheme.lightGrey)
                    Text("Search by region, city, street...")
                        .font(.subheadline)
                        .foregroundStyle(NomadTheme.lightGrey)
                    Spacer()
                }
                .padding(16)
                .background(.white, in: .capsule)
                .shadow(color: .black.opacity(0.08), radius: NomadTheme.cardShadow, y: 10)
            }

            Button { showFilter = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .foregroundStyle(filter.isActive ? .white : NomadTheme.darkText)
                    .frame(width: 52, height: 52)
                    .background(filter.isActive ? NomadTheme.darkGreen : .white, in: .circle)
                    .shadow(color: .black.opacity(0.08), radius: NomadTheme.cardShadow, y: 10)
            }
        }
    }

    private var resultsHeader: some View {
        HStack {
            Text("\(filteredProperties.count) properties for \(filter.listingType.rawValue.lowercased())")
                .font(.subheadline)
                .foregroundStyle(NomadTheme.lightGrey)

            Spacer()

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
                HStack(spacing: 4) {
                    Text(sortOption.title)
                        .font(.caption.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundStyle(NomadTheme.darkText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.white, in: .capsule)
            }
        }
    }

    private var propertyList: some View {
        LazyVStack(spacing: 16) {
            ForEach(filteredProperties) { property in
                Button {
                    selectedProperty = property
                } label: {
                    PropertyCardView(
                        property: property,
                        isSaved: appVM.isSaved(property),
                        onToggleSave: { appVM.toggleSaved(property) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured")
                .font(.title3.bold())
                .foregroundStyle(NomadTheme.darkText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(featuredProperties) { property in
                        Button {
                            selectedProperty = property
                        } label: {
                            FeaturedCard(property: property)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }

    private var mapButton: some View {
        Button { showMap = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                Text("View map")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(.black, in: .capsule)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
        .padding(.bottom, 16)
    }
}

nonisolated enum SortOption: String, CaseIterable, Sendable {
    case newest, priceLow, priceHigh, largest

    var title: String {
        switch self {
        case .newest: return "Newest"
        case .priceLow: return "Price: Low to High"
        case .priceHigh: return "Price: High to Low"
        case .largest: return "Largest"
        }
    }
}

struct FeaturedCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color(.secondarySystemBackground)
                .frame(width: 200, height: 140)
                .overlay {
                    AsyncImage(url: URL(string: property.imageURLs.first ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                        } else {
                            ProgressView()
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: 20))

            Text(property.fullFormattedPrice)
                .font(.subheadline.bold())
                .foregroundStyle(NomadTheme.darkText)

            Text(property.city)
                .font(.caption)
                .foregroundStyle(NomadTheme.lightGrey)

            HStack(spacing: 8) {
                if property.bedrooms > 0 { SpecItem(icon: "bed.double.fill", value: "\(property.bedrooms)") }
                if property.bathrooms > 0 { SpecItem(icon: "shower.fill", value: "\(property.bathrooms)") }
            }
        }
        .frame(width: 200)
        .padding(10)
        .background(.white, in: .rect(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
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
            VStack(spacing: 24) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(NomadTheme.darkGreen)
                    .padding(.top, 16)

                Text("Don't miss any new listings!")
                    .font(.title3.bold())
                    .foregroundStyle(NomadTheme.darkText)

                VStack(spacing: 0) {
                    Toggle(isOn: $emailEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Email")
                                .font(.body.weight(.medium))
                            Text("Daily summary")
                                .font(.caption)
                                .foregroundStyle(NomadTheme.lightGrey)
                        }
                    }
                    .tint(NomadTheme.darkGreen)
                    .padding(16)

                    Divider()

                    Toggle(isOn: $notifEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Notifications")
                                .font(.body.weight(.medium))
                            Text("Real-time")
                                .font(.caption)
                                .foregroundStyle(NomadTheme.lightGrey)
                        }
                    }
                    .tint(NomadTheme.darkGreen)
                    .padding(16)
                }
                .background(.white, in: .rect(cornerRadius: 16))

                if showSuccess {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("The search was saved.")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(NomadTheme.darkGreen, in: .capsule)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button {
                    appVM.savedSearchEmail = emailEnabled
                    appVM.savedSearchNotifications = notifEnabled
                    withAnimation { showSuccess = true }
                    Task {
                        try? await Task.sleep(for: .seconds(1.5))
                        dismiss()
                    }
                } label: {
                    Text("Confirm your choices")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle())

                Spacer()
            }
            .padding(24)
            .background(NomadTheme.offWhite)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(NomadTheme.darkText)
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
