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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                imageGallery

                VStack(alignment: .leading, spacing: NomadSpacing.xl) {
                    headerCard
                    detailsGrid
                    expandableSection("Owner's comments") { ownerComments }
                    noteSection
                    expandableSection("Property features") { propertyFeatures }
                    mortgageSection
                    costsSection
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.top, NomadSpacing.xl)
                .padding(.bottom, NomadSpacing.xl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            NomadPrimaryCTA(title: "Contact Seller", icon: "message.fill", style: .neutral) {
                showContact = true
            }
            .padding(.horizontal, NomadSpacing.pageHorizontal)
            .padding(.vertical, NomadSpacing.sm)
            .background(.ultraThinMaterial)
        }
        .nomadScreenBackground()
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
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .allowsHitTesting(false)
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
            .frame(height: 360)

            VStack(spacing: 0) {
                HStack {
                    NomadIconCircleButton(icon: "xmark", emphasis: .overlay) {
                        dismiss()
                    }
                    .accessibilityLabel("Close")

                    Spacer(minLength: 0)

                    ShareLink(item: "Check out this property: \(property.address), \(property.city) - \(property.fullFormattedPrice)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.28), in: .circle)
                    }
                    .accessibilityLabel("Share")
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.top, 58)

                Spacer(minLength: 0)

                HStack {
                    Text("\(currentImageIndex + 1)/\(max(property.imageURLs.count, 1))")
                        .font(NomadTypography.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, NomadSpacing.sm)
                        .padding(.vertical, NomadSpacing.xs)
                        .background(.black.opacity(0.45), in: .capsule)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.bottom, NomadSpacing.sm)
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: NomadSpacing.xs) {
                Text(property.fullFormattedPrice)
                    .font(NomadTypography.title1)
                    .foregroundStyle(NomadColor.Text.primary)

                if property.listingType == .rent {
                    Text("/mo")
                        .font(NomadTypography.body)
                        .foregroundStyle(NomadColor.Text.secondary)
                }

                Spacer(minLength: 0)

                Button {
                    appVM.toggleSaved(property)
                } label: {
                    Image(systemName: appVM.isSaved(property) ? "heart.fill" : "heart")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(appVM.isSaved(property) ? .red : NomadColor.Text.tertiary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }

            Text("\(property.propertyType.rawValue) for \(property.listingType.rawValue.lowercased())")
                .font(NomadTypography.bodyStrong)
                .foregroundStyle(NomadColor.Accent.primary)

            HStack(spacing: NomadSpacing.xxs) {
                Image(systemName: "mappin.and.ellipse")
                    .font(NomadTypography.meta)
                    .foregroundStyle(NomadColor.Accent.primary)

                Text("\(property.address), \(property.city), \(property.region)")
                    .font(NomadTypography.body)
                    .foregroundStyle(NomadColor.Text.secondary)
            }
        }
        .padding(NomadSpacing.md)
        .nomadCardSurface(level: .level1, radius: NomadRadius.card)
    }

    private var detailsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: NomadSpacing.sm) {
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
                    if isExpanded {
                        expandedSections.remove(title)
                    } else {
                        expandedSections.insert(title)
                    }
                }
            } label: {
                HStack {
                    Text(title)
                        .font(NomadTypography.section)
                        .foregroundStyle(NomadColor.Text.primary)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NomadColor.Text.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(NomadSpacing.md)
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding(.horizontal, NomadSpacing.md)
                    .padding(.bottom, NomadSpacing.md)
            }
        }
        .nomadCardSurface(level: .level1, radius: NomadRadius.card)
    }

    private var ownerComments: some View {
        Text(property.ownerComments)
            .font(NomadTypography.body)
            .foregroundStyle(NomadColor.Text.primary)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noteSection: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.sm) {
            Text("Add note")
                .font(NomadTypography.section)
                .foregroundStyle(NomadColor.Text.primary)

            TextEditor(text: $noteText)
                .font(NomadTypography.body)
                .frame(minHeight: 120)
                .padding(NomadSpacing.sm)
                .background(NomadColor.Background.surface, in: .rect(cornerRadius: NomadRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: NomadRadius.card)
                        .stroke(NomadColor.Border.default, lineWidth: 1)
                }
                .onChange(of: noteText) { _, newValue in
                    appVM.propertyNotes[property.id] = newValue.isEmpty ? nil : newValue
                }
        }
    }

    private var propertyFeatures: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.xs) {
            let keys = Array(property.features.keys.sorted())

            ForEach(Array(keys.prefix(6)), id: \.self) { key in
                HStack {
                    Text(key)
                        .font(NomadTypography.body)
                        .foregroundStyle(NomadColor.Text.secondary)

                    Spacer(minLength: 0)

                    Text(property.features[key] ?? "")
                        .font(NomadTypography.bodyStrong)
                        .foregroundStyle(NomadColor.Text.primary)
                        .multilineTextAlignment(.trailing)
                }

                if key != keys.prefix(6).last {
                    Divider().overlay(NomadColor.Border.default)
                }
            }

            Button {
                showAllFeatures = true
            } label: {
                HStack(spacing: NomadSpacing.xxs) {
                    Text("See all property features")
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(NomadTypography.bodyStrong)
                .foregroundStyle(NomadColor.Accent.primary)
                .padding(.top, NomadSpacing.xs)
            }
            .buttonStyle(.plain)
        }
    }

    private var mortgageSection: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.sm) {
            Text("Mortgage Calculator")
                .font(NomadTypography.section)
                .foregroundStyle(NomadColor.Text.primary)

            VStack(spacing: NomadSpacing.md) {
                VStack(alignment: .leading, spacing: NomadSpacing.xs) {
                    HStack {
                        Text("Purchase Price")
                            .font(NomadTypography.body)
                            .foregroundStyle(NomadColor.Text.secondary)

                        Spacer(minLength: 0)

                        Text(Int(purchasePrice).formatted(.currency(code: "USD").precision(.fractionLength(0))))
                            .font(NomadTypography.bodyStrong)
                            .foregroundStyle(NomadColor.Text.primary)
                    }

                    Slider(value: $purchasePrice, in: 50_000...5_000_000, step: 5000)
                        .tint(NomadColor.Accent.primary)
                }

                VStack(alignment: .leading, spacing: NomadSpacing.xs) {
                    HStack {
                        Text("Down Payment")
                            .font(NomadTypography.body)
                            .foregroundStyle(NomadColor.Text.secondary)

                        Spacer(minLength: 0)

                        Text("\(Int(downPayment))%")
                            .font(NomadTypography.bodyStrong)
                            .foregroundStyle(NomadColor.Text.primary)
                    }

                    Slider(value: $downPayment, in: 5...50, step: 1)
                        .tint(NomadColor.Accent.primary)
                }

                HStack {
                    Text("Interest Rate")
                        .font(NomadTypography.body)
                        .foregroundStyle(NomadColor.Text.secondary)

                    Spacer(minLength: 0)

                    TextField("5.5", text: $interestRate)
                        .font(NomadTypography.bodyStrong)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 72)

                    Text("%")
                        .font(NomadTypography.body)
                        .foregroundStyle(NomadColor.Text.tertiary)
                }

                Divider().overlay(NomadColor.Border.default)

                HStack {
                    Text("Est. Monthly Payment")
                        .font(NomadTypography.bodyStrong)
                        .foregroundStyle(NomadColor.Text.primary)

                    Spacer(minLength: 0)

                    Text(monthlyPayment.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(NomadTypography.title2)
                        .foregroundStyle(NomadColor.Accent.primary)
                }
            }
            .padding(NomadSpacing.md)
            .nomadCardSurface(level: .level1, radius: NomadRadius.card)
        }
    }

    private var monthlyPayment: Double {
        let principal = purchasePrice * (1 - downPayment / 100)
        let rate = (Double(interestRate) ?? 5.5) / 100 / 12
        let payments: Double = 25 * 12

        guard rate > 0 else {
            return principal / payments
        }

        return principal * (rate * pow(1 + rate, payments)) / (pow(1 + rate, payments) - 1)
    }

    private var costsSection: some View {
        VStack(alignment: .leading, spacing: NomadSpacing.sm) {
            HStack {
                Text("Costs and expenses")
                    .font(NomadTypography.section)
                    .foregroundStyle(NomadColor.Text.primary)

                Spacer(minLength: 0)

                Picker("", selection: $showMonthlyCosts) {
                    Text("Monthly").tag(true)
                    Text("Yearly").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 190)
            }

            let multiplier = showMonthlyCosts ? 1 : 12
            let total = (property.monthlyTaxes + property.monthlyElectricity + property.monthlyCondoFees) * multiplier

            VStack(spacing: NomadSpacing.sm) {
                HStack {
                    Text("Total")
                        .font(NomadTypography.bodyStrong)
                        .foregroundStyle(NomadColor.Text.primary)

                    Spacer(minLength: 0)

                    Text(total.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                        .font(NomadTypography.title2)
                        .foregroundStyle(NomadColor.Accent.primary)
                }

                Divider().overlay(NomadColor.Border.default)

                CostRow(title: "Property taxes", amount: property.monthlyTaxes * multiplier)
                if property.monthlyElectricity > 0 {
                    CostRow(title: "Electricity", amount: property.monthlyElectricity * multiplier)
                }
                if property.monthlyCondoFees > 0 {
                    CostRow(title: "Condo fees", amount: property.monthlyCondoFees * multiplier)
                }
            }
            .padding(NomadSpacing.md)
            .nomadCardSurface(level: .level1, radius: NomadRadius.card)
        }
    }
}

