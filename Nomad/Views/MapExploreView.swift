//
//  MapExploreView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI
import MapKit

struct MapExploreView: View {
    let properties: [Property]
    let appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProperty: Property?
    @State private var showDetail = false
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5673),
            span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
        )
    )

    var body: some View {
        ZStack {
            Map(position: $cameraPosition, selection: $selectedProperty) {
                ForEach(properties) { property in
                    Annotation(property.formattedPrice, coordinate: CLLocationCoordinate2D(latitude: property.latitude, longitude: property.longitude)) {
                        Button {
                            selectedProperty = property
                        } label: {
                            Text(property.formattedPrice)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.black, in: .capsule)
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        }
                    }
                    .tag(property)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(NomadTheme.darkText)
                            .frame(width: 40, height: 40)
                            .background(.white, in: .circle)
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Spacer()

                if let property = selectedProperty {
                    mapPreviewCard(property)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button { dismiss() } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet")
                        Text("View list")
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
        .fullScreenCover(isPresented: $showDetail) {
            if let property = selectedProperty {
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private func mapPreviewCard(_ property: Property) -> some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 12) {
                Color(.secondarySystemBackground)
                    .frame(width: 80, height: 80)
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

                VStack(alignment: .leading, spacing: 4) {
                    Text(property.fullFormattedPrice)
                        .font(.headline)
                        .foregroundStyle(NomadTheme.darkText)
                    Text(property.address)
                        .font(.caption)
                        .foregroundStyle(NomadTheme.lightGrey)
                        .lineLimit(2)
                    Text(property.city)
                        .font(.caption)
                        .foregroundStyle(NomadTheme.darkGreen)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(NomadTheme.lightGrey)
            }
            .padding(12)
            .background(.white, in: .rect(cornerRadius: NomadTheme.pillRadius))
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}
