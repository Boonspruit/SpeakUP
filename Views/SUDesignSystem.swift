import SwiftUI

// MARK: - Color Palette

enum SUColor {
    // Brand
    static let brand       = Color(red: 0.13, green: 0.46, blue: 0.96)    // Vibrant blue
    static let brandDark   = Color(red: 0.08, green: 0.33, blue: 0.78)
    static let brandLight  = Color(red: 0.87, green: 0.93, blue: 1.0)

    // Accent (warm amber/orange)
    static let accent      = Color(red: 1.0, green: 0.62, blue: 0.04)     // Amber CTA
    static let accentLight = Color(red: 1.0, green: 0.88, blue: 0.60)

    // Success / streak
    static let success     = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let successDark = Color(red: 0.12, green: 0.62, blue: 0.25)

    // Streak gradient
    static let streakStart = Color(red: 1.0, green: 0.72, blue: 0.10)     // Yellow
    static let streakEnd   = Color(red: 1.0, green: 0.42, blue: 0.10)     // Orange-red

    // Surfaces
    static let background  = Color(red: 0.97, green: 0.97, blue: 0.98)    // Off-white
    static let surface     = Color.white
    static let surfaceAlt  = Color(red: 0.95, green: 0.96, blue: 0.97)

    // Text
    static let ink         = Color(red: 0.12, green: 0.13, blue: 0.18)
    static let inkSecondary = Color(red: 0.45, green: 0.47, blue: 0.54)
    static let inkMuted    = Color(red: 0.68, green: 0.70, blue: 0.75)

    // Danger
    static let danger      = Color(red: 0.94, green: 0.22, blue: 0.22)

    // Theater
    static let seatRed     = Color(red: 0.90, green: 0.18, blue: 0.15)
    static let paperWhite  = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let paperLine   = Color(red: 0.84, green: 0.88, blue: 0.94)

    // Tab bar
    static let tabInactive = Color(red: 0.72, green: 0.74, blue: 0.78)
}

// MARK: - Typography

enum SUFont {
    static func heroTitle()   -> Font { .system(size: 32, weight: .bold, design: .rounded) }
    static func pageTitle()   -> Font { .system(size: 26, weight: .bold, design: .rounded) }
    static func sectionTitle() -> Font { .system(size: 20, weight: .bold, design: .rounded) }
    static func cardTitle()   -> Font { .system(size: 17, weight: .semibold, design: .rounded) }
    static func body()        -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func bodyBold()    -> Font { .system(size: 16, weight: .semibold, design: .rounded) }
    static func caption()     -> Font { .system(size: 13, weight: .medium, design: .rounded) }
    static func captionBold() -> Font { .system(size: 13, weight: .bold, design: .rounded) }
    static func button()      -> Font { .system(size: 17, weight: .bold, design: .rounded) }
    static func bigNumber()   -> Font { .system(size: 44, weight: .heavy, design: .rounded) }
    static func teleprompter() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
}

// MARK: - Spacing (4pt grid)

enum SUSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 16
    static let xl:  CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// MARK: - Corner Radius

enum SURounding {
    static let sm:   CGFloat = 10
    static let md:   CGFloat = 14
    static let card: CGFloat = 20
    static let lg:   CGFloat = 24
    static let pill: CGFloat = 999
}

// MARK: - Shadows

enum SUShadow {
    static func card() -> some View {
        Color.black.opacity(0.06)
    }

    static let cardRadius: CGFloat = 16
    static let cardY: CGFloat = 6
    static let subtleRadius: CGFloat = 8
    static let subtleY: CGFloat = 3
}

// MARK: - Animations

enum SUAnimation {
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let smooth = Animation.easeInOut(duration: 0.25)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let gentle = Animation.easeOut(duration: 0.35)
}

// MARK: - View Modifiers

struct SUCardModifier: ViewModifier {
    var padding: CGFloat = SUSpacing.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(SUColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: SURounding.card, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: SUShadow.cardRadius, y: SUShadow.cardY)
    }
}

struct SUPrimaryButtonStyle: ButtonStyle {
    var color: Color = SUColor.brand

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SUFont.button())
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: SURounding.md, style: .continuous))
            .shadow(color: color.opacity(0.3), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(SUAnimation.snappy, value: configuration.isPressed)
    }
}

struct SUSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SUFont.button())
            .foregroundStyle(SUColor.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(SUColor.brandLight)
            .clipShape(RoundedRectangle(cornerRadius: SURounding.md, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(SUAnimation.snappy, value: configuration.isPressed)
    }
}

struct SUGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SUFont.bodyBold())
            .foregroundStyle(SUColor.brand)
            .padding(.vertical, 12)
            .padding(.horizontal, SUSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: SURounding.sm, style: .continuous)
                    .stroke(SUColor.brand.opacity(0.3), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(SUAnimation.snappy, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func suCard(padding: CGFloat = SUSpacing.lg) -> some View {
        modifier(SUCardModifier(padding: padding))
    }
}

// MARK: - Practice Mode Colors

extension PracticeMode {
    var color: Color {
        switch self {
        case .presentation: return Color(red: 0.13, green: 0.46, blue: 0.96)
        case .speech:       return Color(red: 0.56, green: 0.27, blue: 0.87)
        case .salesPitch:   return Color(red: 1.0, green: 0.42, blue: 0.10)
        case .interview:    return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .elevatorPitch: return Color(red: 0.94, green: 0.22, blue: 0.60)
        }
    }
}

extension FocusTrack {
    var color: Color {
        switch self {
        case .work: return Color(red: 0.13, green: 0.46, blue: 0.96)
        case .interviews: return Color(red: 0.22, green: 0.74, blue: 0.38)
        case .social: return Color(red: 1.0, green: 0.62, blue: 0.04)
        case .school: return Color(red: 0.52, green: 0.43, blue: 0.94)
        case .storytelling: return Color(red: 0.94, green: 0.22, blue: 0.60)
        }
    }
}
