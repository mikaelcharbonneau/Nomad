//
//  CreateListingView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//

import SwiftUI
import PhotosUI
import UIKit
import CoreLocation
import MapKit

struct CreateListingView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(\.dismiss) private var dismiss

    @State private var path: [ListingFlowStep] = []
    @State private var model = ListingFlowModel()
    @State private var addressSearch = AddressSearchService()
    @State private var errorMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack(path: $path) {
            ListingTypeStepView(model: model) {
                path.append(.media)
            }
            .navigationDestination(for: ListingFlowStep.self) { step in
                switch step {
                case .media:
                    MediaStepView(model: model) {
                        path.append(model.listingType == .rent ? .rentProperty : .sellPropertyBasics)
                    }

                case .sellPropertyBasics:
                    SellPropertyBasicsStepView(model: model, addressSearch: addressSearch) {
                        path.append(.sellPropertyDetails)
                    }

                case .sellPropertyDetails:
                    SellPropertyDetailsStepView(model: model) {
                        path.append(.sellPropertyFeatures)
                    }

                case .sellPropertyFeatures:
                    SellPropertyFeaturesStepView(model: model) {
                        path.append(.sellPricing)
                    }

                case .sellPricing:
                    SellPricingStepView(model: model) {
                        path.append(.sellListingDetails)
                    }

                case .sellListingDetails:
                    SellListingDetailsStepView(model: model) {
                        path.append(.review)
                    }

                case .rentProperty:
                    RentPropertyStepView(model: model, addressSearch: addressSearch) {
                        path.append(.rentLease)
                    }

                case .rentLease:
                    RentLeaseStepView(model: model) {
                        path.append(.rentPolicies)
                    }

                case .rentPolicies:
                    RentPoliciesStepView(model: model) {
                        path.append(.rentAmenities)
                    }

                case .rentAmenities:
                    RentAmenitiesStepView(model: model) {
                        path.append(.rentListedBy)
                    }

                case .rentListedBy:
                    RentListedByStepView(model: model) {
                        path.append(.review)
                    }

                case .review:
                    ReviewStepView(model: model, errorMessage: $errorMessage, isSubmitting: $isSubmitting) {
                        Task { await submitListing() }
                    }
                }
            }
            .navigationTitle("New Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func submitListing() async {
        errorMessage = nil
        isSubmitting = true
        do {
            let draft = try await model.buildDraft()
            try await appVM.listingsService.createListing(draft: draft, photoData: model.photoData)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}

enum ListingFlowStep: Hashable {
    case media
    case sellPropertyBasics
    case sellPropertyDetails
    case sellPropertyFeatures
    case sellPricing
    case sellListingDetails
    case rentProperty
    case rentLease
    case rentPolicies
    case rentAmenities
    case rentListedBy
    case review
}

@MainActor
@Observable
class ListingFlowModel {
    var listingType: ListingType = .sale

    var photoItems: [PhotosPickerItem] = []
    var photoData: [Data] = []
    var photoPreviews: [UIImage] = []

    var address = ""
    var city = ""
    var region = ""
    var country = ""
    var selectedCoordinate: CLLocationCoordinate2D?

    var sellPropertyType: SellPropertyType = .house
    var sellBedrooms = "1"
    var sellBathrooms = "1"
    var sellSquareFeet = ""
    var sellLotSize = ""
    var sellYearBuilt = ""
    var sellHasPool = false
    var sellHasElevator = false
    var sellIsWaterfront = false
    var sellHasGarage = false
    var sellPrice = ""
    var sellMonthlyTaxes = ""
    var sellCondoFees = ""
    var sellMoveInDate = Date()
    var sellStatus: ListingStatus = .published
    var sellListedBy: ListedByOption = .owner
    var sellTitle = ""
    var sellDescription = ""
    var sellOwnerComments = ""

    var rentPropertyType = "Apartment"
    var rentBedrooms = "1"
    var rentBathrooms = "1"
    var rentSquareFeet = ""
    var rentAmount = ""
    var rentOffer = ""
    var availabilityStart = Date()
    var availabilityEnd = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    var rentPolicies: Set<String> = []
    var laundryOptions: Set<String> = []
    var coolingOptions: Set<String> = []
    var heatingOptions: Set<String> = []
    var applianceOptions: Set<String> = []
    var furnitureOption = "Not furnished"
    var parkingOptions: Set<String> = []
    var commodityOptions: Set<String> = []
    var otherAmenities: Set<String> = []
    var rentListedBy: ListedByOption = .owner

    private let geocoder = CLGeocoder()

    func loadPhotos() async {
        photoData.removeAll()
        photoPreviews.removeAll()
        for item in photoItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                photoData.append(data)
                if let image = UIImage(data: data) {
                    photoPreviews.append(image)
                }
            }
        }
    }

    func applyCompletion(_ completion: MKLocalSearchCompletion) async throws {
        let request = MKLocalSearch.Request(completion: completion)
        let response = try await MKLocalSearch(request: request).start()
        if let item = response.mapItems.first {
            let placemark = item.placemark
            address = [placemark.subThoroughfare, placemark.thoroughfare]
                .compactMap { $0 }
                .joined(separator: " ")
            city = placemark.locality ?? city
            region = placemark.administrativeArea ?? region
            country = placemark.country ?? country
            if let coordinate = placemark.location?.coordinate {
                selectedCoordinate = coordinate
            }
        }
    }

    func buildDraft() async throws -> ListingDraft {
        if photoData.isEmpty { throw ListingFlowError.missingPhotos }
        if address.trimmingCharacters(in: .whitespaces).isEmpty { throw ListingFlowError.missingAddress }
        if city.trimmingCharacters(in: .whitespaces).isEmpty { throw ListingFlowError.missingCity }
        if region.trimmingCharacters(in: .whitespaces).isEmpty { throw ListingFlowError.missingRegion }

        let coordinates = try await resolveCoordinates()

        switch listingType {
        case .sale:
            guard let priceValue = Int(sellPrice) else { throw ListingFlowError.invalidPrice }
            let title = sellTitle.trimmingCharacters(in: .whitespaces).isEmpty
                ? sellPropertyType.rawValue + " in " + city
                : sellTitle
            let squareFeet = Int(sellSquareFeet) ?? 0
            let lotSize = Int(sellLotSize) ?? 0
            let yearBuilt = Int(sellYearBuilt) ?? 0
            let bedrooms = parseCount(sellBedrooms)
            let bathrooms = parseCount(sellBathrooms)
            let taxes = Int(sellMonthlyTaxes) ?? 0
            let condoFees = Int(sellCondoFees) ?? 0
            let propertyType = sellPropertyType.propertyType

            return ListingDraft(
                title: title,
                price: priceValue,
                address: address,
                city: city,
                region: region,
                country: country,
                listingType: .sale,
                propertyType: propertyType,
                bedrooms: sellPropertyType.isLot ? 0 : bedrooms,
                bathrooms: sellPropertyType.isLot ? 0 : bathrooms,
                squareFeet: sellPropertyType.isLot ? 0 : squareFeet,
                lotSize: lotSize,
                levels: 1,
                yearBuilt: sellPropertyType.isLot ? 0 : yearBuilt,
                description: sellDescription,
                ownerComments: sellOwnerComments,
                features: sellFeatures(),
                hasPool: sellHasPool,
                hasElevator: sellHasElevator,
                isWaterfront: sellIsWaterfront,
                isPetFriendly: false,
                moveInDate: sellMoveInDate,
                monthlyTaxes: taxes,
                monthlyElectricity: 0,
                monthlyCondoFees: sellPropertyType == .condo ? condoFees : 0,
                parkingSpaces: 0,
                garages: sellHasGarage ? 1 : 0,
                constructionType: .detached,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                status: sellStatus.rawValue.lowercased(),
                listedBy: sellListedBy.rawValue
            )

        case .rent:
            guard let rentValue = Int(rentAmount) else { throw ListingFlowError.invalidPrice }
            let title = rentPropertyType + " in " + city
            let bedrooms = parseCount(rentBedrooms)
            let bathrooms = parseCount(rentBathrooms)
            let squareFeet = Int(rentSquareFeet) ?? 0
            let propertyType = mapRentPropertyType(rentPropertyType)

            return ListingDraft(
                title: title,
                price: rentValue,
                address: address,
                city: city,
                region: region,
                country: country,
                listingType: .rent,
                propertyType: propertyType,
                bedrooms: bedrooms,
                bathrooms: bathrooms,
                squareFeet: squareFeet,
                lotSize: 0,
                levels: 1,
                yearBuilt: 0,
                description: "",
                ownerComments: "",
                features: rentFeatures(),
                hasPool: commodityOptions.contains("Pool"),
                hasElevator: false,
                isWaterfront: false,
                isPetFriendly: rentPolicies.contains("Cats Allowed") || rentPolicies.contains("Dogs Allowed"),
                moveInDate: availabilityStart,
                monthlyTaxes: 0,
                monthlyElectricity: 0,
                monthlyCondoFees: 0,
                parkingSpaces: 0,
                garages: 0,
                constructionType: .detached,
                latitude: coordinates.latitude,
                longitude: coordinates.longitude,
                status: "published",
                listedBy: rentListedBy.rawValue
            )
        }
    }

    private func resolveCoordinates() async throws -> CLLocationCoordinate2D {
        if let selectedCoordinate { return selectedCoordinate }
        let fullAddress = [address, city, region, country]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        let matches = try await geocoder.geocodeAddressString(fullAddress)
        if let location = matches.first?.location {
            return location.coordinate
        }
        throw ListingFlowError.invalidAddress
    }

    private func sellFeatures() -> [String: String] {
        var features: [String: String] = [:]
        if sellPropertyType.isPlex { features["Plex type"] = sellPropertyType.rawValue }
        features["Listed by"] = sellListedBy.rawValue
        return features
    }

    private func rentFeatures() -> [String: String] {
        var features: [String: String] = [:]
        if !rentOffer.trimmingCharacters(in: .whitespaces).isEmpty {
            features["Rent offer"] = rentOffer
        }
        features["Availability start"] = formattedDate(availabilityStart)
        features["Availability end"] = formattedDate(availabilityEnd)
        features["Listed by"] = rentListedBy.rawValue
        features["Furniture"] = furnitureOption

        addFeature("Policies", values: rentPolicies, to: &features)
        addFeature("Laundry", values: laundryOptions, to: &features)
        addFeature("Cooling", values: coolingOptions, to: &features)
        addFeature("Heating", values: heatingOptions, to: &features)
        addFeature("Appliances", values: applianceOptions, to: &features)
        addFeature("Parking", values: parkingOptions, to: &features)
        addFeature("Commodities", values: commodityOptions, to: &features)
        addFeature("Other", values: otherAmenities, to: &features)

        return features
    }

    private func addFeature(_ key: String, values: Set<String>, to features: inout [String: String]) {
        if !values.isEmpty {
            features[key] = values.sorted().joined(separator: ", ")
        }
    }

    private func parseCount(_ value: String) -> Int {
        if value.contains("+") {
            return Int(value.replacingOccurrences(of: "+", with: "")) ?? 0
        }
        return Int(value) ?? 0
    }

    private func mapRentPropertyType(_ value: String) -> PropertyType {
        switch value.lowercased() {
        case "apartment":
            return .condo
        case "room":
            return .loft
        case "townhouse":
            return .house
        default:
            return .house
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

enum ListingFlowError: LocalizedError {
    case missingPhotos
    case missingAddress
    case missingCity
    case missingRegion
    case invalidPrice
    case invalidAddress

    var errorDescription: String? {
        switch self {
        case .missingPhotos: return "Please add at least one photo."
        case .missingAddress: return "Please enter an address."
        case .missingCity: return "Please enter a city."
        case .missingRegion: return "Please enter a region/state."
        case .invalidPrice: return "Please enter a valid price."
        case .invalidAddress: return "We couldn't locate that address."
        }
    }
}

enum SellPropertyType: String, CaseIterable {
    case house = "House"
    case condo = "Condo"
    case townhouse = "Townhouse"
    case duplex = "Duplex"
    case triplex = "Triplex"
    case quadruplex = "Quadruplex"
    case quintuplex = "Quintuplex+"
    case cottage = "Cottage"
    case lotLand = "Lot / Land"

    var isLot: Bool { self == .lotLand }
    var isPlex: Bool { self == .duplex || self == .triplex || self == .quadruplex || self == .quintuplex }

    var propertyType: PropertyType {
        switch self {
        case .condo:
            return .condo
        case .cottage:
            return .cottage
        case .lotLand:
            return .lot
        case .duplex, .triplex, .quadruplex, .quintuplex:
            return .plex
        default:
            return .house
        }
    }
}

enum ListingStatus: String, CaseIterable {
    case published = "Published"
    case draft = "Draft"
}

enum ListedByOption: String, CaseIterable {
    case owner = "Owner"
    case agent = "Agent"
    case company = "Company"
}

struct ListingTypeStepView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let splitY = proxy.size.height * 0.54
            let safeTop = proxy.safeAreaInsets.top

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    sellPanel
                        .frame(height: splitY)

                    Rectangle()
                        .fill(Color.white.opacity(0.9))
                        .frame(height: 1)

                    rentPanel
                        .frame(maxHeight: .infinity)
                }

                header(safeTop: safeTop)

                Circle()
                    .fill(.white)
                    .frame(width: 78, height: 78)
                    .shadow(color: .black.opacity(0.14), radius: 14, y: 7)
                    .overlay {
                        Text("OR")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(red: 17 / 255, green: 38 / 255, blue: 39 / 255))
                    }
                    .offset(y: splitY - 39)
            }
            .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var sellPanel: some View {
        ZStack {
            sellBackground

            VStack(spacing: 16) {
                Spacer(minLength: 104)

                sellIcon
                    .padding(.bottom, 2)
                    .foregroundStyle(.white.opacity(0.92))

                Text("Sell")
                    .font(.custom("Times New Roman", size: 58))
                    .italic()
                    .foregroundStyle(.white.opacity(0.96))
                    .minimumScaleFactor(0.7)

                Text("Maximize your property's potential\nvalue with our experts.")
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 300)
                    .foregroundStyle(.white.opacity(0.84))
                    .padding(.horizontal, 28)

                Button {
                    choose(.sale)
                } label: {
                    Text("SELECT")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                        .frame(width: 196, height: 48)
                        .background(.clear, in: .capsule)
                        .overlay {
                            Capsule()
                                .stroke(.white.opacity(0.4), lineWidth: 1.6)
                        }
                }
                .buttonStyle(.plain)

                Spacer(minLength: 56)
            }
        }
    }

    private var rentPanel: some View {
        ZStack {
            rentBackground

            VStack(spacing: 18) {
                Spacer(minLength: 72)

                Button {
                    choose(.rent)
                } label: {
                    Text("SELECT")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(red: 17 / 255, green: 38 / 255, blue: 39 / 255))
                        .frame(width: 196, height: 48)
                        .background(.clear, in: .capsule)
                        .overlay {
                            Capsule()
                                .stroke(Color(red: 17 / 255, green: 38 / 255, blue: 39 / 255).opacity(0.26), lineWidth: 1.6)
                        }
                }
                .buttonStyle(.plain)

                Text("Find your perfect temporary\nsanctuary in the city.")
                    .font(.system(size: 15, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 300)
                    .foregroundStyle(Color(red: 17 / 255, green: 38 / 255, blue: 39 / 255).opacity(0.78))
                    .padding(.horizontal, 26)
                    .padding(.top, 14)

                Text("Rent")
                    .font(.custom("Times New Roman", size: 62))
                    .italic()
                    .foregroundStyle(Color(red: 17 / 255, green: 38 / 255, blue: 39 / 255))
                    .minimumScaleFactor(0.7)

                Image(systemName: "key.horizontal")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(Color(red: 17 / 255, green: 38 / 255, blue: 39 / 255).opacity(0.78))

                Spacer(minLength: 40)
            }
        }
    }

    private var sellBackground: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 5 / 255, green: 40 / 255, blue: 42 / 255),
                        Color(red: 2 / 255, green: 28 / 255, blue: 32 / 255),
                        Color(red: 1 / 255, green: 19 / 255, blue: 25 / 255)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.22))
                    .frame(width: width * 0.16, height: height * 0.7)
                    .overlay(alignment: .top) {
                        VStack(spacing: 0) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.06))
                                    .frame(height: 1)
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.vertical, 22)
                    }
                    .position(x: width * 0.5, y: height * 0.52)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(width: width * 0.22, height: height * 0.36)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.white.opacity(0.08), lineWidth: 2)
                            .padding(10)
                    }
                    .position(x: width * 0.18, y: height * 0.66)

                HStack(spacing: 5) {
                    ForEach(0..<6, id: \.self) { idx in
                        Rectangle()
                            .fill(Color.black.opacity(idx < 2 ? 0.2 : 0.32))
                            .frame(width: 5)
                    }
                }
                .frame(height: height * 0.78)
                .position(x: width * 0.84, y: height * 0.52)

                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.1),
                        Color.black.opacity(0.36)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var rentBackground: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 247 / 255, green: 248 / 255, blue: 245 / 255),
                        Color(red: 241 / 255, green: 243 / 255, blue: 238 / 255)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(spacing: width * 0.025) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.42))
                        .frame(width: width * 0.32, height: height * 0.32)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.5))
                        .frame(width: width * 0.35, height: height * 0.42)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.46))
                        .frame(width: width * 0.14, height: height * 0.36)
                }
                .position(x: width * 0.48, y: height * 0.62)

                Ellipse()
                    .fill(Color(red: 214 / 255, green: 223 / 255, blue: 214 / 255).opacity(0.48))
                    .frame(width: width * 0.22, height: width * 0.12)
                    .position(x: width * 0.1, y: height * 0.72)

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.22),
                        Color(red: 237 / 255, green: 238 / 255, blue: 232 / 255).opacity(0.66)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var sellIcon: some View {
        ZStack(alignment: .bottom) {
            Image(systemName: "house")
                .font(.system(size: 48, weight: .regular))
            Image(systemName: "hand.raised")
                .font(.system(size: 30, weight: .regular))
                .offset(y: 15)
        }
    }

    private func header(safeTop: CGFloat) -> some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white.opacity(0.94))
                    .frame(width: 56, height: 56)
                    .background(.white.opacity(0.1), in: .circle)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.22), lineWidth: 1.6)
                    }
            }
            .buttonStyle(.plain)

            Spacer()

            Text("NOMAD")
                .font(.system(size: 21, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()

            Color.clear
                .frame(width: 56, height: 56)
        }
        .padding(.horizontal, 20)
        .padding(.top, safeTop + 8)
    }

    private func choose(_ listingType: ListingType) {
        model.listingType = listingType
        onNext()
    }
}

