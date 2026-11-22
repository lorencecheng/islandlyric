import Foundation
import ActivityKit

/// 灵动岛 / 锁屏 / CarPlay / 手表共用的实时活动数据结构
struct LyricActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// 当前句
        var current: String
        /// 下一句（锁屏 medium 卡片用）
        var next: String
        /// 当前句在整首歌中的进度 0...1
        var lineProgress: Double
        /// 整首进度 0...1
        var trackProgress: Double
        /// 是否正在播放
        var isPlaying: Bool
        /// 当前句开始时间（用于本地推进）
        var lineStart: Double
        /// 当前句时长
        var lineDuration: Double
        /// 播放锚点：系统时间 + 进度，用于让系统自己走
        var anchorTimestamp: Double
    }

    var title: String
    var artist: String
    var lineCount: Int
}
