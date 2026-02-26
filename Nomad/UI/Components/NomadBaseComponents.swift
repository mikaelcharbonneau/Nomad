import SwiftUI

struct NomadSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: NomadSpacing.sm) {
            VStack(alignment: .leading, spacing: NomadSpacing.xs) {
                Text(title)
                    .font(NomadTypography.section)
                    .foregroundStyle(NomadColor.Text.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(NomadTypography.caption)
                        .foregroundStyle(NomadColor.Text.secondary)
                }
            }

            Spacer(minLength: NomadSpacing.md)
            trailing
        }
    }
}

struct NomadSearchField: View {
    let placeholder: String
    var icon: String = "magnifyingglass"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: NomadSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(NomadColor.Text.tertiary)

                Text(placeholder)
                    .font(NomadTypography.body)
                    .foregroundStyle(NomadColor.Text.tertiary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, NomadSpacing.md)
            .frame(height: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .nomadCardSurface(level: .level1, radius: NomadRadius.pill)
    }
}

struct NomadChip: View {
    let text: String
    let isSelected: Bool
    var isCompact = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(isCompact ? NomadTypography.meta : NomadTypography.caption)
                .foregroundStyle(isSelected ? NomadColor.Background.surface : NomadColor.Text.primary)
                .lineLimit(1)
                .padding(.horizontal, isCompact ? NomadSpacing.sm : NomadSpacing.md)
                .padding(.vertical, isCompact ? NomadSpacing.xs : NomadSpacing.sm)
                .frame(minHeight: 36)
                .background(isSelected ? NomadColor.Accent.primary : NomadColor.Background.surface, in: .capsule)
                .overlay {
                    Capsule()
                        .stroke(isSelected ? .clear : NomadColor.Border.default, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct NomadPrimaryCTA: View {
    enum StyleKind {
        case accent
        case neutral
    }

    let title: String
    let icon: String?
    var style: StyleKind = .accent
    var action: () -> Void

    private var background: Color {
        switch style {
        case .accent: return NomadColor.Accent.primary
        case .neutral: return NomadColor.Text.primary
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: NomadSpacing.xs) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .lineLimit(1)
            }
            .font(NomadTypography.bodyStrong)
            .foregroundStyle(NomadColor.Background.surface)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
            .padding(.horizontal, NomadSpacing.md)
            .background(background, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
    }
}

struct NomadIconCircleButton: View {
    enum Emphasis {
        case neutral
        case accent
        case overlay
    }

    let icon: String
    var emphasis: Emphasis = .neutral
    var isFilled: Bool = true
    var size: CGFloat = 44
    var action: () -> Void

    private var backgroundColor: Color {
        switch emphasis {
        case .neutral:
            return NomadColor.Background.surface
        case .accent:
            return NomadColor.Accent.primary
        case .overlay:
            return .black.opacity(0.28)
        }
    }

    private var foregroundColor: Color {
        switch emphasis {
        case .neutral:
            return NomadColor.Text.primary
        case .accent:
            return NomadColor.Background.surface
        case .overlay:
            return NomadColor.Background.surface
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: max(size, 44), height: max(size, 44))
                .background(backgroundColor, in: .circle)
                .overlay {
                    if !isFilled {
                        Circle().stroke(NomadColor.Border.default, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Base Components") {
    VStack(alignment: .leading, spacing: NomadSpacing.lg) {
        NomadSectionHeader(title: "Featured", subtitle: "Calm and trustworthy")

        NomadSearchField(placeholder: "Search by region, city, street...") {}

        HStack {
            NomadChip(text: "Condo", isSelected: true) {}
            NomadChip(text: "House", isSelected: false) {}
        }

        HStack {
            NomadIconCircleButton(icon: "slider.horizontal.3") {}
            NomadIconCircleButton(icon: "plus", emphasis: .accent) {}
        }

        NomadPrimaryCTA(title: "View map", icon: "map.fill") {}
    }
    .padding(NomadSpacing.pageHorizontal)
    .nomadScreenBackground()
}

#Preview("Base Components AX4") {
    VStack(alignment: .leading, spacing: NomadSpacing.lg) {
        NomadSearchField(placeholder: "Search by region, city, street...") {}
        NomadPrimaryCTA(title: "Contact Seller", icon: "message.fill") {}
    }
    .padding(NomadSpacing.pageHorizontal)
    .nomadScreenBackground()
    .environment(\.dynamicTypeSize, .accessibility4)
}