struct MediaStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Media", onNext: onNext, progress: .media) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Photos")

                PhotosPicker(selection: $model.photoItems, maxSelectionCount: 10, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle")
                        Text("Add photos")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(NomadTheme.darkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white, in: .capsule)
                }

                if !model.photoPreviews.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(model.photoPreviews.indices, id: \.self) { index in
                                Image(uiImage: model.photoPreviews[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 80)
                                    .clipShape(.rect(cornerRadius: 12))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .contentMargins(.horizontal, 0)
                }
            }
        }
        .onChange(of: model.photoItems) { _, _ in
            Task { await model.loadPhotos() }
        }
    }
}

struct SellPropertyBasicsStepView: View {
    @Bindable var model: ListingFlowModel
    @Bindable var addressSearch: AddressSearchService
    @FocusState private var isAddressFocused: Bool
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Property Basics", onNext: onNext, progress: .sellPropertyBasics) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(title: "Property Type")

                PillWrap(items: SellPropertyType.allCases, selection: $model.sellPropertyType)

                AddressSection(
                    address: $model.address,
                    city: $model.city,
                    region: $model.region,
                    country: $model.country,
                    addressSearch: addressSearch,
                    isAddressFocused: $isAddressFocused,
                    onSelect: { completion in
                        Task { try? await model.applyCompletion(completion) }
                    }
                )
            }
        }
        .onChange(of: model.address) { _, newValue in
            addressSearch.update(query: newValue)
        }
    }
}

