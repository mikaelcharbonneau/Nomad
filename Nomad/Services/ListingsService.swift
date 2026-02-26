//
//  ListingsService.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@Observable
@MainActor
class ListingsService {
    static let shared = ListingsService()

    var properties: [Property] = []
    var isLoading = false
    var lastError: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {
        Task { await loadListings() }
    }

    func loadListings() async {
        isLoading = true
        lastError = nil
        do {
            let snapshot = try await db.collection("listings")
                .whereField("status", isEqualTo: "published")
                .getDocuments()
            properties = snapshot.documents.compactMap { Self.mapDocument($0) }
        } catch {
            lastError = error.localizedDescription
            properties = []
        }
        isLoading = false
    }

    func filteredProperties(with filter: PropertyFilter) -> [Property] {
        properties.filter { property in
            guard property.listingType == filter.listingType else { return false }

            if !filter.propertyTypes.isEmpty && !filter.propertyTypes.contains(property.propertyType) {
                return false
            }

            if let min = filter.minPrice, property.price < min { return false }
            if let max = filter.maxPrice, property.price > max { return false }

            if let beds = filter.bedrooms {
                let required = Int(beds.replacingOccurrences(of: "+", with: "")) ?? 0
                if beds.contains("+") {
                    if property.bedrooms < required { return false }
                } else {
                    if property.bedrooms != required { return false }
                }
            }

            if let baths = filter.bathrooms {
                let required = Int(baths.replacingOccurrences(of: "+", with: "")) ?? 0
                if property.bathrooms < required { return false }
            }

            if let parking = filter.parkingSpaces {
                let required = Int(parking.replacingOccurrences(of: "+", with: "")) ?? 0
                if property.parkingSpaces < required { return false }
            }

            if let garage = filter.garages {
                let required = Int(garage.replacingOccurrences(of: "+", with: "")) ?? 0
                if property.garages < required { return false }
            }

            if filter.hasPool && !property.hasPool { return false }
            if filter.hasElevator && !property.hasElevator { return false }
            if filter.isWaterfront && !property.isWaterfront { return false }
            if filter.isPetFriendly && !property.isPetFriendly { return false }

            if !filter.selectedCities.isEmpty && !filter.selectedCities.contains(property.city) {
                return false
            }

            if !filter.constructionTypes.isEmpty && !filter.constructionTypes.contains(property.constructionType) {
                return false }

            if let minYear = filter.minYear, property.yearBuilt > 0, property.yearBuilt < minYear { return false }
            if let maxYear = filter.maxYear, property.yearBuilt > 0, property.yearBuilt > maxYear { return false }

            if let minArea = filter.minLivingArea, property.squareFeet > 0, property.squareFeet < minArea { return false }
            if let maxArea = filter.maxLivingArea, property.squareFeet > 0, property.squareFeet > maxArea { return false }

            if let minLand = filter.minLandArea, property.lotSize > 0, property.lotSize < minLand { return false }
            if let maxLand = filter.maxLandArea, property.lotSize > 0, property.lotSize > maxLand { return false }

            return true
        }
    }

    func createListing(draft: ListingDraft, photoData: [Data]) async throws {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        var payload: [String: Any] = [
            "title": draft.title,
            "price": draft.price,
            "address": draft.address,
            "city": draft.city,
            "region": draft.region,
            "country": draft.country,
            "listingType": draft.listingType.rawValue.lowercased(),
            "propertyType": draft.propertyType.rawValue,
            "bedrooms": draft.bedrooms,
            "bathrooms": draft.bathrooms,
            "squareFeet": draft.squareFeet,
            "lotSize": draft.lotSize,
            "levels": draft.levels,
            "yearBuilt": draft.yearBuilt,
            "description": draft.description,
            "ownerComments": draft.ownerComments,
            "features": draft.features,
            "hasPool": draft.hasPool,
            "hasElevator": draft.hasElevator,
            "isWaterfront": draft.isWaterfront,
            "isPetFriendly": draft.isPetFriendly,
            "isFeatured": false,
            "listingDate": Timestamp(date: Date()),
            "moveInDate": Timestamp(date: draft.moveInDate),
            "monthlyTaxes": draft.monthlyTaxes,
            "monthlyElectricity": draft.monthlyElectricity,
            "monthlyCondoFees": draft.monthlyCondoFees,
            "parkingSpaces": draft.parkingSpaces,
            "garages": draft.garages,
            "constructionType": draft.constructionType.rawValue,
            "status": draft.status,
            "lat": draft.latitude,
            "lng": draft.longitude
        ]

        payload["listedBy"] = draft.listedBy

        if let ownerId = Auth.auth().currentUser?.uid {
            payload["ownerId"] = ownerId
        }

        let documentRef = try await db.collection("listings").addDocument(data: payload)

        if !photoData.isEmpty {
            let photoUrls = try await uploadPhotos(photoData, listingId: documentRef.documentID)
            if !photoUrls.isEmpty {
                try await documentRef.updateData(["photoUrls": photoUrls])
            }
        }


        await loadListings()
    }

