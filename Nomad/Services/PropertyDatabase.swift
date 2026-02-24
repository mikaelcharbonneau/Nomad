//
//  PropertyDatabase.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import Foundation

@Observable
@MainActor
class PropertyDatabase {
    static let shared = PropertyDatabase()

    var properties: [Property] = []

    private init() {
        seedProperties()
    }

    private func seedProperties() {
        properties = [
            Property(
                id: "p1", title: "Modern Downtown Condo", price: 485000,
                address: "1250 René-Lévesque Blvd W, Unit 2204", city: "Montreal", region: "Greater Montreal",
                latitude: 45.4972, longitude: -73.5731,
                bedrooms: 2, bathrooms: 2, squareFeet: 1150, lotSize: 0, levels: 1, yearBuilt: 2020,
                propertyType: .condo, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
                    "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
                    "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800"
                ],
                description: "Stunning modern condo in the heart of downtown Montreal with panoramic city views.",
                ownerComments: "We've loved living here for the past 3 years. The building amenities are fantastic and the location is unbeatable. Walking distance to everything.",
                features: ["Ownership": "Divided", "Year of construction": "2020", "Heating": "Central forced air", "Flooring": "Hardwood", "Appliances": "All included"],
                hasPool: false, hasElevator: true, isWaterfront: false, isPetFriendly: true,
                isFeatured: true, listingDate: Date().addingTimeInterval(-86400 * 5),
                moveInDate: Date().addingTimeInterval(86400 * 30),
                monthlyTaxes: 280, monthlyElectricity: 85, monthlyCondoFees: 420,
                parkingSpaces: 1, garages: 1, constructionType: .newConstruction
            ),
            Property(
                id: "p2", title: "Charming Victorian Home", price: 895000,
                address: "342 Elm Avenue", city: "Montreal", region: "Greater Montreal",
                latitude: 45.4842, longitude: -73.5856,
                bedrooms: 4, bathrooms: 3, squareFeet: 2850, lotSize: 4500, levels: 3, yearBuilt: 1912,
                propertyType: .house, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
                    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800",
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800",
                    "https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=800"
                ],
                description: "Beautifully restored Victorian home with original details and modern amenities.",
                ownerComments: "This home has been in our family for generations. Every room has been carefully restored while adding modern comforts. The garden is a true oasis.",
                features: ["Ownership": "Undivided", "Year of construction": "1912", "Heating": "Radiant floor", "Flooring": "Original hardwood", "Roof": "Slate, replaced 2019"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: true, listingDate: Date().addingTimeInterval(-86400 * 12),
                moveInDate: Date().addingTimeInterval(86400 * 60),
                monthlyTaxes: 520, monthlyElectricity: 150, monthlyCondoFees: 0,
                parkingSpaces: 2, garages: 1, constructionType: .centuryHistoric
            ),
            Property(
                id: "p3", title: "Waterfront Luxury Estate", price: 2450000,
                address: "88 Lakeshore Drive", city: "Mont-Tremblant", region: "Laurentians",
                latitude: 46.2091, longitude: -74.5960,
                bedrooms: 5, bathrooms: 4, squareFeet: 4200, lotSize: 12000, levels: 2, yearBuilt: 2018,
                propertyType: .house, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800",
                    "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800",
                    "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800"
                ],
                description: "Magnificent waterfront property with private dock and breathtaking lake views.",
                ownerComments: "An absolute dream property. Wake up to stunning lake views every morning. The infinity pool and dock make summers unforgettable.",
                features: ["Ownership": "Undivided", "Year of construction": "2018", "Heating": "Geothermal", "Flooring": "Italian marble & hardwood", "Windows": "Triple-pane"],
                hasPool: true, hasElevator: false, isWaterfront: true, isPetFriendly: true,
                isFeatured: true, listingDate: Date().addingTimeInterval(-86400 * 3),
                moveInDate: Date().addingTimeInterval(86400 * 45),
                monthlyTaxes: 1200, monthlyElectricity: 280, monthlyCondoFees: 0,
                parkingSpaces: 4, garages: 2, constructionType: .detached
            ),
            Property(
                id: "p4", title: "Cozy Studio Loft", price: 225000,
                address: "55 Saint-Paul Street E, Unit 305", city: "Montreal", region: "Greater Montreal",
                latitude: 45.5075, longitude: -73.5530,
                bedrooms: 0, bathrooms: 1, squareFeet: 550, lotSize: 0, levels: 1, yearBuilt: 2015,
                propertyType: .loft, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1536376072261-38c75010e6c9?w=800",
                    "https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=800"
                ],
                description: "Stylish studio loft in the vibrant Old Montreal neighborhood.",
                ownerComments: "Perfect for young professionals or as an investment property. The neighborhood is alive with restaurants and culture.",
                features: ["Ownership": "Divided", "Year of construction": "2015", "Heating": "Electric baseboard", "Flooring": "Polished concrete", "Ceiling height": "12 feet"],
                hasPool: false, hasElevator: true, isWaterfront: false, isPetFriendly: false,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 20),
                moveInDate: Date().addingTimeInterval(86400 * 15),
                monthlyTaxes: 120, monthlyElectricity: 55, monthlyCondoFees: 280,
                parkingSpaces: 0, garages: 0, constructionType: .attached
            ),
            Property(
                id: "p5", title: "Family Bungalow with Pool", price: 545000,
                address: "1872 Maple Crescent", city: "Laval", region: "Greater Montreal",
                latitude: 45.5690, longitude: -73.6920,
                bedrooms: 3, bathrooms: 2, squareFeet: 1800, lotSize: 6800, levels: 1, yearBuilt: 1985,
                propertyType: .house, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800",
                    "https://images.unsplash.com/photo-1600573472592-401b489a3cdc?w=800",
                    "https://images.unsplash.com/photo-1600566753086-00f18f6b0d6b?w=800"
                ],
                description: "Spacious family bungalow with in-ground pool and mature landscaping.",
                ownerComments: "We raised our family here and it's been wonderful. The pool is the center of summer activities. Great school district nearby.",
                features: ["Ownership": "Undivided", "Year of construction": "1985", "Heating": "Natural gas", "Flooring": "Hardwood & ceramic", "Renovated": "Kitchen 2021"],
                hasPool: true, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 8),
                moveInDate: Date().addingTimeInterval(86400 * 90),
                monthlyTaxes: 350, monthlyElectricity: 120, monthlyCondoFees: 0,
                parkingSpaces: 2, garages: 1, constructionType: .bungalow
            ),
            Property(
                id: "p6", title: "Revenue Triplex", price: 725000,
                address: "4455 Papineau Avenue", city: "Montreal", region: "Greater Montreal",
                latitude: 45.5270, longitude: -73.5700,
                bedrooms: 6, bathrooms: 3, squareFeet: 3200, lotSize: 3000, levels: 3, yearBuilt: 1945,
                propertyType: .plex, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=800",
                    "https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800"
                ],
                description: "Well-maintained triplex with strong rental income potential in a growing neighborhood.",
                ownerComments: "All three units have been renovated in the last 5 years. Current tenants are long-term and reliable. Excellent investment.",
                features: ["Ownership": "Undivided", "Year of construction": "1945", "Revenue": "$48,000/year", "Units": "3", "Renovated": "2020-2022"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 15),
                moveInDate: Date().addingTimeInterval(86400 * 120),
                monthlyTaxes: 480, monthlyElectricity: 0, monthlyCondoFees: 0,
                parkingSpaces: 3, garages: 0, constructionType: .moreThanOneStorey
            ),
            Property(
                id: "p7", title: "Ski Chalet Cottage", price: 395000,
                address: "22 Chemin du Sommet", city: "Saint-Sauveur", region: "Laurentians",
                latitude: 45.9000, longitude: -74.1700,
                bedrooms: 3, bathrooms: 2, squareFeet: 1600, lotSize: 8000, levels: 2, yearBuilt: 2005,
                propertyType: .cottage, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800",
                    "https://images.unsplash.com/photo-1449158743715-0a90ebb6d2d8?w=800",
                    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800"
                ],
                description: "Charming A-frame cottage minutes from ski slopes and village boutiques.",
                ownerComments: "Our beloved weekend retreat. Ski-in access to the slopes makes winters magical. The wood-burning fireplace is the heart of the home.",
                features: ["Ownership": "Undivided", "Year of construction": "2005", "Heating": "Wood + electric", "Flooring": "Pine wood", "Fireplace": "Wood-burning"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: true, listingDate: Date().addingTimeInterval(-86400 * 2),
                moveInDate: Date().addingTimeInterval(86400 * 30),
                monthlyTaxes: 220, monthlyElectricity: 95, monthlyCondoFees: 0,
                parkingSpaces: 2, garages: 0, constructionType: .detached
            ),
            Property(
                id: "p8", title: "Intergenerational Home", price: 675000,
                address: "990 Boulevard des Seigneurs", city: "Terrebonne", region: "Greater Montreal",
                latitude: 45.7000, longitude: -73.6500,
                bedrooms: 5, bathrooms: 3, squareFeet: 3000, lotSize: 5500, levels: 2, yearBuilt: 2010,
                propertyType: .intergenerational, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1600607687644-c7171b42498f?w=800",
                    "https://images.unsplash.com/photo-1600566753151-384129cf4e3e?w=800"
                ],
                description: "Perfect intergenerational home with separate entrance and full kitchen for in-law suite.",
                ownerComments: "Designed for multi-generational living with complete privacy for both units. Shared backyard is perfect for family gatherings.",
                features: ["Ownership": "Undivided", "Year of construction": "2010", "Units": "2 (main + in-law)", "Heating": "Heat pump", "Flooring": "Engineered hardwood"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 7),
                moveInDate: Date().addingTimeInterval(86400 * 60),
                monthlyTaxes: 420, monthlyElectricity: 160, monthlyCondoFees: 0,
                parkingSpaces: 3, garages: 2, constructionType: .detached
            ),
            Property(
                id: "p9", title: "Luxury Penthouse", price: 1200000,
                address: "1500 Atwater Ave, PH-1", city: "Montreal", region: "Greater Montreal",
                latitude: 45.4780, longitude: -73.5850,
                bedrooms: 3, bathrooms: 3, squareFeet: 2400, lotSize: 0, levels: 2, yearBuilt: 2022,
                propertyType: .condo, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800",
                    "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800",
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800"
                ],
                description: "Breathtaking penthouse with private rooftop terrace and 360° city views.",
                ownerComments: "The crown jewel of the building. Floor-to-ceiling windows on all sides. The rooftop terrace is perfect for entertaining.",
                features: ["Ownership": "Divided", "Year of construction": "2022", "Heating": "Central + radiant floor", "Flooring": "White oak", "Terrace": "800 sq ft"],
                hasPool: true, hasElevator: true, isWaterfront: false, isPetFriendly: true,
                isFeatured: true, listingDate: Date().addingTimeInterval(-86400 * 1),
                moveInDate: Date().addingTimeInterval(86400 * 30),
                monthlyTaxes: 680, monthlyElectricity: 200, monthlyCondoFees: 850,
                parkingSpaces: 2, garages: 2, constructionType: .newConstruction
            ),
            Property(
                id: "p10", title: "Mobile Home in Quiet Park", price: 89000,
                address: "Lot 42, Parc Résidentiel du Lac", city: "Granby", region: "Eastern Townships",
                latitude: 45.4000, longitude: -72.7300,
                bedrooms: 2, bathrooms: 1, squareFeet: 900, lotSize: 2000, levels: 1, yearBuilt: 2008,
                propertyType: .mobileHome, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1558036117-15d82a90b9b1?w=800",
                    "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800"
                ],
                description: "Well-maintained mobile home in a peaceful residential park near the lake.",
                ownerComments: "Affordable living at its finest. The community is friendly and quiet. Perfect for retirees or first-time buyers.",
                features: ["Ownership": "Leased land", "Year of construction": "2008", "Heating": "Electric", "Lot rent": "$350/month"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 30),
                moveInDate: Date().addingTimeInterval(86400 * 14),
                monthlyTaxes: 60, monthlyElectricity: 70, monthlyCondoFees: 350,
                parkingSpaces: 1, garages: 0, constructionType: .detached
            ),
            Property(
                id: "p11", title: "Hobby Farm Paradise", price: 780000,
                address: "1100 Rang Saint-Joseph", city: "Magog", region: "Eastern Townships",
                latitude: 45.2700, longitude: -72.1500,
                bedrooms: 4, bathrooms: 2, squareFeet: 2200, lotSize: 180000, levels: 2, yearBuilt: 1975,
                propertyType: .hobbyFarm, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800",
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800",
                    "https://images.unsplash.com/photo-1600566753086-00f18f6b0d6b?w=800"
                ],
                description: "Beautiful hobby farm with barn, greenhouse, and 40 acres of rolling countryside.",
                ownerComments: "A true escape from city life. We've grown organic vegetables and raised chickens here. The sunsets over the hills are unmatched.",
                features: ["Ownership": "Undivided", "Year of construction": "1975", "Land": "40 acres", "Outbuildings": "Barn, greenhouse, workshop", "Water": "Well"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 18),
                moveInDate: Date().addingTimeInterval(86400 * 90),
                monthlyTaxes: 380, monthlyElectricity: 130, monthlyCondoFees: 0,
                parkingSpaces: 4, garages: 1, constructionType: .detached
            ),
            Property(
                id: "p12", title: "Building Lot — Lake Access", price: 125000,
                address: "Lot 7, Chemin du Rivage", city: "Bromont", region: "Eastern Townships",
                latitude: 45.3167, longitude: -72.6500,
                bedrooms: 0, bathrooms: 0, squareFeet: 0, lotSize: 15000, levels: 0, yearBuilt: 0,
                propertyType: .lot, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800",
                    "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=800"
                ],
                description: "Prime building lot with lake access and mountain views. Services at the road.",
                ownerComments: "Build your dream home on this beautiful wooded lot. Municipal water and sewer available. Stunning views of the Appalachian mountains.",
                features: ["Zoning": "Residential", "Services": "Water, sewer, electricity at road", "Access": "Lake communal beach", "Topography": "Gentle slope"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 45),
                moveInDate: Date().addingTimeInterval(86400 * 7),
                monthlyTaxes: 40, monthlyElectricity: 0, monthlyCondoFees: 0,
                parkingSpaces: 0, garages: 0, constructionType: .detached
            ),
            Property(
                id: "p13", title: "Quebec City Heritage Home", price: 520000,
                address: "18 Rue du Petit-Champlain", city: "Quebec City", region: "Quebec City",
                latitude: 46.8130, longitude: -71.2040,
                bedrooms: 3, bathrooms: 2, squareFeet: 1950, lotSize: 2200, levels: 3, yearBuilt: 1890,
                propertyType: .house, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=800",
                    "https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800",
                    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800"
                ],
                description: "Charming heritage home in the heart of Old Quebec. Steps from the St. Lawrence River.",
                ownerComments: "Living in Old Quebec is like living in a fairy tale. This home combines centuries of history with modern comfort. Tourist season brings energy to the street.",
                features: ["Ownership": "Undivided", "Year of construction": "1890", "Heritage": "Protected façade", "Heating": "Natural gas forced air", "Parking": "Street permit"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: false,
                isFeatured: true, listingDate: Date().addingTimeInterval(-86400 * 10),
                moveInDate: Date().addingTimeInterval(86400 * 60),
                monthlyTaxes: 340, monthlyElectricity: 110, monthlyCondoFees: 0,
                parkingSpaces: 0, garages: 0, constructionType: .centuryHistoric
            ),
            Property(
                id: "p14", title: "Split-Level in Lévis", price: 345000,
                address: "455 Avenue Taniata", city: "Lévis", region: "Quebec City",
                latitude: 46.7400, longitude: -71.1800,
                bedrooms: 3, bathrooms: 2, squareFeet: 1650, lotSize: 5000, levels: 3, yearBuilt: 1992,
                propertyType: .house, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800",
                    "https://images.unsplash.com/photo-1600573472592-401b489a3cdc?w=800"
                ],
                description: "Well-maintained split-level home with finished basement and private backyard.",
                ownerComments: "Great family home with a layout that provides privacy for everyone. The finished basement is perfect for a home office or playroom.",
                features: ["Ownership": "Undivided", "Year of construction": "1992", "Heating": "Oil forced air", "Flooring": "Hardwood & carpet", "Basement": "Fully finished"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 22),
                moveInDate: Date().addingTimeInterval(86400 * 45),
                monthlyTaxes: 240, monthlyElectricity: 100, monthlyCondoFees: 0,
                parkingSpaces: 2, garages: 1, constructionType: .splitLevel
            ),
            Property(
                id: "p15", title: "Modern Semi-Detached", price: 415000,
                address: "210 Rue de la Commune", city: "Longueuil", region: "Greater Montreal",
                latitude: 45.5312, longitude: -73.5185,
                bedrooms: 3, bathrooms: 2, squareFeet: 1500, lotSize: 2800, levels: 2, yearBuilt: 2019,
                propertyType: .house, listingType: .sale,
                imageURLs: [
                    "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800",
                    "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800",
                    "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800"
                ],
                description: "Contemporary semi-detached home with open concept living and eco-friendly features.",
                ownerComments: "Built to exceed energy efficiency standards. The open concept main floor is perfect for entertaining. Quick access to the metro.",
                features: ["Ownership": "Undivided", "Year of construction": "2019", "Heating": "Heat pump", "Flooring": "Engineered bamboo", "Energy": "LEED certified"],
                hasPool: false, hasElevator: false, isWaterfront: false, isPetFriendly: true,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 6),
                moveInDate: Date().addingTimeInterval(86400 * 30),
                monthlyTaxes: 290, monthlyElectricity: 75, monthlyCondoFees: 0,
                parkingSpaces: 1, garages: 1, constructionType: .semiDetached
            ),
            Property(
                id: "p16", title: "Rental Condo Downtown", price: 1800,
                address: "800 Sherbrooke St W, Unit 1504", city: "Montreal", region: "Greater Montreal",
                latitude: 45.5055, longitude: -73.5750,
                bedrooms: 1, bathrooms: 1, squareFeet: 750, lotSize: 0, levels: 1, yearBuilt: 2021,
                propertyType: .condo, listingType: .rent,
                imageURLs: [
                    "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800",
                    "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800"
                ],
                description: "Fully furnished 1-bedroom rental in a premium downtown building with gym and pool.",
                ownerComments: "Move-in ready with all furnishings included. Building amenities include a gym, pool, and rooftop terrace.",
                features: ["Furnished": "Yes", "Lease": "12 months", "Utilities": "Included", "Laundry": "In-unit"],
                hasPool: true, hasElevator: true, isWaterfront: false, isPetFriendly: false,
                isFeatured: false, listingDate: Date().addingTimeInterval(-86400 * 4),
                moveInDate: Date().addingTimeInterval(86400 * 14),
                monthlyTaxes: 0, monthlyElectricity: 0, monthlyCondoFees: 0,
                parkingSpaces: 1, garages: 0, constructionType: .newConstruction
            ),
        ]
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
                return false
            }

            if let minYear = filter.minYear, property.yearBuilt > 0, property.yearBuilt < minYear { return false }
            if let maxYear = filter.maxYear, property.yearBuilt > 0, property.yearBuilt > maxYear { return false }

            if let minArea = filter.minLivingArea, property.squareFeet > 0, property.squareFeet < minArea { return false }
            if let maxArea = filter.maxLivingArea, property.squareFeet > 0, property.squareFeet > maxArea { return false }

            if let minLand = filter.minLandArea, property.lotSize > 0, property.lotSize < minLand { return false }
            if let maxLand = filter.maxLandArea, property.lotSize > 0, property.lotSize > maxLand { return false }

            return true
        }
    }
}