struct SellPropertyDetailsStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Property Details", onNext: onNext, progress: .sellPropertyDetails) {
            VStack(alignment: .leading, spacing: 16) {
                if !model.sellPropertyType.isLot {
                    SectionHeader(title: "Bedrooms")
                    PillStringWrap(items: ["1", "2", "3", "4", "5+"], selection: $model.sellBedrooms)

                    SectionHeader(title: "Bathrooms")
                    PillStringWrap(items: ["1", "2", "3", "4", "5+"], selection: $model.sellBathrooms)

                    TextField("Square footage", text: $model.sellSquareFeet)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(.white, in: .rect(cornerRadius: 12))
                        .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                    TextField("Year built", text: $model.sellYearBuilt)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(.white, in: .rect(cornerRadius: 12))
                        .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }
                }

                TextField("Lot size", text: $model.sellLotSize)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }
            }
        }
    }
}

struct SellPropertyFeaturesStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Property Features", onNext: onNext, progress: .sellPropertyFeatures) {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Pool", isOn: $model.sellHasPool)
                    .tint(NomadTheme.darkGreen)

                if model.sellPropertyType == .condo {
                    Toggle("Elevator", isOn: $model.sellHasElevator)
                        .tint(NomadTheme.darkGreen)
                }

                Toggle("Waterfront", isOn: $model.sellIsWaterfront)
                    .tint(NomadTheme.darkGreen)

                if !model.sellPropertyType.isLot {
                    Toggle("Garage", isOn: $model.sellHasGarage)
                        .tint(NomadTheme.darkGreen)
                }
            }
            .padding(12)
            .background(.white, in: .rect(cornerRadius: 12))
        }
    }
}

