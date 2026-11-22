import Foundation

/// 一整首歌的逐句歌词
struct LyricLine: Identifiable, Hashable {
    let id: Int
    let start: TimeInterval
    let end: TimeInterval
    var text: String
}

struct LyricTrack: Hashable {
    let title: String
    let artist: String
    let album: String
    let duration: TimeInterval
    let lines: [LyricLine]
    let source: String

    var isEmpty: Bool { lines.isEmpty }

    /// 按播放时间找当前句下标（二分查找）
    func index(at time: TimeInterval) -> Int? {
        guard !lines.isEmpty else { return nil }
        if time < lines[0].start { return 0 }
        var low = 0
        var high = lines.count - 1
        var result = 0
        while low <= high {
            let mid = (low + high) / 2
            if lines[mid].start <= time {
                result = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return result
    }
}

/// Now Playing 的快照
struct NowPlayingSnapshot: Equatable {
    var title: String
    var artist: String
    var album: String
    var duration: TimeInterval
    var elapsed: TimeInterval
    var isPlaying: Bool
    var timestamp: Date
    var isAppleMusic: Bool

    static let empty = NowPlayingSnapshot(
        title: "", artist: "", album: "", duration: 0,
        elapsed: 0, isPlaying: false, timestamp: .distantPast, isAppleMusic: false
    )

    var isEmpty: Bool { title.isEmpty }

    var identity: String { "\(title)|\(artist)|\(album)|\(Int(duration.rounded()))" }
}
