import SwiftUI

struct SectionHeader: View {
    var title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(Palette.textSecondary)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .padding(.horizontal, 4)
    }
}

struct StatusDot: View {
    var active: Bool
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(active ? Palette.gold : Palette.textTertiary)
            .frame(width: 7, height: 7)
            .scaleEffect(active && pulse ? 1.3 : 1.0)
            .shadow(color: active ? Palette.gold.opacity(0.7) : .clear, radius: 6)
            .animation(active ? .easeInOut(duration: 1.3).repeatForever(autoreverses: true) : .default, value: pulse)
            .onAppear { pulse = true }
    }
}

struct ArtworkTile: View {
    var size: CGFloat = 62

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Palette.gold.opacity(0.55), Color(hex: 0x2A3B55).opacity(0.72)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "music.note")
                .font(.system(size: size * 0.33, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
        )
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }
}

struct WaveformBars: View {
    var active: Bool
    var height: CGFloat = 18

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.22, paused: !active)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<5, id: \.self) { i in
                    let level = active
                        ? 0.32 + 0.62 * abs(sin(t * 1.7 + Double(i) * 0.85))
                        : 0.22
                    Capsule()
                        .fill(Palette.gold.opacity(active ? 0.88 : 0.30))
                        .frame(width: 2.5, height: height * level)
                }
            }
            .frame(height: height)
        }
    }
}

struct ProgressBar: View {
    var value: Double
    var height: CGFloat = 3

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Palette.gold.opacity(0.92), Palette.goldBright],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(min(max(value, 0), 1)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct SourceBadge: View {
    var text: String
    var isGold: Bool = true

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .tracking(0.6)
            .foregroundStyle(isGold ? Palette.goldBright : Palette.textSecondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill((isGold ? Palette.gold : Color.white).opacity(0.12)))
            .overlay(Capsule().strokeBorder((isGold ? Palette.gold : Color.white).opacity(0.25), lineWidth: 0.8))
    }
}

struct PlayerCard: View {
    var snapshot: NowPlayingSnapshot
    var progress: Double
    var isLive: Bool

    var body: some View {
        MaterialSurface(level: .medium, goldEdge: isLive) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 14) {
                    ArtworkTile()

                    VStack(alignment: .leading, spacing: 6) {
                        Text(snapshot.title.isEmpty ? "等待播放" : snapshot.title)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.textPrimary)
                            .lineLimit(1)

                        Text(subtitle)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            SourceBadge(text: snapshot.isPlaying ? "PLAYING" : "PAUSED", isGold: snapshot.isPlaying)
                            if isLive { SourceBadge(text: "LIVE ACTIVITY", isGold: true) }
                        }
                    }

                    Spacer(minLength: 4)
                    WaveformBars(active: snapshot.isPlaying)
                }

                VStack(spacing: 8) {
                    ProgressBar(value: progress)
                    HStack {
                        Text(TimeFormat.stamp(snapshot.elapsed))
                        Spacer()
                        Text(snapshot.duration > 0 ? TimeFormat.stamp(snapshot.duration) : "--:--")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                }
            }
            .padding(18)
        }
    }

    private var subtitle: String {
        if snapshot.isEmpty { return "打开 Apple Music 播放一首歌" }
        if snapshot.artist.isEmpty { return snapshot.album }
        if snapshot.album.isEmpty { return snapshot.artist }
        return "\(snapshot.artist) · \(snapshot.album)"
    }
}

struct LyricPanel: View {
    var track: LyricTrack?
    var currentIndex: Int?
    var status: LyricsStatus

    var body: some View {
        MaterialSurface(level: .light) {
            VStack(alignment: .leading, spacing: 0) {
                header
                Divider().overlay(Palette.hairline)
                content
            }
            .padding(.vertical, 14)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("逐句歌词")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(Palette.textSecondary)

            if let track, !track.isEmpty {
                SourceBadge(text: track.source.uppercased())
            }

            Spacer()

            if let track, let currentIndex, !track.isEmpty {
                Text("\(currentIndex + 1) / \(track.lines.count)")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    @ViewBuilder private var content: some View {
        switch status {
        case .loading:
            placeholder("正在匹配在线歌词…", icon: "waveform")
        case .failed(let message):
            placeholder(message, icon: "exclamationmark.triangle")
        case .ready:
            if let track, let currentIndex, !track.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(visibleLines(track: track, currentIndex: currentIndex)) { line in
                        LyricRow(
                            text: line.text,
                            isCurrent: line.id == currentIndex,
                            opacity: opacity(for: abs(line.id - currentIndex))
                        )
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.easeInOut(duration: 0.28), value: currentIndex)
            }
        default:
            placeholder("播放歌曲后自动匹配歌词", icon: "text.quote")
        }
    }

    private func visibleLines(track: LyricTrack, currentIndex: Int) -> [LyricLine] {
        let lower = max(0, currentIndex - 2)
        let upper = min(track.lines.count - 1, currentIndex + 4)
        guard lower <= upper else { return [] }
        return Array(track.lines[lower...upper])
    }

    private func opacity(for distance: Int) -> Double {
        switch distance {
        case 0: return 1.0
        case 1: return 0.52
        case 2: return 0.28
        case 3: return 0.14
        case 4: return 0.08
        default: return 0.05
        }
    }

    private func placeholder(_ text: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Palette.gold.opacity(0.8))
            Text(text)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)
    }
}

struct LyricRow: View {
    var text: String
    var isCurrent: Bool
    var opacity: Double

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Capsule()
                .fill(Palette.gold)
                .frame(width: isCurrent ? 3 : 0, height: 14)
                .opacity(isCurrent ? 0.9 : 0)

            Text(text)
                .font(.system(size: isCurrent ? 19 : 14, weight: isCurrent ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isCurrent ? Palette.goldBright : Palette.textPrimary)
                .opacity(opacity)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

struct PillButton: View {
    var title: String
    var systemImage: String
    var prominent: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
            }
            .foregroundStyle(prominent ? Palette.ink : Palette.textPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    if prominent {
                        Capsule().fill(
                            LinearGradient(
                                colors: [Palette.gold, Palette.goldBright],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    } else {
                        Capsule().fill(.ultraThinMaterial)
                        Capsule().fill(Palette.ink.opacity(0.35))
                    }
                }
            }
            .overlay(Capsule().strokeBorder(prominent ? Color.clear : Palette.hairline, lineWidth: 0.8))
            .shadow(color: prominent ? Palette.gold.opacity(0.32) : .black.opacity(0.28), radius: 14, y: 8)
        }
        .buttonStyle(.plain)
    }
}
