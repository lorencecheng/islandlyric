import SwiftUI

/// Material 体系的四级表面 —— 对应 SwiftUI 的 .ultraThinMaterial / .thin / .regular / .thick
enum SurfaceLevel: Int, CaseIterable {
    case frosted = 0     // 最轻，浮在最上层的浮层
    case light = 1
    case medium = 2
    case deep = 3        // 最重，页面底板

    var material: Material {
        switch self {
        case .frosted: return .ultraThinMaterial
        case .light: return .thinMaterial
        case .medium: return .regularMaterial
        case .deep: return .thickMaterial
        }
    }

    /// 炭黑压暗强度：层级越深，压得越暗，保证文字可读
    var dimming: Double {
        switch self {
        case .frosted: return 0.18
        case .light: return 0.30
        case .medium: return 0.52
        case .deep: return 0.80
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .frosted: return 22
        case .light: return 26
        case .medium: return 30
        case .deep: return 34
        }
    }
}

enum Metrics {
    static let pagePadding: CGFloat = 20
    static let cardGap: CGFloat = 14
    static let hairline: CGFloat = 0.8
}
