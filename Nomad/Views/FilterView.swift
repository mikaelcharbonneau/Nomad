//
//  FilterView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct FilterView: View {
    @Binding var filter: PropertyFilter
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    listingTypeToggle
                    propertyTypeSection
                    priceSection
                    if !filter.isLotOnly { featuresSection }
                    otherSection
                    if !filter.isLotOnly { yearSection }
                    if !filter.isLotOnly { constructionTypeSection }
                    if !filter.isLotOnly { livingAreaSection }
                    landAreaSection
                    moveInDateSection
                    listingDateSection

                    Button {
                        onApply()
                    } label: {
                        Text("Apply Filters")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle())
                    .padding(.top, 8)

                    Button {
                        filter.reset()
                    } label: {
                        Text("Reset All")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PillButtonStyle(filled: false))
                }
                .padding(20)
            }
            .background(NomadTheme.offWhite)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(NomadTheme.lightGrey)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    private var listingTypeToggle: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("", selection: $filter.listingType) {
                ForEach(ListingType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var propertyTypeSection: some View {
        FilterSection(title: "Property Type") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: filter.propertyTypes.contains(type),
                        action: {
                            if filter.propertyTypes.contains(type) {
                                filter.propertyTypes.remove(type)
                            } else {
                                filter.propertyTypes.insert(type)
                            }
                        }
                    )
                }
            }
        }
    }

    private var priceSection: some View {
        FilterSection(title: "Price") {
            HStack(spacing: 12) {
                NumberField(placeholder: "Min", value: $filter.minPrice)
                Text("–").foregroundStyle(NomadTheme.lightGrey)
                NumberField(placeholder: "Max", value: $filter.maxPrice)
            }
        }
    }

    private var featuresSection: some View {
        FilterSection(title: "Features") {
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(title: "Bedrooms", options: ["1", "1+", "2", "2+", "3", "3+", "4", "4+", "5", "5+"], selection: $filter.bedrooms)
                FeatureRow(title: "Bathrooms", options: ["1+", "2+", "3+", "4+", "5+"], selection: $filter.bathrooms)
                FeatureRow(title: "Parking", options: ["1+", "2+", "3+", "4+", "5+"], selection: $filter.parkingSpaces)
                FeatureRow(title: "Garages", options: ["1+", "2+", "3+", "4+", "5+"], selection: $filter.garages)
            }
        }
    }

    private var otherSection: some View {
        FilterSection(title: "Other") {
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
                FilterToggle(title: "Repossession", isOn: $filter.repossession)
            }
            .background(.white, in: .rect(cornerRadius: 16))
        }
    }

    private var yearSection: some View {
        FilterSection(title: "Year of Construction") {
            HStack(spacing: 12) {
                NumberField(placeholder: "Min year", value: $filter.minYear)
                Text("–").foregroundStyle(NomadTheme.lightGrey)
                NumberField(placeholder: "Max year", value: $filter.maxYear)
            }
        }
    }

    private var constructionTypeSection: some View {
        FilterSection(title: "Type of Construction") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
                ForEach(ConstructionType.allCases, id: \.self) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: filter.constructionTypes.contains(type),
                        action: {
                            if filter.constructionTypes.contains(type) {
                                filter.constructionTypes.remove(type)
                            } else {
                                filter.constructionTypes.insert(type)
                            }
                        }
                    )
                }
            }
        }
    }

    private var livingAreaSection: some View {
        FilterSection(title: "Living Area (sq ft)") {
            HStack(spacing: 12) {
                NumberField(placeholder: "Min", value: $filter.minLivingArea)
                Text("–").foregroundStyle(NomadTheme.lightGrey)
                NumberField(placeholder: "Max", value: $filter.maxLivingArea)
            }
        }
    }

    private var landAreaSection: some View {
        FilterSection(title: "Land Area (sq ft)") {
            HStack(spacing: 12) {
                NumberField(placeholder: "Min", value: $filter.minLandArea)
                Text("–").foregroundStyle(NomadTheme.lightGrey)
                NumberField(placeholder: "Max", value: $filter.maxLandArea)
            }
        }
    }

    private var moveInDateSection: some View {
        FilterSection(title: "Move-in Date") {
            HStack(spacing: 12) {
                DatePickerField(title: "Soonest", date: $filter.moveInDateStart)
                DatePickerField(title: "Latest", date: $filter.moveInDateEnd)
            }
        }
    }

    private var listingDateSection: some View {
        FilterSection(title: "Listing Date") {
            HStack(spacing: 12) {
                DatePickerField(title: "Most recent", date: $filter.listingDateStart)
                DatePickerField(title: "Oldest", date: $filter.listingDateEnd)
            }
        }
    }
}

struct FilterSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(NomadTheme.darkText)
            content
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? NomadTheme.darkGreen : .white, in: .capsule)
                .foregroundStyle(isSelected ? .white : NomadTheme.darkText)
                .overlay { Capsule().stroke(isSelected ? .clear : Color(.separator), lineWidth: 1) }
        }
    }
}

struct FilterToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(title, isOn: $isOn)
            .tint(NomadTheme.darkGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }
}

struct FeatureRow: View {
    let title: String
    let options: [String]
    @Binding var selection: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NomadTheme.darkText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = selection == option ? nil : option
                        } label: {
                            Text(option)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selection == option ? NomadTheme.darkGreen : .white, in: .capsule)
                                .foregroundStyle(selection == option ? .white : NomadTheme.darkText)
                                .overlay { Capsule().stroke(selection == option ? .clear : Color(.separator), lineWidth: 1) }
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 0)
        }
    }
}

struct NumberField: View {
    let placeholder: String
    @Binding var value: Int?
    @State private var text = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.numberPad)
            .padding(12)
            .background(.white, in: .capsule)
            .overlay { Capsule().stroke(Color(.separator), lineWidth: 1) }
            .onChange(of: text) { _, newValue in
                value = Int(newValue)
            }
            .onAppear {
                if let value { text = "\(value)" }
            }
    }
}

struct DatePickerField: View {
    let title: String
    @Binding var date: Date?
    @State private var showPicker = false
    @State private var tempDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(NomadTheme.lightGrey)

            Button {
                showPicker.toggle()
            } label: {
                Text(date?.formatted(date: .abbreviated, time: .omitted) ?? "Any")
                    .font(.subheadline)
                    .foregroundStyle(date != nil ? NomadTheme.darkText : NomadTheme.lightGrey)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white, in: .rect(cornerRadius: 12))
                    .overlay { RoundedRectangle(cornerRadius: 12).stroke(Color(.separator), lineWidth: 1) }
            }
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
