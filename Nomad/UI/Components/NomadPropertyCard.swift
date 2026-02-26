import SwiftUI

struct NomadPropertyCard: View {
    enum Variant {
        case full
        case compact
        case mini

        var imageHeight: CGFloat {
            switch self {
            case .full: return 236
            case .compact: return 120
            case .mini: return 120
            }
        }

        var contentSpacing: CGFloat {
            switch self {
            case .full: return NomadSpacing.md
            case .compact, .mini: return NomadSpacing.sm
            }
        }

        var cardPadding: CGFloat {
            switch self {
            case .full: return NomadSpacing.md
            case .compact, .mini: return NomadSpacing.sm
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .full: return NomadRadius.hero
            case .compact, .mini: return NomadRadius.card
            }
        }

        var priceFont: Font {
            switch self {
            case .full: return NomadTypography.title2
            case .compact, .mini: return NomadTypography.bodyStrong
            }
        }

        var cityFont: Font {
            switch self {
            case .full: return NomadTypography.bodyStrong
            case .compact, .mini: return NomadTypography.body
            }
        }

        var showsAddress: Bool {
            switch self {
            case .full: return true
            case .compact, .mini: return false
            }
        }

        var specsLimit: Int {
            switch self {
            case .full: return 4
            case .compact, .mini: return 2
            }
        }

        var shadowLevel: NomadElevation {
            switch self {
            case .full: return .level2
            case .compact, .mini: return .level1
            }
        }
    }

    let property: Property
    let variant: Variant
    var isSaved: Bool? = nil
    var onToggleSave: (() -> Void)? = nil

    @State private var imageIndex = 0

    init(property: Property, variant: Variant = .full, isSaved: Bool? = nil, onToggleSave: (() -> Void)? = nil) {
        self.property = property
        self.variant = variant
        self.isSaved = isSaved
        self.onToggleSave = onToggleSave
    }

    var body: some View {
        VStack(alignment: .leading, spacing: variant.contentSpacing) {
            imageContent

            VStack(alignment: .leading, spacing: NomadSpacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: NomadSpacing.xs) {
                    Text(property.fullFormattedPrice)
                        .font(variant.priceFont)
                        .foregroundStyle(NomadColor.Text.primary)

                    if property.listingType == .rent && variant == .full {
                        Text("/mo")
                            .font(NomadTypography.caption)
                            .foregroundStyle(NomadColor.Text.secondary)
                    }

                    Spacer(minLength: NomadSpacing.xs)

                    if let isSaved, let onToggleSave {
                        Button(action: onToggleSave) {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(isSaved ? .red : NomadColor.Text.tertiary)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: NomadSpacing.xxs) {
                    Image(systemName: "mappin")
                        .font(NomadTypography.meta)
                        .foregroundStyle(NomadColor.Accent.primary)
                    Text(property.city)
                        .font(variant.cityFont)
                        .foregroundStyle(NomadColor.Text.primary)
                        .lineLimit(1)
                }

                if variant.showsAddress {
                    Text(property.address)
                        .font(NomadTypography.caption)
                        .foregroundStyle(NomadColor.Text.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: NomadSpacing.md) {
                    ForEach(propertySpecs.prefix(variant.specsLimit)) { spec in
                        SpecItem(icon: spec.icon, value: spec.value)
                    }
                }
                .padding(.top, NomadSpacing.xxs)
            }
        }
        .padding(variant.cardPadding)
        .nomadCardSurface(level: variant.shadowLevel, radius: variant.cornerRadius)
    }

    @ViewBuilder
    private var imageContent: some View {
        if variant == .full, property.imageURLs.count > 1 {
            TabView(selection: $imageIndex) {
                ForEach(Array(property.imageURLs.enumerated()), id: \.offset) { index, url in
                    cardImage(url: url)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: variant.imageHeight)
            .clipShape(.rect(cornerRadius: variant.cornerRadius))
        } else {
            cardImage(url: property.imageURLs.first ?? "")
                .frame(height: variant.imageHeight)
                .clipShape(.rect(cornerRadius: variant.cornerRadius))
        }
    }

    private func cardImage(url: String) -> some View {
        Color(.secondarySystemBackground)
            .overlay {
                AsyncImage(url: URL(string: url)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } else if phase.error != nil {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(.tertiary)
                    } else {
                        ProgressView()
                    }
                }
            }
            .clipped()
    }

    private var propertySpecs: [PropertySpec] {
        var specs: [PropertySpec] = []
        if property.bedrooms > 0 { specs.append(PropertySpec(icon: "bed.double.fill", value: "\(property.bedrooms)")) }
        if property.bathrooms > 0 { specs.append(PropertySpec(icon: "shower.fill", value: "\(property.bathrooms)")) }
        if property.squareFeet > 0 { specs.append(PropertySpec(icon: "house.fill", value: "\(property.squareFeet) ft²")) }
        if property.lotSize > 0 { specs.append(PropertySpec(icon: "tree.fill", value: "\(property.lotSize) ft²")) }
        return specs
    }
}

private struct PropertySpec: Identifiable {
    let id = UUID()
    let icon: String
    let value: String
}

struct SpecItem: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: NomadSpacing.xxs) {
            Image(systemName: icon)
                .font(NomadTypography.meta)
                .foregroundStyle(NomadColor.Accent.primary)
            Text(value)
                .font(NomadTypography.caption)
                .foregroundStyle(NomadColor.Text.primary)
        }
    }
}

