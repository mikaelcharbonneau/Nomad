import SwiftUI

struct RegionSearchView: View {
    @Binding var selectedCities: Set<String>
    @Binding var searchText: String

    @Environment(\.dismiss) private var dismiss

    @State private var expandedRegions: Set<String> = []
    @State private var localSearch = ""

    private var filteredRegions: [Region] {
        if localSearch.isEmpty {
            return sampleRegions
        }

        return sampleRegions.filter { region in
            region.name.localizedCaseInsensitiveContains(localSearch) ||
            region.cities.contains { $0.localizedCaseInsensitiveContains(localSearch) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !selectedCities.isEmpty {
                    selectedChips
                }

                List {
                    ForEach(filteredRegions) { region in
                        regionRow(region)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .nomadScreenBackground()
            .searchable(text: $localSearch, prompt: "Search by region, city, street...")
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        searchText = ""
                        dismiss()
                    }
                    .font(NomadTypography.bodyStrong)
                }
            }
        }
    }

    private var selectedChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: NomadSpacing.xs) {
                ForEach(Array(selectedCities).sorted(), id: \.self) { city in
                    HStack(spacing: NomadSpacing.xxs) {
                        Text(city)
                            .font(NomadTypography.caption)

                        Button {
                            selectedCities.remove(city)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 20, height: 20)
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundStyle(NomadColor.Background.surface)
                    .padding(.horizontal, NomadSpacing.sm)
                    .padding(.vertical, NomadSpacing.xs)
                    .background(NomadColor.Accent.primary, in: .capsule)
                }
            }
            .padding(.horizontal, NomadSpacing.pageHorizontal)
            .padding(.vertical, NomadSpacing.sm)
        }
        .contentMargins(.horizontal, 0)
        .background(NomadColor.Background.surfaceMuted)
    }

    private func regionRow(_ region: Region) -> some View {
        let isExpanded = expandedRegions.contains(region.id)
        let selectedCount = region.cities.filter { selectedCities.contains($0) }.count

        return Section {
            if isExpanded {
                ForEach(region.cities, id: \.self) { city in
                    Button {
                        if selectedCities.contains(city) {
                            selectedCities.remove(city)
                        } else {
                            selectedCities.insert(city)
                        }
                    } label: {
                        HStack(spacing: NomadSpacing.xs) {
                            Image(systemName: selectedCities.contains(city) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedCities.contains(city) ? NomadColor.Accent.primary : NomadColor.Text.tertiary)

                            Text(city)
                                .font(NomadTypography.body)
                                .foregroundStyle(NomadColor.Text.primary)

                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Button {
                withAnimation(.snappy) {
                    if isExpanded {
                        expandedRegions.remove(region.id)
                    } else {
                        expandedRegions.insert(region.id)
                    }
                }
            } label: {
                HStack {
                    Text(region.name)
                        .font(NomadTypography.bodyStrong)
                        .foregroundStyle(NomadColor.Text.primary)

                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(NomadTypography.meta)
                            .foregroundStyle(NomadColor.Background.surface)
                            .frame(width: 22, height: 22)
                            .background(NomadColor.Accent.primary, in: .circle)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(NomadColor.Text.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            .textCase(nil)
        }
    }
}
