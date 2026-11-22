import Foundation
import MediaPlayer

/// 读取系统 Now Playing（Apple Music 也走这里）
final class NowPlayingMonitor {

    func snapshot() -> NowPlayingSnapshot {
        guard let info = MPNowPlayingInfoCenter.default().nowPlayingInfo else {
            return .empty
        }

        let title = (info[MPMediaItemPropertyTitle] as? String) ?? ""
        guard !title.isEmpty else { return .empty }

        let artist = (info[MPMediaItemPropertyArtist] as? String) ?? ""
        let album = (info[MPMediaItemPropertyAlbumTitle] as? String) ?? ""
        let duration = (info[MPMediaItemPropertyPlaybackDuration] as? NSNumber)?.doubleValue ?? 0
        let elapsed = (info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? NSNumber)?.doubleValue ?? 0
        let rate = (info[MPNowPlayingInfoPropertyPlaybackRate] as? NSNumber)?.doubleValue ?? 0

        return NowPlayingSnapshot(
            title: title,
            artist: artist,
            album: album,
            duration: max(0, duration),
            elapsed: max(0, elapsed),
            isPlaying: rate > 0.01,
            timestamp: Date(),
            // 系统不暴露来源 Bundle ID，这里不区分 App，任何 Now Playing 都可用
            isAppleMusic: true
        )
    }
}
