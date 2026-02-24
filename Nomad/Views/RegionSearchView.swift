//
//  RegionSearchView.swift
//  Temporary
//
//  Created by Mikael on 24/2/26.
//


import SwiftUI

struct RegionSearchView: View {
    @Binding var selectedCities: Set<String>
    @Binding var searchText: String
    @Environment(\.dismiss) private var dismiss
    @State private var expandedRegions: Set<String> = []
    @State private var localSearch = ""

    private var filteredRegions: [Region] {
        if localSearch.isEmpty { return sampleRegions }
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
            }
            .background(NomadTheme.offWhite)
            .searchable(text: $localSearch, prompt: "Search by region, city, street...")
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        searchText = ""
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var selectedChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(selectedCities).sorted(), id: \.self) { city in
                    HStack(spacing: 4) {
                        Text(city)
                            .font(.caption.weight(.medium))
                        Button {
                            selectedCities.remove(city)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption2.weight(.bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(NomadTheme.darkGreen, in: .capsule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .contentMargins(.horizontal, 0)
        .background(Color(.secondarySystemGroupedBackground))
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
                        HStack {
                            Image(systemName: selectedCities.contains(city) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedCities.contains(city) ? NomadTheme.darkGreen : NomadTheme.lightGrey)
                            Text(city)
                                .foregroundStyle(NomadTheme.darkText)
                            Spacer()
                        }
                    }
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(NomadTheme.darkText)

                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(NomadTheme.darkGreen, in: .circle)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(NomadTheme.lightGrey)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
        }
    }
}
