//
//  PropertyDetailView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct PropertyDetailView: View {
    let property: Property
    let appVM: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex = 0
    @State private var showContact = false
    @State private var noteText = ""
    @State private var showAllFeatures = false
    @State private var expandedSections: Set<String> = []
    @State private var purchasePrice: Double = 0
    @State private var downPayment: Double = 20
    @State private var interestRate: String = "5.5"
    @State private var showMonthlyCosts = true

    var body: some View {
        ZStack {
            NomadTheme.offWhite.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    imageGallery
                    contentSection
                }
            }
            .ignoresSafeArea(edges: .top)

            VStack {
                Spacer()
                contactButton
            }
        }
        .onAppear {
            purchasePrice = Double(property.price)
            noteText = appVM.propertyNotes[property.id] ?? ""
        }
        .sheet(isPresented: $showContact) {
            ContactSellerSheet(property: property)
        }
        .sheet(isPresented: $showAllFeatures) {
            AllFeaturesSheet(property: property)
        }
    }

    private var imageGallery: some View {
        ZStack(alignment: .topLeading) {
            TabView(selection: $currentImageIndex) {
                ForEach(Array(property.imageURLs.enumerated()), id: \.offset) { index, url in
                    Color.black
                        .overlay {
                            AsyncImage(url: URL(string: url)) { phase in
                                if let image = phase.image {
                                    image.resizable().aspectRatio(contentMode: .fill).allowsHitTesting(false)
                                } else {
                                    ProgressView().tint(.white)
                                }
                            }
                        }
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 340)

            VStack {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.4), in: .circle)
                    }
                    Spacer()
                    ShareLink(item: "Check out this property: \(property.address), \(property.city) - \(property.fullFormattedPrice)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.black.opacity(0.4), in: .circle)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 56)

                Spacer()

                HStack {
                    Text("\(currentImageIndex + 1)/\(property.imageURLs.count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.black.opacity(0.5), in: .capsule)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerInfo
            detailsGrid
            expandableSection("Owner's comments") { ownerComments }
            noteSection
            expandableSection("Property features") { propertyFeatures }
            mortgageSection
            costsSection
            Spacer(minLength: 100)
        }
        .padding(20)
    }

    private var headerInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(property.fullFormattedPrice)
                    .font(.title.bold())
                    .foregroundStyle(NomadTheme.darkText)
                if property.listingType == .rent {
                    Text("/mo").font(.subheadline).foregroundStyle(NomadTheme.lightGrey)
                }
                Spacer()
                Button { appVM.toggleSaved(property) } label: {
                    Image(systemName: appVM.isSaved(property) ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundStyle(appVM.isSaved(property) ? .red : NomadTheme.lightGrey)
                }
            }

            Text("\(property.propertyType.rawValue) for \(property.listingType.rawValue.lowercased())")
                .font(.subheadline)
                .foregroundStyle(NomadTheme.darkGreen)

            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption)
                    .foregroundStyle(NomadTheme.darkGreen)
                Text("\(property.address), \(property.city), \(property.region)")
                    .font(.subheadline)
                    .foregroundStyle(NomadTheme.lightGrey)
            }
        }
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            if property.bedrooms > 0 {
                DetailCard(icon: "bed.double.fill", title: "Bedrooms", value: "\(property.bedrooms)")
            }
            if property.bathrooms > 0 {
                DetailCard(icon: "shower.fill", title: "Bathrooms", value: "\(property.bathrooms)")
            }
            if property.levels > 0 {
                DetailCard(icon: "building.2.fill", title: "Levels", value: "\(property.levels)")
            }
            if property.squareFeet > 0 {
                DetailCard(icon: "square.dashed", title: "Total Area", value: "\(property.squareFeet) ft²")
            }
        }
    }

    @ViewBuilder
    private func expandableSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        let isExpanded = expandedSections.contains(title)
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.snappy) {
                    if isExpanded { expandedSections.remove(title) }
                    else { expandedSections.insert(title) }
                }
            } label: {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(NomadTheme.darkText)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NomadTheme.lightGrey)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }

            if isExpanded {
                content()
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
        .background(.white, in: .rect(cornerRadius: 16))
    }

    private var ownerComments: some View {
        Text(property.ownerComments)
            .font(.body)
            .foregroundStyle(NomadTheme.darkText)
            .lineSpacing(4)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add note")
                .font(.headline)
                .foregroundStyle(NomadTheme.darkText)

            TextEditor(text: $noteText)
                .frame(minHeight: 80)
                .padding(12)
                .background(.white, in: .rect(cornerRadius: 16))
                .overlay { RoundedRectangle(cornerRadius: 16).stroke(Color(.separator), lineWidth: 1) }
                .onChange(of: noteText) { _, newValue in
                    appVM.propertyNotes[property.id] = newValue.isEmpty ? nil : newValue
                }
        }
    }

    private var propertyFeatures: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(property.features.keys.sorted().prefix(5)), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(.subheadline)
                        .foregroundStyle(NomadTheme.lightGrey)
                    Spacer()
                    Text(property.features[key] ?? "")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(NomadTheme.darkText)
                }
                if key != property.features.keys.sorted().prefix(5).last {
                    Divider()
                }
            }

            Button { showAllFeatures = true } label: {
                HStack {
                    Text("See all property features")
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundStyle(NomadTheme.darkGreen)
                .padding(.top, 8)
            }
        }
    }

    private var mortgageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mortgage Calculator")
                .font(.headline)
                .foregroundStyle(NomadTheme.darkText)

            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Purchase Price")
                            .font(.subheadline)
                            .foregroundStyle(NomadTheme.lightGrey)
                        Spacer()
                        Text(Int(purchasePrice).formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(.subheadline.weight(.medium))
                    }
                    Slider(value: $purchasePrice, in: 50000...5000000, step: 5000)
                        .tint(NomadTheme.darkGreen)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Down Payment")
                            .font(.subheadline)
                            .foregroundStyle(NomadTheme.lightGrey)
                        Spacer()
                        Text("\(Int(downPayment))%")
                            .font(.subheadline.weight(.medium))
                    }
                    Slider(value: $downPayment, in: 5...50, step: 1)
                        .tint(NomadTheme.darkGreen)
                }

                HStack {
                    Text("Interest Rate")
                        .font(.subheadline)
                        .foregroundStyle(NomadTheme.lightGrey)
                    Spacer()
                    TextField("5.5", text: $interestRate)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                        .font(.subheadline.weight(.medium))
                    Text("%")
                        .font(.subheadline)
                        .foregroundStyle(NomadTheme.lightGrey)
                }

                Divider()

                let monthly = calculateMortgage()
                HStack {
                    Text("Est. Monthly Payment")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(monthly.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(.title3.bold())
                        .foregroundStyle(NomadTheme.darkGreen)
                }
            }
            .padding(16)
            .background(.white, in: .rect(cornerRadius: 16))
        }
    }

    private func calculateMortgage() -> Double {
        let principal = purchasePrice * (1 - downPayment / 100)
        let rate = (Double(interestRate) ?? 5.5) / 100 / 12
        let payments: Double = 25 * 12
        guard rate > 0 else { return principal / payments }
        return principal * (rate * pow(1 + rate, payments)) / (pow(1 + rate, payments) - 1)
    }

    private var costsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Costs and expenses")
                    .font(.headline)
                    .foregroundStyle(NomadTheme.darkText)

                Spacer()

                Picker("", selection: $showMonthlyCosts) {
                    Text("Monthly").tag(true)
                    Text("Yearly").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            let multiplier = showMonthlyCosts ? 1 : 12
            let total = (property.monthlyTaxes + property.monthlyElectricity + property.monthlyCondoFees) * multiplier

            VStack(spacing: 12) {
                HStack {
                    Text("Total")
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text("$\(total)")
                        .font(.body.bold())
                        .foregroundStyle(NomadTheme.darkGreen)
                }

                Divider()

                CostRow(title: "Property taxes", amount: property.monthlyTaxes * multiplier)
                if property.monthlyElectricity > 0 {
                    CostRow(title: "Electricity", amount: property.monthlyElectricity * multiplier)
                }
                if property.monthlyCondoFees > 0 {
                    CostRow(title: "Condo fees", amount: property.monthlyCondoFees * multiplier)
                }
            }
            .padding(16)
            .background(.white, in: .rect(cornerRadius: 16))
        }
    }

    private var contactButton: some View {
        Button { showContact = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "message.fill")
                Text("Contact Seller")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.black, in: .capsule)
            .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

