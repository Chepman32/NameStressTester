import SwiftUI
import UIKit

enum Brand {
    static let primary = Color(hex: "#1B1F3B", dark: "#E8ECF4")
    static let accent = Color(hex: "#FF5733", dark: "#FF6F4E")
    static let pass = Color(hex: "#2ECC71", dark: "#3DDB85")
    static let fail = Color(hex: "#E74C3C", dark: "#FF6B6B")
    static let warn = Color(hex: "#F39C12", dark: "#FFB347")
    static let surface = Color(hex: "#F7F8FC", dark: "#12152B")
    static let card = Color(hex: "#FFFFFF", dark: "#1C2041")
    static let cardAlt = Color(hex: "#F0F2FA", dark: "#232850")
    static let textPrimary = Color(hex: "#1B1F3B", dark: "#E8ECF4")
    static let textSecondary = Color(hex: "#6B7394", dark: "#8B92B3")
    static let textTertiary = Color(hex: "#A0A7C4", dark: "#4E5573")
    static let divider = Color(hex: "#E2E5F0", dark: "#2A2F54")
    static let shimmerStart = Color(hex: "#D4D8E8", dark: "#2A2F54")
    static let shimmerEnd = Color(hex: "#F7F8FC", dark: "#1C2041")

    static let rhyme = Color(hex: "#9B59B6")
    static let initials = Color(hex: "#3498DB")
    static let pronunciation = Color(hex: "#E67E22")
    static let email = Color(hex: "#1ABC9C")
    static let nameTag = Color(hex: "#E74C3C")
    static let namesake = Color(hex: "#8E7CC3")
    static let monogram = Color(hex: "#2C3E50", dark: "#BFC5DC")

    static func color(for verdict: TestVerdict) -> Color {
        switch verdict {
        case .pass: pass
        case .warn: warn
        case .fail: fail
        }
    }

    static func color(for testType: TestType) -> Color {
        switch testType {
        case .rhyme: rhyme
        case .initials: initials
        case .pronunciation: pronunciation
        case .email: email
        case .nameTag: nameTag
        case .namesake: namesake
        case .monogram: monogram
        }
    }
}

enum NamifySpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

enum NamifyRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 14
    static let large: CGFloat = 22
    static let pill: CGFloat = 999
}

enum NamifyShadow {
    static let card = ShadowSpec(color: Color.black.opacity(0.08), radius: 12, y: 2)
    static let floating = ShadowSpec(color: Color.black.opacity(0.16), radius: 24, y: 10)
    static let modal = ShadowSpec(color: Color.black.opacity(0.22), radius: 40, y: 18)
    static let glow = ShadowSpec(color: Brand.accent.opacity(0.30), radius: 18, y: 0)
}

struct ShadowSpec {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

enum NamifyMotion {
    static let snappy = Animation.spring(response: 0.35, dampingFraction: 0.72)
    static let smooth = Animation.spring(response: 0.50, dampingFraction: 0.82)
    static let bouncy = Animation.spring(response: 0.60, dampingFraction: 0.65)
    static let gentle = Animation.spring(response: 0.80, dampingFraction: 0.88)
    static let micro = Animation.easeOut(duration: 0.15)
}

enum NamifyTypography {
    static func hero() -> Font { custom(size: 42, weight: .black, relativeTo: .largeTitle) }
    static func title() -> Font { custom(size: 34, weight: .bold, relativeTo: .title) }
    static func subtitle() -> Font { custom(size: 24, weight: .semibold, relativeTo: .title3) }
    static func bodyLarge() -> Font { custom(size: 18, weight: .regular, relativeTo: .body) }
    static func bodyMedium() -> Font { custom(size: 16, weight: .regular, relativeTo: .body) }
    static func bodySmall() -> Font { custom(size: 14, weight: .regular, relativeTo: .footnote) }
    static func badge() -> Font { custom(size: 13, weight: .bold, relativeTo: .caption) }
    static func button() -> Font { custom(size: 17, weight: .semibold, relativeTo: .headline) }
    static func mono() -> Font { .system(.footnote, design: .monospaced).weight(.medium) }

    private static func custom(size: CGFloat, weight: Font.Weight, relativeTo: Font.TextStyle) -> Font {
        if UIFont(name: "Manrope", size: size) != nil {
            return .custom("Manrope", size: size, relativeTo: relativeTo).weight(weight)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }
}

enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

extension View {
    func namifyCardShadow(_ spec: ShadowSpec = NamifyShadow.card) -> some View {
        shadow(color: spec.color, radius: spec.radius, x: 0, y: spec.y)
    }
}

extension Color {
    init(hex: String, dark: String? = nil) {
        if let dark {
            self = Color(
                uiColor: UIColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? UIColor(hex: dark)
                        : UIColor(hex: hex)
                }
            )
        } else {
            self = Color(uiColor: UIColor(hex: hex))
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let sanitized = hex.replacingOccurrences(of: "#", with: "")
        let scanner = Scanner(string: sanitized)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        let red = CGFloat((value & 0xFF0000) >> 16) / 255
        let green = CGFloat((value & 0x00FF00) >> 8) / 255
        let blue = CGFloat(value & 0x0000FF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
