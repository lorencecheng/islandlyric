import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var manager: LyricManager
    @State private var showSettings = false

    var body: some View {
        ZStack {
            GlassBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Metrics.cardGap + 4) {
                    header
                    PlayerCard(
                        snapshot: manager.snapshot,
                        progress: manager.trackProgress,
                        isLive: manager.isActivityActive
                    )
                    lyricSection
                    controls
                    footnote
                }
                .padding(.horizontal, Metrics.pagePadding)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
        }
        .overlay(alignment: .top) { toast }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(manager)
        }
        .onTapGesture { manager.dismissToast() }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("ISLAND LYRIC")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(3)
                    .foregroundStyle(Palette.gold)
                Text("Apple Music 歌词 · 灵动岛 / 锁屏 / CarPlay")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
            }

            Spacer()

            HStack(spacing: 6) {
                StatusDot(active: manager.isActivityActive)
                Text(manager.isActivityActive ? "LIVE" : "IDLE")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(manager.isActivityActive ? Palette.goldBright : Palette.textTertiary)
            }
        }
        .padding(.horizontal, 4)
    }

    private var lyricSection: some View {
        VStack(spacing: 10) {
            SectionHeader(
                title: "LYRICS",
                detail: manager.track.map { "\($0.lines.count) 句 · \($0.source)" }
            )
            LyricPanel(
                track: manager.track,
                currentIndex: manager.currentIndex,
                status: manager.lyricsStatus
            )
        }
    }

    private var controls: some View {
        VStack(spacing: 12) {
            PillButton(
                title: manager.isActivityActive ? "停掉岛上歌词" : "开始岛上歌词",
                systemImage: manager.isActivityActive ? "stop.fill" : "bolt.fill",
                prominent: !manager.isActivityActive
            ) {
                manager.toggleActivity()
            }

            HStack(spacing: 12) {
                PillButton(title: "设置", systemImage: "slider.horizontal.3") {
                    showSettings = true
                }
                PillButton(title: "重新匹配", systemImage: "arrow.clockwise") {
                    Task { await manager.reloadLyrics() }
                }
            }
        }
    }

    private var footnote: some View {
        VStack(spacing: 4) {
            Text("歌词来源 LRCLIB（公开在线歌词库）")
            Text("后台靠静音音频保活，可能增加少量耗电")
        }
        .font(.system(size: 10, weight: .regular, design: .rounded))
        .foregroundStyle(Palette.textTertiary.opacity(0.8))
        .multilineTextAlignment(.center)
        .padding(.top, 6)
    }

    @ViewBuilder private var toast: some View {
        if let text = manager.toast {
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(.thinMaterial))
                .overlay(Capsule().strokeBorder(Palette.goldHairline, lineWidth: 0.8))
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LyricManager())
}