struct SellPricingStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Pricing & Financials", onNext: onNext, progress: .sellPricing) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Listing price", text: $model.sellPrice)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                TextField("Monthly taxes", text: $model.sellMonthlyTaxes)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                if model.sellPropertyType == .condo {
                    TextField("Condo fees", text: $model.sellCondoFees)
                        .keyboardType(.numberPad)
                        .padding(12)
                        .background(.white, in: .rect(cornerRadius: 12))
                        .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }
                }
            }
        }
    }
}

struct SellListingDetailsStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Listing Details", onNext: onNext, progress: .sellListingDetails) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Title", text: $model.sellTitle)
                    .textInputAutocapitalization(.words)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                TextEditor(text: $model.sellDescription)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                TextEditor(text: $model.sellOwnerComments)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                DatePicker("Move-in date", selection: $model.sellMoveInDate, displayedComponents: .date)
                    .datePickerStyle(.compact)

                Picker("Status", selection: $model.sellStatus) {
                    ForEach(ListingStatus.allCases, id: \.self) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
                .pickerStyle(.segmented)

                Picker("Listed by", selection: $model.sellListedBy) {
                    ForEach(ListedByOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 12))
            }
        }
    }
}

struct RentPropertyStepView: View {
    @Bindable var model: ListingFlowModel
    @Bindable var addressSearch: AddressSearchService
    @FocusState private var isAddressFocused: Bool
    let onNext: () -> Void