#Preview("Property Card") {
    let property = Property(
        id: "demo",
        title: "House",
        price: 1_285_000,
        address: "62 Av. Victoria",
        city: "Westmount",
        region: "Montreal",
        latitude: 0,
        longitude: 0,
        bedrooms: 4,
        bathrooms: 3,
        squareFeet: 2_850,
        lotSize: 4_200,
        levels: 2,
        yearBuilt: 2019,
        propertyType: .house,
        listingType: .sale,
        imageURLs: [],
        description: "",
        ownerComments: "",
        features: [:],
        hasPool: false,
        hasElevator: false,
        isWaterfront: false,
        isPetFriendly: false,
        isFeatured: false,
        listingDate: Date(),
        moveInDate: Date(),
        monthlyTaxes: 0,
        monthlyElectricity: 0,
        monthlyCondoFees: 0,
        parkingSpaces: 0,
        garages: 0,
        constructionType: .detached
    )

    VStack(spacing: NomadSpacing.lg) {
        NomadPropertyCard(property: property, variant: .full, isSaved: true) {}
        HStack {
            NomadPropertyCard(property: property, variant: .compact)
            NomadPropertyCard(property: property, variant: .mini)
        }
    }
    .padding(NomadSpacing.pageHorizontal)
    .nomadScreenBackground()
}

#Preview("Property Card AX4") {
    let property = Property(
        id: "demo-ax",
        title: "Condo",
        price: 695000,
        address: "412 Rue Saint-Francois-Xavier",
        city: "Montreal",
        region: "Quebec",
        latitude: 0,
        longitude: 0,
        bedrooms: 2,
        bathrooms: 2,
        squareFeet: 1240,
        lotSize: 0,
        levels: 1,
        yearBuilt: 2016,
        propertyType: .condo,
        listingType: .sale,
        imageURLs: [],
        description: "",
        ownerComments: "",
        features: [:],
        hasPool: false,
        hasElevator: true,
        isWaterfront: false,
        isPetFriendly: false,
        isFeatured: false,
        listingDate: Date(),
        moveInDate: Date(),
        monthlyTaxes: 0,
        monthlyElectricity: 0,
        monthlyCondoFees: 0,
        parkingSpaces: 0,
        garages: 0,
        constructionType: .detached
    )

    NomadPropertyCard(property: property, variant: .full, isSaved: false) {}
        .padding(NomadSpacing.pageHorizontal)
        .nomadScreenBackground()
        .environment(\.dynamicTypeSize, .accessibility4)
}