    func seedSampleListings() async throws {
        let snapshot = try await db.collection("listings")
            .whereField("source", isEqualTo: "seed")
            .getDocuments()
        if snapshot.count >= 5 { return }

        let samples = SampleListingData.samples
        for sample in samples {
            var payload: [String: Any] = [
                "title": sample.title,
                "price": sample.price,
                "address": sample.address,
                "city": sample.city,
                "region": sample.region,
                "country": "Canada",
                "listingType": sample.listingType,
                "propertyType": sample.propertyType,
                "bedrooms": sample.bedrooms,
                "bathrooms": sample.bathrooms,
                "squareFeet": sample.squareFeet,
                "lotSize": sample.lotSize,
                "levels": sample.levels,
                "yearBuilt": sample.yearBuilt,
                "description": sample.description,
                "ownerComments": sample.ownerComments,
                "features": sample.features,
                "hasPool": sample.hasPool,
                "hasElevator": sample.hasElevator,
                "isWaterfront": sample.isWaterfront,
                "isPetFriendly": sample.isPetFriendly,
                "isFeatured": sample.isFeatured,
                "listingDate": Timestamp(date: Date().addingTimeInterval(-sample.daysOnMarket * 86_400)),
                "moveInDate": Timestamp(date: Date().addingTimeInterval(sample.moveInDays * 86_400)),
                "monthlyTaxes": sample.monthlyTaxes,
                "monthlyElectricity": sample.monthlyElectricity,
                "monthlyCondoFees": sample.monthlyCondoFees,
                "parkingSpaces": sample.parkingSpaces,
                "garages": sample.garages,
                "constructionType": sample.constructionType,
                "status": "published",
                "lat": sample.latitude,
                "lng": sample.longitude,
                "photoUrls": sample.photoUrls,
                "source": "seed"
            ]
            if let ownerId = Auth.auth().currentUser?.uid {
                payload["ownerId"] = ownerId
            }
            try await db.collection("listings").addDocument(data: payload)
        }

        await loadListings()
    }