    private let rentPropertyTypes = ["Apartment", "Room", "House", "Townhouse"]

    var body: some View {
        StepContainer(title: "Property", onNext: onNext, progress: .rentProperty) {
            VStack(alignment: .leading, spacing: 16) {
                AddressSection(
                    address: $model.address,
                    city: $model.city,
                    region: $model.region,
                    country: $model.country,
                    addressSearch: addressSearch,
                    isAddressFocused: $isAddressFocused,
                    onSelect: { completion in
                        Task { try? await model.applyCompletion(completion) }
                    }
                )

                SectionHeader(title: "Property Type")
                PillStringWrap(items: rentPropertyTypes, selection: $model.rentPropertyType)

                SectionHeader(title: "Bedrooms")
                PillStringWrap(items: ["1", "2", "3", "4", "5+"], selection: $model.rentBedrooms)

                SectionHeader(title: "Bathrooms")
                PillStringWrap(items: ["1", "2", "3", "4", "5+"], selection: $model.rentBathrooms)

                TextField("Square footage", text: $model.rentSquareFeet)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }
            }
        }
        .onChange(of: model.address) { _, newValue in
            addressSearch.update(query: newValue)
        }
    }
}

struct RentLeaseStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Lease Info", onNext: onNext, progress: .rentLease) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Rent Amount", text: $model.rentAmount)
                    .keyboardType(.numberPad)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                TextField("Rent Offer", text: $model.rentOffer)
                    .padding(12)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

                DatePicker("Availability start", selection: $model.availabilityStart, displayedComponents: .date)
                    .datePickerStyle(.compact)
                DatePicker("Availability end", selection: $model.availabilityEnd, displayedComponents: .date)
                    .datePickerStyle(.compact)
            }
        }
    }
}

