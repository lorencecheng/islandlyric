import SwiftUI

/// 一块 Material 面板：底层模糊 + 压暗 + 高光 + 发丝描边 + 阴影
struct MaterialSurface<Content: View>: View {
    var level: SurfaceLevel = .medium
    var tint: Color = .clear
    var goldEdge: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background {
                ZStack {
                    Rectangle().fill(level.material)
                    Rectangle().fill(Palette.ink.opacity(level.dimming))
                    if tint != .clear {
                        Rectangle().fill(tint)
                    }
                    // 顶部高光：模拟玻璃受光
                    LinearGradient(
                        colors: [Color.white.opacity(0.14), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: level.cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: level.cornerRadius, style: .continuous)
                    .strokeBorder(goldEdge ? Palette.goldHairline : Palette.hairline,
                                  lineWidth: Metrics.hairline)
            }
            .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 14)
    }
}
