import SwiftUI

/// Material 体系的四级表面 —— 对应 SwiftUI 的 .ultraThinMaterial / .thin / .regular / .thick
enum SurfaceLevel: Int, CaseIterable {
    case ultraThin = 0   // 最轻，浮在最上层的浮层
    case thin = 1
    case regular = 2
    case thick = 3       // 最重，页面底板

    // 语义别名（frosted / light / medium / deep）
    static let frosted = SurfaceLevel.ultraThin
    static let light = SurfaceLevel.thin
    static let medium = SurfaceLevel.regular
    static let deep = SurfaceLevel.thick

    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        }
    }

    /// 炭黑压暗强度：层级越深，压得越暗，保证文字可读
    var dimming: Double {
        switch self {
        case .ultraThin: return 0.18
        case .thin: return 0.30
        case .regular: return 0.52
        case .thick: return 0.80
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .ultraThin: return 22
        case .thin: return 26
        case .regular: return 30
        case .thick: return 34
        }
    }
}

enum Metrics {
    static let pagePadding: CGFloat = 20
    static let cardGap: CGFloat = 14
    static let hairline: CGFloat = 0.8
}