struct RentPoliciesStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Policies", onNext: onNext, progress: .rentPolicies) {
            VStack(alignment: .leading, spacing: 8) {
                policyToggle("Cats Allowed")
                policyToggle("Dogs Allowed")
                policyToggle("Smoking Allowed")
            }
            .padding(12)
            .background(.white, in: .rect(cornerRadius: 12))
        }
    }

    private func policyToggle(_ title: String) -> some View {
        Toggle(title, isOn: bindingForOption(title))
            .tint(NomadTheme.darkGreen)
    }

    private func bindingForOption(_ option: String) -> Binding<Bool> {
        Binding(
            get: { model.rentPolicies.contains(option) },
            set: { isSelected in
                if isSelected {
                    model.rentPolicies.insert(option)
                } else {
                    model.rentPolicies.remove(option)
                }
            }
        )
    }
}

struct RentAmenitiesStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    private let laundryChoices = ["Washer-dryer included", "Shared or in building", "No laundry facilities"]
    private let coolingChoices = ["Central", "Wall", "Window"]
    private let heatingChoices = ["Baseboard", "Forced Air", "Heat pump", "Wall"]
    private let applianceChoices = ["Dishwasher", "Freezer", "Microwave", "Oven", "Refrigerator"]
    private let parkingChoices = ["Interior", "Exterior"]
    private let commodityChoices = ["Pool", "Gym"]
    private let otherAmenityChoices = ["Bicycle storage", "EV charging station", "Locker"]

    var body: some View {
        StepContainer(title: "Amenities", onNext: onNext, progress: .rentAmenities) {
            VStack(alignment: .leading, spacing: 12) {
                amenityGroup(title: "Laundry", options: laundryChoices, selection: $model.laundryOptions)
                amenityGroup(title: "Cooling", options: coolingChoices, selection: $model.coolingOptions)
                amenityGroup(title: "Heating", options: heatingChoices, selection: $model.heatingOptions)
                amenityGroup(title: "Appliances", options: applianceChoices, selection: $model.applianceOptions)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Furniture")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NomadTheme.darkText)
                    Picker("Furniture", selection: $model.furnitureOption) {
                        Text("Furnished").tag("Furnished")
                        Text("Not furnished").tag("Not furnished")
                    }
                    .pickerStyle(.segmented)
                }
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 12))

                amenityGroup(title: "Parking", options: parkingChoices, selection: $model.parkingOptions)
                amenityGroup(title: "Commodities", options: commodityChoices, selection: $model.commodityOptions)
                amenityGroup(title: "Other", options: otherAmenityChoices, selection: $model.otherAmenities)
            }
        }
    }

    private func amenityGroup(title: String, options: [String], selection: Binding<Set<String>>) -> some View {
        DisclosureGroup(title) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Toggle(option, isOn: bindingForOption(option, in: selection))
                        .tint(NomadTheme.darkGreen)
                }
            }
            .padding(.top, 8)
        }
        .padding(12)
        .background(.white, in: .rect(cornerRadius: 12))
    }

    private func bindingForOption(_ option: String, in selection: Binding<Set<String>>) -> Binding<Bool> {
        Binding(
            get: { selection.wrappedValue.contains(option) },
            set: { isSelected in
                if isSelected {
                    selection.wrappedValue.insert(option)
                } else {
                    selection.wrappedValue.remove(option)
                }
            }
        )
    }
}

