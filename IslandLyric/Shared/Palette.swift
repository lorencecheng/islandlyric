import SwiftUI

/// 全局配色。炭黑底 + 金色强调，Material 体系里用色相区分层级
enum Palette {

    static let ink = Color(hex: 0x08080A)
    static let inkSoft = Color(hex: 0x121216)
    static let gold = Color(hex: 0xC9A961)
    static let goldBright = Color(hex: 0xE3C888)

    static let textPrimary = Color.white.opacity(0.92)
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.34)

    static let hairline = Color.white.opacity(0.10)
    static let goldHairline = Color(hex: 0xC9A961).opacity(0.28)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
