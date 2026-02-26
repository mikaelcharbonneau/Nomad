import MapKit
import SwiftUI

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
                    Annotation("", coordinate: CLLocationCoordinate2D(latitude: property.latitude, longitude: property.longitude)) {
                        Button {
                            selectedProperty = property
                        } label: {
                            Text(property.formattedPrice)
                                .font(NomadTypography.meta)
                                .foregroundStyle(NomadColor.Background.surface)
                                .padding(.horizontal, NomadSpacing.sm)
                                .padding(.vertical, NomadSpacing.xs)
                                .background(NomadColor.Text.primary, in: .capsule)
                        }
                    }
                    .tag(property)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .ignoresSafeArea()

            VStack(spacing: NomadSpacing.sm) {
                HStack {
                    NomadIconCircleButton(icon: "xmark") {
                        dismiss()
                    }
                    .accessibilityLabel("Close map")

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.top, NomadSpacing.xs)

                Spacer(minLength: 0)

                if let property = selectedProperty {
                    Button {
                        showDetail = true
                    } label: {
                        mapPreviewCard(property)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, NomadSpacing.pageHorizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                NomadPrimaryCTA(title: "View list", icon: "list.bullet", style: .neutral) {
                    dismiss()
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.bottom, NomadSpacing.sm)
            }
        }
        .fullScreenCover(isPresented: $showDetail) {
            if let property = selectedProperty {
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private func mapPreviewCard(_ property: Property) -> some View {
        HStack(spacing: NomadSpacing.sm) {
            Color(.secondarySystemBackground)
                .frame(width: 88, height: 88)
                .overlay {
                    AsyncImage(url: URL(string: property.imageURLs.first ?? "")) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .allowsHitTesting(false)
                        } else {
                            Image(systemName: "photo")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: NomadRadius.control))

            VStack(alignment: .leading, spacing: NomadSpacing.xxs) {
                Text(property.fullFormattedPrice)
                    .font(NomadTypography.title2)
                    .foregroundStyle(NomadColor.Text.primary)

                Text(property.address)
                    .font(NomadTypography.caption)
                    .foregroundStyle(NomadColor.Text.secondary)
                    .lineLimit(1)

                Text(property.city)
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Accent.primary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(NomadColor.Text.tertiary)
                .frame(width: 44, height: 44)
        }
        .padding(NomadSpacing.md)
        .nomadCardSurface(level: .level2, radius: NomadRadius.hero)
    }
}
