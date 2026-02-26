import SwiftUI

struct FilterView: View {
    @Binding var filter: PropertyFilter
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: NomadSpacing.xl) {
                    listingTypeSection
                    propertyTypeSection
                    priceSection

                    if !filter.isLotOnly {
                        featuresSection
                    }

                    otherSection

                    if !filter.isLotOnly {
                        yearSection
                        constructionTypeSection
                        livingAreaSection
                    }

                    landAreaSection
                    moveInDateSection
                    listingDateSection
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.top, NomadSpacing.xl)
                .padding(.bottom, NomadSpacing.xxl)
            }
            .safeAreaInset(edge: .bottom) {
                bottomActionBar
            }
            .nomadScreenBackground()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NomadIconCircleButton(icon: "xmark") { dismiss() }
                        .accessibilityLabel("Close filters")
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    private var listingTypeSection: some View {
        FilterCard {
            Picker("Listing Type", selection: $filter.listingType) {
                ForEach(ListingType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var propertyTypeSection: some View {
        FilterCard(title: "Property Type") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: NomadSpacing.xs)], spacing: NomadSpacing.xs) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    NomadChip(text: type.rawValue, isSelected: filter.propertyTypes.contains(type)) {
                        if filter.propertyTypes.contains(type) {
                            filter.propertyTypes.remove(type)
                        } else {
                            filter.propertyTypes.insert(type)
                        }
                    }
                }
            }
        }
    }

    private var priceSection: some View {
        FilterCard(title: "Price") {
            HStack(spacing: NomadSpacing.sm) {
                NumberField(placeholder: "Min", value: $filter.minPrice)
                Text("–")
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Text.tertiary)
                NumberField(placeholder: "Max", value: $filter.maxPrice)
            }
        }
    }

    private var featuresSection: some View {
        FilterCard(title: "Features") {
            VStack(alignment: .leading, spacing: NomadSpacing.md) {
                FeatureRow(title: "Bedrooms", options: ["1", "1+", "2", "2+", "3", "3+", "4", "4+", "5", "5+"], selection: $filter.bedrooms)
                FeatureRow(title: "Bathrooms", options: ["1+", "2+", "3+", "4+", "5+"], selection: $filter.bathrooms)
                FeatureRow(title: "Parking", options: ["1+", "2+", "3+", "4+", "5+"], selection: $filter.parkingSpaces)
                FeatureRow(title: "Garages", options: ["1+", "2+", "3+", "4+", "5+"], selection: $filter.garages)
            }
        }
    }

    private var otherSection: some View {
        FilterCard(title: "Other") {
            VStack(spacing: 0) {
                if !filter.isLotOnly {
                    FilterToggle(title: "Pool", isOn: $filter.hasPool)
                    FilterToggle(title: "Elevator", isOn: $filter.hasElevator)
                    FilterToggle(title: "Adapted for reduced mobility", isOn: $filter.adaptedMobility)
                }

                FilterToggle(title: "Waterfront", isOn: $filter.isWaterfront)
                FilterToggle(title: "Access to waterfront", isOn: $filter.accessWaterfront)
                FilterToggle(title: "Navigable body of water", isOn: $filter.navigableWater)
                FilterToggle(title: "Resort", isOn: $filter.isResort)

                if !filter.isLotOnly {
                    FilterToggle(title: "Pets allowed", isOn: $filter.isPetFriendly)
                    FilterToggle(title: "Smoking allowed", isOn: $filter.smokingAllowed)
                    FilterToggle(title: "Open houses", isOn: $filter.openHouses)
                }

                FilterToggle(title: "Repossession", isOn: $filter.repossession, showDivider: false)
            }
        }
    }

    private var yearSection: some View {
        FilterCard(title: "Year of Construction") {
            HStack(spacing: NomadSpacing.sm) {
                NumberField(placeholder: "Min year", value: $filter.minYear)
                Text("–")
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Text.tertiary)
                NumberField(placeholder: "Max year", value: $filter.maxYear)
            }
        }
    }

    private var constructionTypeSection: some View {
        FilterCard(title: "Type of Construction") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: NomadSpacing.xs)], spacing: NomadSpacing.xs) {
                ForEach(ConstructionType.allCases, id: \.self) { type in
                    NomadChip(text: type.rawValue, isSelected: filter.constructionTypes.contains(type)) {
                        if filter.constructionTypes.contains(type) {
                            filter.constructionTypes.remove(type)
                        } else {
                            filter.constructionTypes.insert(type)
                        }
                    }
                }
            }
        }
    }

    private var livingAreaSection: some View {
        FilterCard(title: "Living Area (sq ft)") {
            HStack(spacing: NomadSpacing.sm) {
                NumberField(placeholder: "Min", value: $filter.minLivingArea)
                Text("–")
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Text.tertiary)
                NumberField(placeholder: "Max", value: $filter.maxLivingArea)
            }
        }
    }

    private var landAreaSection: some View {
        FilterCard(title: "Land Area (sq ft)") {
            HStack(spacing: NomadSpacing.sm) {
                NumberField(placeholder: "Min", value: $filter.minLandArea)
                Text("–")
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Text.tertiary)
                NumberField(placeholder: "Max", value: $filter.maxLandArea)
            }
        }
    }

    private var moveInDateSection: some View {
        FilterCard(title: "Move-in Date") {
            HStack(spacing: NomadSpacing.sm) {
                DatePickerField(title: "Soonest", date: $filter.moveInDateStart)
                DatePickerField(title: "Latest", date: $filter.moveInDateEnd)
            }
        }
    }

    private var listingDateSection: some View {
        FilterCard(title: "Listing Date") {
            HStack(spacing: NomadSpacing.sm) {
                DatePickerField(title: "Most recent", date: $filter.listingDateStart)
                DatePickerField(title: "Oldest", date: $filter.listingDateEnd)
            }
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: NomadSpacing.sm) {
            NomadPrimaryCTA(title: "Apply Filters", icon: nil) {
                onApply()
            }

            Button {
                filter.reset()
            } label: {
                Text("Reset All")
                    .font(NomadTypography.bodyStrong)
                    .foregroundStyle(NomadColor.Accent.primary)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(NomadColor.Background.surface, in: .capsule)
                    .overlay {
                        Capsule().stroke(NomadColor.Border.default, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, NomadSpacing.pageHorizontal)
        .padding(.vertical, NomadSpacing.sm)
        .background(.ultraThinMaterial)
    }
}

private struct FilterCard<Content: View>: View {
    var title: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.sm) {
            if let title {
                Text(title)
                    .font(NomadTypography.section)
                    .foregroundStyle(NomadColor.Text.primary)
            }

            content
        }
        .padding(NomadSpacing.md)
        .nomadCardSurface(level: .level1, radius: NomadRadius.card)
    }
}

