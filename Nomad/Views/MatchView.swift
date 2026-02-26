//
//  MatchView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct MatchView: View {
    @Environment(AppViewModel.self) private var appVM
    @State private var currentIndex = 0
    @State private var currentImageIndex = 0
    @State private var offset: CGSize = .zero
    @State private var showExpanded = false
    @State private var showFilter = false
    @State private var filter = PropertyFilter()
    @State private var selectedProperty: Property?

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
                    .rotationEffect(.degrees(Double(offset.width / 40)))
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

                VStack {
                    topNav(property)
                    Spacer()
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
                        image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                    } else {
                        ProgressView().tint(.white)
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 20))
            .overlay(alignment: .bottom) {
                LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                    .clipShape(.rect(cornerRadius: 20))
                    .allowsHitTesting(false)
            }
            .padding(.horizontal, 8)
            .padding(.top, 60)
            .padding(.bottom, 100)
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
            VStack {
                Text("LIKE")
                    .font(.title.bold())
                    .foregroundStyle(.green)
                    .padding(8)
                    .overlay { RoundedRectangle(cornerRadius: 8).stroke(.green, lineWidth: 3) }
                    .rotationEffect(.degrees(-15))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(40)
            .padding(.top, 60)
            .transition(.opacity)
        }

        if offset.width < -50 {
            VStack {
                Text("NOPE")
                    .font(.title.bold())
                    .foregroundStyle(.red)
                    .padding(8)
                    .overlay { RoundedRectangle(cornerRadius: 8).stroke(.red, lineWidth: 3) }
                    .rotationEffect(.degrees(15))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(40)
            .padding(.top, 60)
            .transition(.opacity)
        }
    }

    private func topNav(_ property: Property) -> some View {
        HStack {
            Button { showFilter = true } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.2), in: .circle)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(0..<property.imageURLs.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentImageIndex ? .white : .white.opacity(0.4))
                        .frame(width: index == currentImageIndex ? 20 : 8, height: 4)
                }
            }

            Spacer()

            ShareLink(item: "\(property.address), \(property.city) - \(property.fullFormattedPrice)") {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.2), in: .circle)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func profileOverlay(_ property: Property) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(property.fullFormattedPrice)
                    .font(.title.bold())
                    .foregroundStyle(.white)

                HStack(spacing: 8) {
                    if property.bedrooms > 0 {
                        Text("\(property.bedrooms) beds")
                    }
                    if property.bathrooms > 0 {
                        Text("·")
                        Text("\(property.bathrooms) baths")
                    }
                    if property.squareFeet > 0 {
                        Text("·")
                        Text("\(property.squareFeet) sqft")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))

                Text(property.address + ", " + property.city)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button { showExpanded = true } label: {
                Image(systemName: "chevron.up")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(.white.opacity(0.2), in: .circle)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    private func actionBar(_ property: Property) -> some View {
        HStack(spacing: 20) {
            ActionButton(icon: "arrow.uturn.backward", size: .small) {
                goBack()
            }

            ActionButton(icon: "xmark", size: .large, color: .red) {
                swipeLeft(property)
            }

            ActionButton(icon: "heart.fill", size: .large, color: .green) {
                swipeRight(property)
            }

            ActionButton(icon: "arrow.right", size: .small) {
                skip()
            }
        }
        .padding(.bottom, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.5))
            Text("No more properties")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
            Text("Check back later for new listings")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
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
        withAnimation(.snappy) { offset = CGSize(width: 500, height: 0) }
        appVM.toggleSaved(property)
        advanceCard()
    }

    private func swipeLeft(_ property: Property) {
        withAnimation(.snappy) { offset = CGSize(width: -500, height: 0) }
        appVM.dislike(property)
        advanceCard()
    }

    private func skip() {
        withAnimation(.snappy) { offset = CGSize(width: 500, height: 0) }
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

    nonisolated enum ButtonSize { case small, large }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(size == .large ? .title2.weight(.bold) : .body.weight(.medium))
                .foregroundStyle(color)
                .frame(width: size == .large ? 60 : 44, height: size == .large ? 60 : 44)
                .background(.white.opacity(0.15), in: .circle)
                .overlay { Circle().stroke(color.opacity(0.3), lineWidth: 1.5) }
        }
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