struct DetailCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(NomadTheme.darkGreen)
            Text(value)
                .font(.headline)
                .foregroundStyle(NomadTheme.darkText)
            Text(title)
                .font(.caption)
                .foregroundStyle(NomadTheme.lightGrey)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(.white, in: .rect(cornerRadius: 16))
    }
}

struct CostRow: View {
    let title: String
    let amount: Int

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(NomadTheme.lightGrey)
            Spacer()
            Text("$\(amount)")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(NomadTheme.darkText)
        }
    }
}

struct ContactSellerSheet: View {
    let property: Property
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [(String, Bool)] = []
    @State private var sent = false

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                            HStack {
                                if msg.1 { Spacer() }
                                Text(msg.0)
                                    .font(.body)
                                    .padding(12)
                                    .background(msg.1 ? NomadTheme.darkGreen : Color(.secondarySystemBackground), in: .rect(cornerRadius: 18))
                                    .foregroundStyle(msg.1 ? .white : NomadTheme.darkText)
                                if !msg.1 { Spacer() }
                            }
                        }
                    }
                    .padding(16)
                }

                HStack(spacing: 10) {
                    TextField("Type a message...", text: $messageText)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: .capsule)

                    Button {
                        guard !messageText.isEmpty else { return }
                        messages.append((messageText, true))
                        let userMsg = messageText
                        messageText = ""
                        Task {
                            try? await Task.sleep(for: .seconds(1))
                            messages.append(("Thank you for your interest in \(property.address)! I'll get back to you within 24 hours.", false))
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(NomadTheme.darkGreen)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .navigationTitle("Contact Seller")
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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

struct AllFeaturesSheet: View {
    let property: Property
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(property.features.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                            .foregroundStyle(NomadTheme.lightGrey)
                        Spacer()
                        Text(property.features[key] ?? "")
                            .fontWeight(.medium)
                    }
                }
            }
            .navigationTitle("All Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
