import SwiftUI

enum NomadColor {
    enum Background {
        static let canvas = Color(hex: 0xF4F5F3)
        static let surface = Color(hex: 0xFFFFFF)
        static let surfaceMuted = Color(hex: 0xEEF1EE)
    }

    enum Text {
        static let primary = Color(hex: 0x171A19)
        static let secondary = Color(hex: 0x6E7471)
        static let tertiary = Color(hex: 0x8A918D)
    }

    enum Accent {
        static let primary = Color(hex: 0x000000)
        static let soft = Color(hex: 0xECEDEC)
    }

    enum Border {
        static let `default` = Color(hex: 0xD9DFDB)
    }

    enum State {
        static let destructive = Color(hex: 0xD64545)
    }
}

enum NomadSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40

    static let pageHorizontal: CGFloat = lg
    static let sectionVertical: CGFloat = xl
    static let cardPadding: CGFloat = md
}

enum NomadRadius {
    static let control: CGFloat = 12
    static let card: CGFloat = 16
    static let hero: CGFloat = 24
    static let pill: CGFloat = 999
}

enum NomadElevation {
    case level1
    case level2
    case level3

    var blur: CGFloat {
        switch self {
        case .level1: return 8
        case .level2: return 16
        case .level3: return 24
        }
    }

    var y: CGFloat {
        switch self {
        case .level1: return 2
        case .level2: return 6
        case .level3: return 10
        }
    }

    var alpha: Double {
        switch self {
        case .level1: return 0.06
        case .level2: return 0.08
        case .level3: return 0.10
        }
    }
}

enum NomadTypography {
    static let display = Font.system(size: 40, weight: .semibold, design: .default)
    static let title1 = Font.system(size: 32, weight: .bold, design: .default)
    static let title2 = Font.system(size: 24, weight: .semibold, design: .default)
    static let section = Font.system(size: 20, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let bodyStrong = Font.system(size: 17, weight: .semibold, design: .default)
    static let caption = Font.system(size: 13, weight: .regular, design: .default)
    static let meta = Font.system(size: 12, weight: .medium, design: .default)
}

private struct NomadCardSurfaceModifier: ViewModifier {
    let level: NomadElevation
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(NomadColor.Background.surface, in: .rect(cornerRadius: radius))
            .shadow(color: .black.opacity(level.alpha), radius: level.blur, y: level.y)
    }
}

private struct NomadScreenBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(NomadColor.Background.canvas.ignoresSafeArea())
    }
}

extension View {
    func nomadScreenBackground() -> some View {
        modifier(NomadScreenBackgroundModifier())
    }

    func nomadCardSurface(level: NomadElevation = .level1, radius: CGFloat = NomadRadius.card) -> some View {
        modifier(NomadCardSurfaceModifier(level: level, radius: radius))
    }

    func nomadSectionPadding() -> some View {
        padding(.horizontal, NomadSpacing.pageHorizontal)
            .padding(.vertical, NomadSpacing.sectionVertical)
    }

    func nomadHairlineDivider() -> some View {
        overlay(alignment: .bottom) {
            Rectangle()
                .fill(NomadColor.Border.default)
                .frame(height: 1 / UIScreen.main.scale)
        }
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

// Backwards compatibility for non-migrated screens.
enum NomadTheme {
    static let offWhite = NomadColor.Background.canvas
    static let darkText = NomadColor.Text.primary
    static let lightGrey = NomadColor.Text.tertiary
    static let darkGreen = NomadColor.Accent.primary
    static let lightGreen = NomadColor.Accent.soft
    static let pillRadius: CGFloat = NomadRadius.hero
    static let cardShadow: CGFloat = NomadElevation.level2.blur

    static var greeting: String {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch weekday {
        case 1: return "Happy Sunday!"
        case 7: return "Good weekend!"
        case 6: return "Happy Friday!"
        default:
            let hour = Calendar.current.component(.hour, from: Date())
            if hour < 12 { return "Good morning!" }
            else if hour < 17 { return "Good afternoon!" }
            else { return "Good evening!" }
        }
    }
}

struct PillButtonStyle: ButtonStyle {
    let filled: Bool
    let color: Color

    init(filled: Bool = true, color: Color = NomadColor.Accent.primary) {
        self.filled = filled
        self.color = color
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NomadTypography.bodyStrong)
            .padding(.horizontal, NomadSpacing.xl)
            .padding(.vertical, NomadSpacing.sm)
            .background(filled ? color : .clear, in: .capsule)
            .foregroundStyle(filled ? NomadColor.Background.surface : color)
            .overlay {
                Capsule()
                    .stroke(color, lineWidth: filled ? 0 : 1.5)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.2), value: configuration.isPressed)
            .contentShape(.capsule)
    }
}
