import SwiftUI

struct PropertyCardView: View {
    let property: Property
    let isSaved: Bool
    let onToggleSave: () -> Void

    var body: some View {
        NomadPropertyCard(property: property, variant: .full, isSaved: isSaved, onToggleSave: onToggleSave)
    }
}

struct MiniPropertyCard: View {
    let property: Property

    var body: some View {
        NomadPropertyCard(property: property, variant: .mini)
            .frame(width: 180)
    }
}
