import SwiftUI

struct MatchView: View {
    @Environment(AppViewModel.self) private var appVM

    @State private var currentIndex = 0
    @State private var currentImageIndex = 0
    @State private var offset: CGSize = .zero
    @State private var showExpanded = false
    @State private var showFilter = false
    @State private var filter = PropertyFilter()

    private var availableProperties: [Property] {
        appVM.listingsService.properties.filter {
            !appVM.dislikedPropertyIDs.contains($0.id) && $0.listingType == .sale
        }
    }

    private var currentProperty: Property? {
        guard currentIndex < availableProperties.count else { return nil }
        return availableProperties[currentIndex]
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let property = currentProperty {
                cardView(property)
                    .offset(x: offset.width)
                    .rotationEffect(.degrees(Double(offset.width / 42)))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                offset = value.translation
                            }
                            .onEnded { value in
                                handleSwipe(value, property: property)
                            }
                    )
                    .animation(.snappy, value: offset)

                overlayIndicators

                VStack(spacing: 0) {
                    topNav(property)
                    Spacer(minLength: 0)
                    profileOverlay(property)
                    actionBar(property)
                }
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showFilter) {
            FilterView(filter: $filter, onApply: { showFilter = false })
        }
        .sheet(isPresented: $showExpanded) {
            if let property = currentProperty {
                PropertyDetailView(property: property, appVM: appVM)
            }
        }
    }

    private func cardView(_ property: Property) -> some View {
        Color.black
            .overlay {
                AsyncImage(url: URL(string: property.imageURLs[safe: currentImageIndex] ?? property.imageURLs.first ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } else {
                        ProgressView().tint(.white)
                    }
                }
            }
            .clipShape(.rect(cornerRadius: NomadRadius.hero))
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                    .clipShape(.rect(cornerRadius: NomadRadius.hero))
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, NomadSpacing.xs)
            .padding(.top, 58)
            .padding(.bottom, 112)
            .onTapGesture { location in
                let midX = UIScreen.main.bounds.width / 2
                withAnimation(.snappy) {
                    if location.x < midX {
                        currentImageIndex = max(0, currentImageIndex - 1)
                    } else {
                        currentImageIndex = min(property.imageURLs.count - 1, currentImageIndex + 1)
                    }
                }
            }
    }

    @ViewBuilder
    private var overlayIndicators: some View {
        if offset.width > 50 {
            Text("LIKE")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(NomadColor.Accent.primary)
                .padding(.horizontal, NomadSpacing.sm)
                .padding(.vertical, NomadSpacing.xs)
                .overlay {
                    RoundedRectangle(cornerRadius: NomadRadius.control)
                        .stroke(NomadColor.Accent.primary, lineWidth: 3)
                }
                .rotationEffect(.degrees(-14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, NomadSpacing.xxxl)
                .padding(.top, 116)
                .transition(.opacity)
        }

        if offset.width < -50 {
            Text("NOPE")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.red)
                .padding(.horizontal, NomadSpacing.sm)
                .padding(.vertical, NomadSpacing.xs)
                .overlay {
                    RoundedRectangle(cornerRadius: NomadRadius.control)
                        .stroke(.red, lineWidth: 3)
                }
                .rotationEffect(.degrees(14))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.horizontal, NomadSpacing.xxxl)
                .padding(.top, 116)
                .transition(.opacity)
        }
    }

    private func topNav(_ property: Property) -> some View {
        HStack {
            NomadIconCircleButton(icon: "slider.horizontal.3", emphasis: .overlay) {
                showFilter = true
            }
            .accessibilityLabel("Open filters")

            Spacer(minLength: NomadSpacing.sm)

            HStack(spacing: NomadSpacing.xxs) {
                ForEach(0..<property.imageURLs.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentImageIndex ? .white : .white.opacity(0.35))
                        .frame(width: index == currentImageIndex ? 20 : 8, height: 4)
                }
            }

            Spacer(minLength: NomadSpacing.sm)

            ShareLink(item: "\(property.address), \(property.city) - \(property.fullFormattedPrice)") {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.28), in: .circle)
            }
            .accessibilityLabel("Share listing")
        }
        .padding(.horizontal, NomadSpacing.lg)
        .padding(.top, NomadSpacing.sm)
    }

    private func profileOverlay(_ property: Property) -> some View {
        HStack(alignment: .bottom, spacing: NomadSpacing.md) {
            VStack(alignment: .leading, spacing: NomadSpacing.xs) {
                Text(property.fullFormattedPrice)
                    .font(NomadTypography.title1)
                    .foregroundStyle(.white)

                HStack(spacing: NomadSpacing.xs) {
                    if property.bedrooms > 0 {
                        Text("\(property.bedrooms) beds")
                    }
                    if property.bathrooms > 0 {
                        Text("•")
                        Text("\(property.bathrooms) baths")
                    }
                    if property.squareFeet > 0 {
                        Text("•")
                        Text("\(property.squareFeet) sqft")
                    }
                }
                .font(NomadTypography.body)
                .foregroundStyle(.white.opacity(0.86))

                Text(property.address + ", " + property.city)
                    .font(NomadTypography.caption)
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            NomadIconCircleButton(icon: "chevron.up", emphasis: .overlay) {
                showExpanded = true
            }
            .accessibilityLabel("Expand details")
        }
        .padding(.horizontal, NomadSpacing.xl)
        .padding(.bottom, NomadSpacing.md)
    }

    private func actionBar(_ property: Property) -> some View {
        HStack(spacing: NomadSpacing.lg) {
            ActionButton(icon: "arrow.uturn.backward", size: .small) {
                goBack()
            }

            ActionButton(icon: "xmark", size: .large, color: .red) {
                swipeLeft(property)
            }

            ActionButton(icon: "heart.fill", size: .large, color: NomadColor.Accent.primary) {
                swipeRight(property)
            }

            ActionButton(icon: "arrow.right", size: .small) {
                skip()
            }
        }
        .padding(.bottom, NomadSpacing.xl)
    }

    private var emptyState: some View {
        VStack(spacing: NomadSpacing.md) {
            Image(systemName: "house.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))

            Text("No more properties")
                .font(NomadTypography.title2)
                .foregroundStyle(.white)

            Text("Check back later for new listings")
                .font(NomadTypography.body)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, NomadSpacing.pageHorizontal)
    }

    private func handleSwipe(_ value: DragGesture.Value, property: Property) {
        if value.translation.width > 120 {
            swipeRight(property)
        } else if value.translation.width < -120 {
            swipeLeft(property)
        } else if value.translation.height < -120 {
            showExpanded = true
            offset = .zero
        } else {
            offset = .zero
        }
    }

    private func swipeRight(_ property: Property) {
        withAnimation(.snappy) {
            offset = CGSize(width: 500, height: 0)
        }
        appVM.toggleSaved(property)
        advanceCard()
    }

    private func swipeLeft(_ property: Property) {
        withAnimation(.snappy) {
            offset = CGSize(width: -500, height: 0)
        }
        appVM.dislike(property)
        advanceCard()
    }

    private func skip() {
        withAnimation(.snappy) {
            offset = CGSize(width: 500, height: 0)
        }
        advanceCard()
    }

    private func goBack() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        currentImageIndex = 0
        offset = .zero
    }

    private func advanceCard() {
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            currentIndex += 1
            currentImageIndex = 0
            offset = .zero
        }
    }
}

struct ActionButton: View {
    let icon: String
    let size: ButtonSize
    var color: Color = .white
    let action: () -> Void

    nonisolated enum ButtonSize {
        case small
        case large

        var frame: CGFloat {
            switch self {
            case .small: return 46
            case .large: return 62
            }
        }

        var font: Font {
            switch self {
            case .small: return .system(size: 20, weight: .semibold)
            case .large: return .system(size: 26, weight: .bold)
            }
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(size.font)
                .foregroundStyle(color)
                .frame(width: size.frame, height: size.frame)
                .background(.white.opacity(0.16), in: .circle)
                .overlay {
                    Circle()
                        .stroke(color.opacity(0.35), lineWidth: 1.5)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