private struct FilterToggle: View {
    let title: String
    @Binding var isOn: Bool
    var showDivider = true

    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(NomadTypography.body)
                .foregroundStyle(NomadColor.Text.primary)
        }
        .tint(NomadColor.Accent.primary)
        .padding(.horizontal, NomadSpacing.sm)
        .padding(.vertical, NomadSpacing.sm)
        .background(
            VStack {
                Spacer()
                if showDivider {
                    Divider().overlay(NomadColor.Border.default)
                }
            }
        )
    }
}

private struct FeatureRow: View {
    let title: String
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.xs) {
            Text(title)
                .font(NomadTypography.bodyStrong)
                .foregroundStyle(NomadColor.Text.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NomadSpacing.xs) {
                    ForEach(options, id: \.self) { option in
                        NomadChip(text: option, isSelected: selection == option, isCompact: true) {
                            selection = selection == option ? nil : option
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }
}

private struct NumberField: View {
    let placeholder: String
    @Binding var value: Int?
    @State private var text = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .font(NomadTypography.body)
            .keyboardType(.numberPad)
            .padding(.horizontal, NomadSpacing.md)
            .frame(height: 48)
            .background(NomadColor.Background.surfaceMuted, in: .rect(cornerRadius: NomadRadius.control))
            .overlay {
                RoundedRectangle(cornerRadius: NomadRadius.control)
                    .stroke(NomadColor.Border.default, lineWidth: 1)
            }
            .onChange(of: text) { _, newValue in
                value = Int(newValue)
            }
            .onAppear {
                if let value {
                    text = "\(value)"
                }
            }
    }
}

private struct DatePickerField: View {
    let title: String
    @Binding var date: Date?

    @State private var showPicker = false
    @State private var tempDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.xxs) {
            Text(title)
                .font(NomadTypography.meta)
                .foregroundStyle(NomadColor.Text.tertiary)

            Button {
                showPicker.toggle()
            } label: {
                Text(date?.formatted(date: .abbreviated, time: .omitted) ?? "Any")
                    .font(NomadTypography.body)
                    .foregroundStyle(date != nil ? NomadColor.Text.primary : NomadColor.Text.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, NomadSpacing.md)
                    .frame(height: 48)
                    .background(NomadColor.Background.surfaceMuted, in: .rect(cornerRadius: NomadRadius.control))
                    .overlay {
                        RoundedRectangle(cornerRadius: NomadRadius.control)
                            .stroke(NomadColor.Border.default, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                DatePicker("", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Clear") {
                                date = nil
                                showPicker = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                date = tempDate
                                showPicker = false
                            }
                        }
                    }
            }
            .presentationDetents([.medium])
        }
    }
}
