import SwiftUI

/// 页面背景：炭黑渐变 + 两团极淡的光晕，给 Material 面板提供"可模糊的东西"
struct GlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.ink, Color(hex: 0x0E0F13), Palette.ink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Palette.gold.opacity(0.16))
                .frame(width: 420, height: 420)
                .blur(radius: 140)
                .offset(x: -120, y: -220)

            Circle()
                .fill(Color(hex: 0x2A3B55).opacity(0.35))
                .frame(width: 520, height: 520)
                .blur(radius: 160)
                .offset(x: 160, y: 260)
        }
        .ignoresSafeArea()
    }
}
