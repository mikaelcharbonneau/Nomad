//
//  PropertyCardView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct PropertyCardView: View {
    let property: Property
    let isSaved: Bool
    let onToggleSave: () -> Void

    @State private var currentImageIndex = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(property.imageURLs.enumerated()), id: \.offset) { index, url in
                    Color(.secondarySystemBackground)
                        .overlay {
                            AsyncImage(url: URL(string: url)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                                } else if phase.error != nil {
                                    Image(systemName: "photo").font(.title).foregroundStyle(.tertiary)
                                } else {
                                    ProgressView()
                                }
                            }
                        }
                        .clipShape(.rect(cornerRadius: NomadTheme.pillRadius))
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 240)
            .clipShape(.rect(cornerRadius: NomadTheme.pillRadius))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(property.fullFormattedPrice)
                        .font(.title2.bold())
                        .foregroundStyle(NomadTheme.darkText)

                    if property.listingType == .rent {
                        Text("/mo")
                            .font(.subheadline)
                            .foregroundStyle(NomadTheme.lightGrey)
                    }

                    Spacer()

                    Button { onToggleSave() } label: {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundStyle(isSaved ? .red : NomadTheme.lightGrey)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: "mappin")
                        .font(.caption)
                        .foregroundStyle(NomadTheme.darkGreen)
                    Text(property.city)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NomadTheme.darkText)
                }

                Text(property.address)
                    .font(.caption)
                    .foregroundStyle(NomadTheme.lightGrey)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    if property.bedrooms > 0 {
                        SpecItem(icon: "bed.double.fill", value: "\(property.bedrooms)")
                    }
                    if property.bathrooms > 0 {
                        SpecItem(icon: "shower.fill", value: "\(property.bathrooms)")
                    }
                    if property.squareFeet > 0 {
                        SpecItem(icon: "house.fill", value: "\(property.squareFeet) ft²")
                    }
                    if property.lotSize > 0 {
                        SpecItem(icon: "tree.fill", value: "\(property.lotSize) ft²")
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
        }
        .padding(12)
        .background(.white, in: .rect(cornerRadius: NomadTheme.pillRadius))
        .shadow(color: .black.opacity(0.06), radius: 16, y: 8)
    }
}

struct SpecItem: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(NomadTheme.darkGreen)
            Text(value)
                .font(.caption)
                .foregroundStyle(NomadTheme.darkText)
        }
    }
}

struct MiniPropertyCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Color(.secondarySystemBackground)
                .frame(width: 180, height: 120)
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

            Text(property.formattedPrice)
                .font(.subheadline.bold())
                .foregroundStyle(NomadTheme.darkText)

            Text(property.city)
                .font(.caption)
                .foregroundStyle(NomadTheme.lightGrey)

            HStack(spacing: 8) {
                if property.bedrooms > 0 {
                    SpecItem(icon: "bed.double.fill", value: "\(property.bedrooms)")
                }
                if property.bathrooms > 0 {
                    SpecItem(icon: "shower.fill", value: "\(property.bathrooms)")
                }
            }
        }
        .frame(width: 180)
        .padding(10)
        .background(.white, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}
