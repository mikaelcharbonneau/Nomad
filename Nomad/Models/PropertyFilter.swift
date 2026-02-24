//
//  PropertyFilter.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

struct PropertyFilter {
    var listingType: ListingType = .sale
    var propertyTypes: Set<PropertyType> = []
    var minPrice: Int?
    var maxPrice: Int?
    var bedrooms: String?
    var bathrooms: String?
    var parkingSpaces: String?
    var garages: String?
    var hasPool: Bool = false
    var hasElevator: Bool = false
    var adaptedMobility: Bool = false
    var isWaterfront: Bool = false
    var accessWaterfront: Bool = false
    var navigableWater: Bool = false
    var isResort: Bool = false
    var isPetFriendly: Bool = false
    var smokingAllowed: Bool = false
    var openHouses: Bool = false
    var repossession: Bool = false
    var minYear: Int?
    var maxYear: Int?
    var constructionTypes: Set<ConstructionType> = []
    var minLivingArea: Int?
    var maxLivingArea: Int?
    var minLandArea: Int?
    var maxLandArea: Int?
    var moveInDateStart: Date?
    var moveInDateEnd: Date?
    var listingDateStart: Date?
    var listingDateEnd: Date?
    var selectedCities: Set<String> = []

    var isLotOnly: Bool {
        propertyTypes.count == 1 && propertyTypes.contains(.lot)
    }

    var isActive: Bool {
        !propertyTypes.isEmpty || minPrice != nil || maxPrice != nil ||
        bedrooms != nil || bathrooms != nil || parkingSpaces != nil ||
        garages != nil || hasPool || hasElevator || adaptedMobility ||
        isWaterfront || accessWaterfront || navigableWater || isResort ||
        isPetFriendly || smokingAllowed || openHouses || repossession ||
        minYear != nil || maxYear != nil || !constructionTypes.isEmpty ||
        minLivingArea != nil || maxLivingArea != nil ||
        minLandArea != nil || maxLandArea != nil ||
        moveInDateStart != nil || moveInDateEnd != nil ||
        listingDateStart != nil || listingDateEnd != nil ||
        !selectedCities.isEmpty
    }

    mutating func reset() {
        self = PropertyFilter()
    }
}
