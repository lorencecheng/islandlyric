import ActivityKit
import WidgetKit
import SwiftUI

/// 灵动岛 / 锁屏 / CarPlay / 手表 共用一套实时活动
/// - medium 家族：锁屏卡片
/// - small 家族：CarPlay 卡片、手表智能叠放
struct LyricLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricActivityAttributes.self) { context in
            LiveActivityRootView(context: context)
                .activityBackgroundTint(Palette.ink.opacity(0.62))
                .activitySystemActionForegroundColor(Palette.gold)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 7) {
                        Image(systemName: "music.note")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.gold)
                        Text(context.attributes.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.isPlaying ? "PLAYING" : "PAUSED")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(1.1)
                        .foregroundStyle(context.state.isPlaying ? Palette.goldBright : Palette.textTertiary)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.gold)
            } compactTrailing: {
                CompactBars(isPlaying: context.state.isPlaying)
            } minimal: {
                Image(systemName: "music.note")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Palette.gold)
            }
            .keylineTint(Palette.gold)
            .widgetURL(URL(string: "islandlyric://now"))
        }
        .supplementalActivityFamilies([.small, .medium])
    }
}

/// 锁屏 / CarPlay / 手表 入口，按 activityFamily 分支
struct LiveActivityRootView: View {
    let context: ActivityViewContext<LyricActivityAttributes>
    @Environment(\.activityFamily) private var activityFamily

    var body: some View {
        Group {
            switch activityFamily {
            case .small:
                SmallFamilyView(context: context)
            default:
                MediumFamilyView(context: context)
            }
        }
    }
}

struct MediumFamilyView: View {
    let context: ActivityViewContext<LyricActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Circle()
                    .fill(context.state.isPlaying ? Palette.gold : Palette.textTertiary)
                    .frame(width: 6, height: 6)

                Text(context.attributes.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text(context.attributes.artist)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
            }

            Text(context.state.current)
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.goldBright)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)

            if !context.state.next.isEmpty {
                Text(context.state.next)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
            }

            LineProgressBar(value: context.state.trackProgress, height: 2.5)
                .padding(.top, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

struct SmallFamilyView: View {
    let context: ActivityViewContext<LyricActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: "music.note")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Palette.gold)
                Text(context.attributes.title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
            }

            Text(context.state.current)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.goldBright)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            LineProgressBar(value: context.state.trackProgress, height: 2)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<LyricActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(context.state.current)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.goldBright)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if !context.state.next.isEmpty {
                Text(context.state.next)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Palette.textTertiary)
                    .lineLimit(1)
            }

            LineProgressBar(value: context.state.trackProgress, height: 2)
        }
        .padding(.horizontal, 4)
        .padding(.top, 2)
        .padding(.bottom, 2)
    }
}

struct CompactBars: View {
    let isPlaying: Bool
    private let levels: [CGFloat] = [0.55, 0.95, 0.7]

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(levels.indices, id: \.self) { index in
                Capsule()
                    .fill(Palette.gold.opacity(isPlaying ? 0.9 : 0.3))
                    .frame(width: 2, height: 11 * levels[index])
            }
        }
        .frame(width: 12, height: 12)
    }
}

struct LineProgressBar: View {
    var value: Double
    var height: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Palette.gold.opacity(0.9), Palette.goldBright],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat(min(max(value, 0), 1)) * geometry.size.width)
            }
        }
        .frame(height: height)
    }
}