struct RentListedByStepView: View {
    @Bindable var model: ListingFlowModel
    let onNext: () -> Void

    var body: some View {
        StepContainer(title: "Listed By", onNext: onNext, progress: .rentListedBy) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Listed by", selection: $model.rentListedBy) {
                    ForEach(ListedByOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 12))
            }
        }
    }
}

struct ReviewStepView: View {
    @Bindable var model: ListingFlowModel
    @Binding var errorMessage: String?
    @Binding var isSubmitting: Bool
    let onSubmit: () -> Void

    var body: some View {
        StepContainer(title: "Review & Publish", onNext: onSubmit, progress: .review, nextTitle: isSubmitting ? "Publishing..." : "Publish listing", disableNext: isSubmitting) {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Summary")

                summaryRow("Type", value: model.listingType.rawValue)
                summaryRow("Address", value: model.address)
                summaryRow("City", value: model.city)
                summaryRow("Region", value: model.region)
                summaryRow("Country", value: model.country)

                if model.listingType == .sale {
                    summaryRow("Property", value: model.sellPropertyType.rawValue)
                    summaryRow("Price", value: model.sellPrice)
                } else {
                    summaryRow("Property", value: model.rentPropertyType)
                    summaryRow("Rent", value: model.rentAmount)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(NomadTheme.lightGrey)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NomadTheme.darkText)
        }
        .padding(12)
        .background(.white, in: .rect(cornerRadius: 12))
    }
}

struct StepContainer<Content: View>: View {
    let title: String
    let onNext: () -> Void
    let progress: ListingFlowProgress
    var nextTitle: String = "Continue"
    var disableNext = false
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(NomadTheme.darkText)

                ProgressIndicator(progress: progress)

