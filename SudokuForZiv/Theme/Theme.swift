import SwiftUI

enum Theme {
    // Palette
    static let background   = Color(red: 1.00, green: 0.965, blue: 0.976)  // #FFF6F9
    static let surface      = Color.white
    static let primary      = Color(red: 1.00, green: 0.478, blue: 0.714)  // #FF7AB6
    static let primarySoft  = Color(red: 0.957, green: 0.651, blue: 0.753) // #F4A6C0
    static let ink          = Color(red: 0.227, green: 0.122, blue: 0.165) // #3A1F2A
    static let inkFaint     = Color(red: 0.227, green: 0.122, blue: 0.165).opacity(0.45)
    static let mistake      = Color(red: 0.886, green: 0.322, blue: 0.420) // #E2526B
    static let givenText    = Color(red: 0.227, green: 0.122, blue: 0.165)
    static let playerText   = Color(red: 1.00, green: 0.478, blue: 0.714)
    static let highlight    = Color(red: 1.00, green: 0.478, blue: 0.714).opacity(0.18)
    static let highlightWeak = Color(red: 1.00, green: 0.478, blue: 0.714).opacity(0.09)
    static let sameDigit    = Color(red: 1.00, green: 0.478, blue: 0.714).opacity(0.22)

    // Typography
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    // Spacing
    static let cornerRadius: CGFloat = 14
    static let boardCornerRadius: CGFloat = 12
    static let cellCorner: CGFloat = 3
}

private struct ThemedControlSurface<S: Shape>: ViewModifier {
    let shape: S
    let isActive: Bool
    let tint: Color?
    let fallbackFill: Color
    let shadowOpacity: Double

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            let glass = tint.map { Glass.regular.tint($0) }
                ?? (isActive ? Glass.regular.tint(Theme.primary.opacity(0.16)) : Glass.regular)
            content
                .glassEffect(glass.interactive(), in: shape)
        } else {
            content
                .background(isActive ? Theme.primary.opacity(0.12) : fallbackFill, in: shape)
                .shadow(color: Theme.ink.opacity(shadowOpacity), radius: 4, y: 1)
        }
    }
}

extension View {
    func themedControlSurface<S: Shape>(
        in shape: S,
        isActive: Bool = false,
        tint: Color? = nil,
        fallbackFill: Color = Theme.surface,
        shadowOpacity: Double = 0.06
    ) -> some View {
        modifier(
            ThemedControlSurface(
                shape: shape,
                isActive: isActive,
                tint: tint,
                fallbackFill: fallbackFill,
                shadowOpacity: shadowOpacity
            )
        )
    }
}
