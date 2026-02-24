//
//  Property.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

nonisolated struct Property: Identifiable, Hashable, Sendable {
    let id: String
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
    let propertyType: PropertyType
    let listingType: ListingType
    let imageURLs: [String]
    let description: String
    let ownerComments: String
    let features: [String: String]
    let hasPool: Bool
    let hasElevator: Bool
    let isWaterfront: Bool
    let isPetFriendly: Bool
    let isFeatured: Bool
    let listingDate: Date
    let moveInDate: Date
    let monthlyTaxes: Int
    let monthlyElectricity: Int
    let monthlyCondoFees: Int
    let parkingSpaces: Int
    let garages: Int
    let constructionType: ConstructionType

    var formattedPrice: String {
        if price >= 1_000_000 {
            let millions = Double(price) / 1_000_000.0
            return String(format: "$%.1fM", millions)
        } else if price >= 1000 {
            let thousands = Double(price) / 1000.0
            return String(format: "$%.0fK", thousands)
        }
        return "$\(price)"
    }

    var fullFormattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
}

nonisolated enum PropertyType: String, CaseIterable, Hashable, Sendable {
    case house = "House"
    case condo = "Condo"
    case plex = "Plex"
    case loft = "Loft / Studio"
    case intergenerational = "Intergenerational"
    case mobileHome = "Mobile home"
    case hobbyFarm = "Hobby farm"
    case cottage = "Cottage"
    case lot = "Lot"
}

nonisolated enum ListingType: String, CaseIterable, Hashable, Sendable {
    case sale = "Sale"
    case rent = "Rent"
}

nonisolated enum ConstructionType: String, CaseIterable, Hashable, Sendable {
    case newConstruction = "New construction"
    case centuryHistoric = "Century/Historic"
    case bungalow = "Bungalow"
    case moreThanOneStorey = "More than one storey"
    case splitLevel = "Split-level"
    case detached = "Detached"
    case semiDetached = "Semi-detached"
    case attached = "Attached"
}