                content

                Button(action: onNext) {
                    Text(nextTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle())
                .disabled(disableNext)
                .opacity(disableNext ? 0.6 : 1)
            }
            .padding(20)
        }
        .background(NomadTheme.offWhite)
        .toolbar(.visible, for: .navigationBar)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(NomadTheme.darkText)
            Divider()
        }
    }
}

struct ProgressIndicator: View {
    let progress: ListingFlowProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(progress.stepNumber) of \(progress.totalSteps)")
                .font(.caption)
                .foregroundStyle(NomadTheme.lightGrey)

            GeometryReader { geometry in
                let width = geometry.size.width * progress.fraction
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.separator))
                        .frame(height: 6)
                    Capsule()
                        .fill(NomadTheme.darkGreen)
                        .frame(width: max(6, width), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

struct ListingFlowProgress {
    let stepNumber: Int
    let totalSteps: Int

    var fraction: CGFloat {
        CGFloat(stepNumber) / CGFloat(totalSteps)
    }

    static let listingType = ListingFlowProgress(stepNumber: 1, totalSteps: 8)
    static let media = ListingFlowProgress(stepNumber: 2, totalSteps: 8)
    static let sellPropertyBasics = ListingFlowProgress(stepNumber: 3, totalSteps: 8)
    static let sellPropertyDetails = ListingFlowProgress(stepNumber: 4, totalSteps: 8)
    static let sellPropertyFeatures = ListingFlowProgress(stepNumber: 5, totalSteps: 8)
    static let sellPricing = ListingFlowProgress(stepNumber: 6, totalSteps: 8)
    static let sellListingDetails = ListingFlowProgress(stepNumber: 7, totalSteps: 8)
    static let rentProperty = ListingFlowProgress(stepNumber: 3, totalSteps: 8)
    static let rentLease = ListingFlowProgress(stepNumber: 4, totalSteps: 8)
    static let rentPolicies = ListingFlowProgress(stepNumber: 5, totalSteps: 8)
    static let rentAmenities = ListingFlowProgress(stepNumber: 6, totalSteps: 8)
    static let rentListedBy = ListingFlowProgress(stepNumber: 7, totalSteps: 8)
    static let review = ListingFlowProgress(stepNumber: 8, totalSteps: 8)
}

struct AddressSection: View {
    @Binding var address: String
    @Binding var city: String
    @Binding var region: String
    @Binding var country: String
    @Bindable var addressSearch: AddressSearchService
    @FocusState.Binding var isAddressFocused: Bool
    let onSelect: (MKLocalSearchCompletion) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Address", text: $address)
                .focused($isAddressFocused)
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

            let searchResults = addressSearch.results
            if isAddressFocused && !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults.indices, id: \.self) { index in
                        Button {
                            onSelect(searchResults[index])
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(searchResults[index].title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(NomadTheme.darkText)
                                if !searchResults[index].subtitle.isEmpty {
                                    Text(searchResults[index].subtitle)
                                        .font(.caption)
                                        .foregroundStyle(NomadTheme.lightGrey)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                        }
                        if index < searchResults.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(.white, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }
            }

            TextField("City", text: $city)
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

            TextField("Region/State", text: $region)
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }

            TextField("Country", text: $country)
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 12))
                .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }
        }
    }
}

struct PillWrap<T: Hashable & RawRepresentable>: View where T.RawValue == String {
    let items: [T]
    @Binding var selection: T

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(item.rawValue)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(selection == item ? .white : NomadTheme.darkText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selection == item ? NomadTheme.darkGreen : .white, in: .capsule)
                        .overlay { Capsule().stroke(selection == item ? .clear : Color(.separator), lineWidth: 1) }
                }
            }
        }
    }
}

struct PillStringWrap: View {
    let items: [String]
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    Text(item)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(selection == item ? .white : NomadTheme.darkText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(selection == item ? NomadTheme.darkGreen : .white, in: .capsule)
                        .overlay { Capsule().stroke(selection == item ? .clear : Color(.separator), lineWidth: 1) }
                }
            }
        }
    }
}

@MainActor
@Observable
class AddressSearchService: NSObject, MKLocalSearchCompleterDelegate {
    private let completer = MKLocalSearchCompleter()

    var results: [MKLocalSearchCompletion] = []

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        completer.queryFragment = trimmed
        if trimmed.isEmpty {
            results = []
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}