    private static func mapDocument(_ document: QueryDocumentSnapshot) -> Property? {
        let data = document.data()
        let title = data["title"] as? String ?? "Untitled"
        let price = data["price"] as? Int ?? 0
        let address = data["address"] as? String ?? ""
        let city = data["city"] as? String ?? ""
        let region = data["region"] as? String ?? ""
        let country = data["country"] as? String
        let listingType = parseListingType(data["listingType"] as? String)
        let propertyType = parsePropertyType(data["propertyType"] as? String)
        let constructionType = parseConstructionType(data["constructionType"] as? String)
        let bedrooms = data["bedrooms"] as? Int ?? 0
        let bathrooms = data["bathrooms"] as? Int ?? 0
        let squareFeet = data["squareFeet"] as? Int ?? 0
        let lotSize = data["lotSize"] as? Int ?? 0
        let levels = data["levels"] as? Int ?? 0
        let yearBuilt = data["yearBuilt"] as? Int ?? 0
        let imageURLs = data["photoUrls"] as? [String] ?? []
        let description = data["description"] as? String ?? ""
        let ownerComments = data["ownerComments"] as? String ?? ""
        let features = data["features"] as? [String: String] ?? [:]
        let hasPool = data["hasPool"] as? Bool ?? false
        let hasElevator = data["hasElevator"] as? Bool ?? false
        let isWaterfront = data["isWaterfront"] as? Bool ?? false
        let isPetFriendly = data["isPetFriendly"] as? Bool ?? false
        let isFeatured = data["isFeatured"] as? Bool ?? false
        let listingDate = (data["listingDate"] as? Timestamp)?.dateValue() ?? Date()
        let moveInDate = (data["moveInDate"] as? Timestamp)?.dateValue() ?? Date()
        let monthlyTaxes = data["monthlyTaxes"] as? Int ?? 0
        let monthlyElectricity = data["monthlyElectricity"] as? Int ?? 0
        let monthlyCondoFees = data["monthlyCondoFees"] as? Int ?? 0
        let parkingSpaces = data["parkingSpaces"] as? Int ?? 0
        let garages = data["garages"] as? Int ?? 0

        let (latitude, longitude) = parseCoordinates(data)
        var regionParts = [region]
        if let country, !country.isEmpty {
            regionParts.append(country)
        }
        let displayRegion = regionParts.filter { !$0.isEmpty }.joined(separator: ", ")

        return Property(
            id: document.documentID,
            title: title,
            price: price,
            address: address,
            city: city,
            region: displayRegion.isEmpty ? region : displayRegion,
            latitude: latitude,
            longitude: longitude,
            bedrooms: bedrooms,
            bathrooms: bathrooms,
            squareFeet: squareFeet,
            lotSize: lotSize,
            levels: levels,
            yearBuilt: yearBuilt,
            propertyType: propertyType,
            listingType: listingType,
            imageURLs: imageURLs,
            description: description,
            ownerComments: ownerComments,
            features: features,
            hasPool: hasPool,
            hasElevator: hasElevator,
            isWaterfront: isWaterfront,
            isPetFriendly: isPetFriendly,
            isFeatured: isFeatured,
            listingDate: listingDate,
            moveInDate: moveInDate,
            monthlyTaxes: monthlyTaxes,
            monthlyElectricity: monthlyElectricity,
            monthlyCondoFees: monthlyCondoFees,
            parkingSpaces: parkingSpaces,
            garages: garages,
            constructionType: constructionType
        )
    }

    private func uploadPhotos(_ photos: [Data], listingId: String) async throws -> [String] {
        var urls: [String] = []
        for data in photos {
            let filename = UUID().uuidString + ".jpg"
            let ref = storage.reference(withPath: "listingPhotos/\(listingId)/\(filename)")
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            _ = try await ref.putDataAsync(data, metadata: metadata)
            let url = try await ref.downloadURL()
            urls.append(url.absoluteString)
        }
        return urls
    }


    private static func parseCoordinates(_ data: [String: Any]) -> (Double, Double) {
        if let geoPoint = data["location"] as? GeoPoint {
            return (geoPoint.latitude, geoPoint.longitude)
        }
        let latitude = data["lat"] as? Double ?? 0
        let longitude = data["lng"] as? Double ?? 0
        return (latitude, longitude)
    }

    private static func parseListingType(_ value: String?) -> ListingType {
        switch value?.lowercased() {
        case "rent": return .rent
        default: return .sale
        }
    }

    private static func parsePropertyType(_ value: String?) -> PropertyType {
        if let value, let type = PropertyType(rawValue: value) { return type }
        switch value?.lowercased() {
        case "condo": return .condo
        case "plex": return .plex
        case "loft", "studio": return .loft
        case "intergenerational": return .intergenerational
        case "mobile home": return .mobileHome
        case "hobby farm": return .hobbyFarm
        case "cottage": return .cottage
        case "lot": return .lot
        default: return .house
        }
    }

    private static func parseConstructionType(_ value: String?) -> ConstructionType {
        if let value, let type = ConstructionType(rawValue: value) { return type }
        switch value?.lowercased() {
        case "new construction": return .newConstruction
        case "century/historic": return .centuryHistoric
        case "bungalow": return .bungalow
        case "more than one storey": return .moreThanOneStorey
        case "split-level": return .splitLevel
        case "detached": return .detached
        case "semi-detached": return .semiDetached
        case "attached": return .attached
        default: return .detached
        }
    }
}