struct DetailCard: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: NomadSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(NomadColor.Accent.primary)

            Text(value)
                .font(NomadTypography.title2)
                .foregroundStyle(NomadColor.Text.primary)

            Text(title)
                .font(NomadTypography.caption)
                .foregroundStyle(NomadColor.Text.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(NomadSpacing.md)
        .nomadCardSurface(level: .level1, radius: NomadRadius.card)
    }
}

struct CostRow: View {
    let title: String
    let amount: Int

    var body: some View {
        HStack {
            Text(title)
                .font(NomadTypography.body)
                .foregroundStyle(NomadColor.Text.secondary)

            Spacer(minLength: 0)

            Text(amount.formatted(.currency(code: "USD").precision(.fractionLength(0))))
                .font(NomadTypography.bodyStrong)
                .foregroundStyle(NomadColor.Text.primary)
        }
    }
}

struct ContactSellerSheet: View {
    let property: Property

    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var messages: [(String, Bool)] = []

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: NomadSpacing.sm) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                        HStack {
                            if message.1 {
                                Spacer(minLength: 60)
                            }

                            Text(message.0)
                                .font(NomadTypography.body)
                                .foregroundStyle(message.1 ? NomadColor.Background.surface : NomadColor.Text.primary)
                                .padding(.horizontal, NomadSpacing.md)
                                .padding(.vertical, NomadSpacing.sm)
                                .background(
                                    message.1 ? NomadColor.Accent.primary : NomadColor.Background.surfaceMuted,
                                    in: .rect(cornerRadius: NomadRadius.card)
                                )

                            if !message.1 {
                                Spacer(minLength: 60)
                            }
                        }
                    }
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.top, NomadSpacing.md)
                .padding(.bottom, NomadSpacing.md)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: NomadSpacing.sm) {
                    TextField("Type a message...", text: $messageText)
                        .font(NomadTypography.body)
                        .padding(.horizontal, NomadSpacing.md)
                        .frame(minHeight: 48)
                        .background(NomadColor.Background.surfaceMuted, in: .capsule)

                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(NomadColor.Background.surface)
                            .frame(width: 44, height: 44)
                            .background(
                                messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    ? NomadColor.Text.tertiary
                                    : NomadColor.Accent.primary,
                                in: .circle
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, NomadSpacing.pageHorizontal)
                .padding(.vertical, NomadSpacing.sm)
                .background(.ultraThinMaterial)
            }
            .nomadScreenBackground()
            .navigationTitle("Contact Seller")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NomadIconCircleButton(icon: "xmark") { dismiss() }
                        .accessibilityLabel("Close contact")
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append((text, true))
        messageText = ""

        Task {
            try? await Task.sleep(for: .seconds(1.0))
            messages.append(("Thank you for your interest in \(property.address)! I'll get back to you within 24 hours.", false))
        }
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
                            .font(NomadTypography.body)
                            .foregroundStyle(NomadColor.Text.secondary)

                        Spacer(minLength: 0)

                        Text(property.features[key] ?? "")
                            .font(NomadTypography.bodyStrong)
                            .foregroundStyle(NomadColor.Text.primary)
                    }
                }
            }
            .navigationTitle("All Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
