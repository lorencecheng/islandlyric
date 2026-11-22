import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var manager: LyricManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage(SettingsKey.autoStart) private var autoStart = true
    @AppStorage(SettingsKey.keepAlive) private var keepAlive = true

    @State private var cacheCleared = false

    var body: some View {
        NavigationStack {
            ZStack {
                GlassBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        behaviorCard
                        sourceCard
                        aboutCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.gold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var behaviorCard: some View {
        MaterialSurface(level: .regular) {
            VStack(spacing: 0) {
                toggleRow(
                    title: "播放时自动上岛",
                    detail: "检测到正在播放且歌词就绪后，2 秒内自动开启实时活动",
                    isOn: $autoStart
                )

                Divider().overlay(Palette.hairline).padding(.horizontal, 16)

                toggleRow(
                    title: "静音音频保活",
                    detail: "用一段无声音频维持后台运行，锁屏时歌词才会继续跳动",
                    isOn: $keepAlive
                )
                .onChange(of: keepAlive) { _, _ in
                    manager.applyKeepAliveSetting()
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var sourceCard: some View {
        MaterialSurface(level: .regular) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("歌词来源")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    SourceBadge(text: "LRCLIB")
                }

                Text("LRCLIB 是公开在线歌词库，无需账号与 API Key，按歌名 / 歌手 / 时长三级匹配逐句时间轴。")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    LyricsService.clearCache()
                    cacheCleared = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: cacheCleared ? "checkmark.circle.fill" : "trash")
                        Text(cacheCleared ? "缓存已清除" : "清除歌词缓存")
                    }
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.goldBright)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Palette.gold.opacity(0.12)))
                    .overlay(Capsule().strokeBorder(Palette.goldHairline, lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }

    private var aboutCard: some View {
        MaterialSurface(level: .regular) {
            VStack(alignment: .leading, spacing: 10) {
                row(title: "版本", value: "1.0")
                row(title: "Bundle ID", value: "com.lorence.islandlyric")
                row(title: "灵动岛 / 锁屏", value: "medium 家族")
                row(title: "CarPlay / 手表", value: "small 家族")

                Text("CarPlay 是否显示实时活动由系统与车机决定，应用只能声明支持；手表需要 iPhone 配对并在智能叠放里查看。")
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(16)
        }
    }

    private func toggleRow(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.textPrimary)
                Text(detail)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Palette.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func row(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(Palette.textTertiary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.textSecondary)
        }
    }
}