private struct SampleListingData {
    let title: String
    let price: Int
    let address: String
    let city: String
    let region: String
    let latitude: Double
    let longitude: Double
    let bedrooms: Int
    let bathrooms: Int
    let squareFeet: Int
    let lotSize: Int
    let levels: Int
    let yearBuilt: Int
    let propertyType: String
    let listingType: String
    let description: String
    let ownerComments: String
    let features: [String: String]
    let hasPool: Bool
    let hasElevator: Bool
    let isWaterfront: Bool
    let isPetFriendly: Bool
    let isFeatured: Bool
    let daysOnMarket: Double
    let moveInDays: Double
    let monthlyTaxes: Int
    let monthlyElectricity: Int
    let monthlyCondoFees: Int
    let parkingSpaces: Int
    let garages: Int
    let constructionType: String
    let photoUrls: [String]

    static let samples: [SampleListingData] = [
        SampleListingData(
            title: "Old Port Loft with Terrace",
            price: 695000,
            address: "412 Rue Saint-Francois-Xavier",
            city: "Montreal",
            region: "Greater Montreal",
            latitude: 45.5019,
            longitude: -73.5546,
            bedrooms: 2,
            bathrooms: 2,
            squareFeet: 1240,
            lotSize: 0,
            levels: 1,
            yearBuilt: 2016,
            propertyType: "Condo",
            listingType: "sale",
            description: "Airy loft steps from the Old Port with floor-to-ceiling windows and a private terrace.",
            ownerComments: "Quiet building with a fantastic rooftop. We loved the walkability.",
            features: ["Heating": "Central", "Flooring": "Hardwood", "Terrace": "Private"],
            hasPool: false,
            hasElevator: true,
            isWaterfront: false,
            isPetFriendly: true,
            isFeatured: true,
            daysOnMarket: 6,
            moveInDays: 30,
            monthlyTaxes: 310,
            monthlyElectricity: 85,
            monthlyCondoFees: 420,
            parkingSpaces: 1,
            garages: 1,
            constructionType: "New construction",
            photoUrls: [
                "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200",
                "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200",
                "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200"
            ]
        ),
        SampleListingData(
            title: "Westmount Family Home",
            price: 1285000,
            address: "62 Av. Victoria",
            city: "Westmount",
            region: "Greater Montreal",
            latitude: 45.4869,
            longitude: -73.5960,
            bedrooms: 4,
            bathrooms: 3,
            squareFeet: 2850,
            lotSize: 4200,
            levels: 2,
            yearBuilt: 1928,
            propertyType: "House",
            listingType: "sale",
            description: "Classic Westmount stone home with a renovated kitchen and sunny backyard.",
            ownerComments: "We restored the original woodwork and added a modern family room.",
            features: ["Heating": "Radiant", "Renovated": "Kitchen 2021", "Yard": "Landscaped"],
            hasPool: false,
            hasElevator: false,
            isWaterfront: false,
            isPetFriendly: true,
            isFeatured: true,
            daysOnMarket: 3,
            moveInDays: 60,
            monthlyTaxes: 640,
            monthlyElectricity: 160,
            monthlyCondoFees: 0,
            parkingSpaces: 2,
            garages: 1,
            constructionType: "Century/Historic",
            photoUrls: [
                "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1200",
                "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200",
                "https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=1200"
            ]
        ),
        SampleListingData(
            title: "Lakefront Cottage Retreat",
            price: 845000,
            address: "18 Chemin du Lac-Brome",
            city: "Knowlton",
            region: "Eastern Townships",
            latitude: 45.2343,
            longitude: -72.5214,
            bedrooms: 3,
            bathrooms: 2,
            squareFeet: 1750,
            lotSize: 9800,
            levels: 2,
            yearBuilt: 2009,
            propertyType: "Cottage",
            listingType: "sale",
            description: "Charming cottage with direct lake access, private dock, and panoramic sunsets.",
            ownerComments: "Perfect for weekends and summer gatherings with friends.",
            features: ["Waterfront": "Yes", "Dock": "Private", "Heating": "Heat pump"],
            hasPool: false,
            hasElevator: false,
            isWaterfront: true,
            isPetFriendly: true,
            isFeatured: false,
            daysOnMarket: 12,
            moveInDays: 45,
            monthlyTaxes: 420,
            monthlyElectricity: 140,
            monthlyCondoFees: 0,
            parkingSpaces: 3,
            garages: 0,
            constructionType: "Detached",
            photoUrls: [
                "https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=1200",
                "https://images.unsplash.com/photo-1507089947368-19c1da9775ae?w=1200",
                "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1200"
            ]
        ),
        SampleListingData(
            title: "Plateau Artist's Duplex",
            price: 980000,
            address: "4250 Rue De Bullion",
            city: "Montreal",
            region: "Greater Montreal",
            latitude: 45.5262,
            longitude: -73.6008,
            bedrooms: 5,
            bathrooms: 2,
            squareFeet: 2400,
            lotSize: 2600,
            levels: 2,
            yearBuilt: 1910,
            propertyType: "Plex",
            listingType: "sale",
            description: "Sunlit duplex in the Plateau with original brick and flexible studio space.",
            ownerComments: "We used the upper unit as a creative studio with gorgeous light.",
            features: ["Units": "2", "Flooring": "Hardwood", "Balcony": "Rear"],
            hasPool: false,
            hasElevator: false,
            isWaterfront: false,
            isPetFriendly: true,
            isFeatured: false,
            daysOnMarket: 9,
            moveInDays: 30,
            monthlyTaxes: 520,
            monthlyElectricity: 120,
            monthlyCondoFees: 0,
            parkingSpaces: 1,
            garages: 0,
            constructionType: "Century/Historic",
            photoUrls: [
                "https://images.unsplash.com/photo-1502005097973-6a7082348e28?w=1200",
                "https://images.unsplash.com/photo-1502672023488-70e25813eb80?w=1200",
                "https://images.unsplash.com/photo-1501045661006-fcebe0257c3f?w=1200"
            ]
        ),
        SampleListingData(
            title: "Urban Rental in Griffintown",
            price: 2100,
            address: "1200 Rue Ottawa, Unit 908",
            city: "Montreal",
            region: "Greater Montreal",
            latitude: 45.4895,
            longitude: -73.5632,
            bedrooms: 1,
            bathrooms: 1,
            squareFeet: 720,
            lotSize: 0,
            levels: 1,
            yearBuilt: 2020,
            propertyType: "Condo",
            listingType: "rent",
            description: "Modern rental with gym and rooftop pool in the heart of Griffintown.",
            ownerComments: "Walk to cafes, the canal, and the best restaurants.",
            features: ["Furnished": "Optional", "Lease": "12 months", "Gym": "Yes"],
            hasPool: true,
            hasElevator: true,
            isWaterfront: false,
            isPetFriendly: false,
            isFeatured: false,
            daysOnMarket: 4,
            moveInDays: 14,
            monthlyTaxes: 0,
            monthlyElectricity: 0,
            monthlyCondoFees: 0,
            parkingSpaces: 0,
            garages: 0,
            constructionType: "New construction",
            photoUrls: [
                "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200",
                "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200",
                "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200"
            ]
        )
    ]
}

struct ListingDraft: Sendable {
    var title: String
    var price: Int
    var address: String
    var city: String
    var region: String
    var country: String
    var listingType: ListingType
    var propertyType: PropertyType
    var bedrooms: Int
    var bathrooms: Int
    var squareFeet: Int
    var lotSize: Int
    var levels: Int
    var yearBuilt: Int
    var description: String
    var ownerComments: String
    var features: [String: String]
    var hasPool: Bool
    var hasElevator: Bool
    var isWaterfront: Bool
    var isPetFriendly: Bool
    var moveInDate: Date
    var monthlyTaxes: Int
    var monthlyElectricity: Int
    var monthlyCondoFees: Int
    var parkingSpaces: Int
    var garages: Int
    var constructionType: ConstructionType
    var latitude: Double
    var longitude: Double
    var status: String
    var listedBy: String
}
