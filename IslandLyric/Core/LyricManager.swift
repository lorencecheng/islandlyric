import Foundation
import SwiftUI
import Combine

enum SettingsKey {
    static let autoStart = "autoStartOnPlay"
    static let keepAlive = "keepAliveEnabled"
}

@MainActor
final class LyricManager: ObservableObject {

    @Published private(set) var snapshot: NowPlayingSnapshot = .empty
    @Published private(set) var track: LyricTrack?
    @Published private(set) var currentIndex: Int?
    @Published private(set) var lyricsStatus: LyricsStatus = .idle
    @Published private(set) var isActivityActive = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published var toast: String?

    private let monitor = NowPlayingMonitor()
    private let service = LyricsService()
    private let keepAlive = KeepAliveAudio()

    private var tickerTask: Task<Void, Never>?
    private var pollingTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    private var loadedIdentity: String?
    private var pendingIdentity: String?
    private var autoStartSince: Date?
    private var anchorDate = Date()
    private var anchorElapsed: TimeInterval = 0
    private var lastPushDate = Date.distantPast
    private var lastPushedLine = ""
    private var lastPushedProgress: Double = -1
    private var started = false

    private var defaults: UserDefaults { .standard }

    var autoStartOnPlay: Bool { defaults.object(forKey: SettingsKey.autoStart) as? Bool ?? true }
    var keepAliveEnabled: Bool { defaults.object(forKey: SettingsKey.keepAlive) as? Bool ?? true }

    // MARK: - 生命周期

    func start() async {
        guard !started else { return }
        started = true
        LiveActivityController.shared.endAllStale()
        isActivityActive = false
        refreshNowPlaying()
        startTicker()
        startPolling()
        if keepAliveEnabled { keepAlive.start() }
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            refreshNowPlaying()
            startPolling()
        case .background, .inactive:
            break
        @unknown default:
            break
        }
    }

    func applyKeepAliveSetting() {
        if keepAliveEnabled { keepAlive.start() } else { keepAlive.stop() }
    }

    // MARK: - 轮询与推进

    private func startTicker() {
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 200_000_000)
                if Task.isCancelled { break }
                self?.tick()
            }
        }
    }

    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 600_000_000)
                if Task.isCancelled { break }
                self?.poll()
            }
        }
    }

    private func tick() {
        guard !snapshot.isEmpty, snapshot.isPlaying else { return }
        elapsed = anchorElapsed + Date().timeIntervalSince(anchorDate)
        if snapshot.duration > 0 { elapsed = min(elapsed, snapshot.duration) }
        syncIndex(allowPush: true)
    }

    private func poll() {
        refreshNowPlaying()
        syncIndex(allowPush: false)
        maybeAutoStart()
    }

    func refreshNowPlaying() {
        let next = monitor.snapshot()
        let identityChanged = next.identity != snapshot.identity
        let playChanged = next.isPlaying != snapshot.isPlaying

        if identityChanged || playChanged {
            anchorDate = next.timestamp
            anchorElapsed = next.elapsed
            elapsed = next.elapsed
        } else if next.isPlaying {
            let local = anchorElapsed + Date().timeIntervalSince(anchorDate)
            if abs(local - next.elapsed) > 0.35 {
                anchorDate = next.timestamp
                anchorElapsed = next.elapsed
                elapsed = next.elapsed
            }
        }

        snapshot = next

        if identityChanged {
            currentIndex = nil
            loadedIdentity = nil
            autoStartSince = nil
            if next.isEmpty {
                track = nil
                lyricsStatus = .idle
            } else {
                loadLyrics(for: next)
            }
        }
    }

    // MARK: - 歌词加载

    private func loadLyrics(for snapshot: NowPlayingSnapshot) {
        guard !snapshot.isEmpty else { return }
        guard snapshot.identity != loadedIdentity, snapshot.identity != pendingIdentity else { return }

        let identity = snapshot.identity
        let title = snapshot.title
        let artist = snapshot.artist
        let album = snapshot.album
        let duration = snapshot.duration

        pendingIdentity = identity
        lyricsStatus = .loading
        loadTask?.cancel()

        loadTask = Task { [weak self] in
            guard let self else { return }
            let result = await self.service.lookup(title: title, artist: artist, album: album, duration: duration)
            guard !Task.isCancelled, self.pendingIdentity == identity else { return }

            self.pendingIdentity = nil
            self.loadedIdentity = identity

            switch result {
            case .success(let value):
                self.track = value
                self.currentIndex = value.index(at: self.elapsed)
                self.lyricsStatus = .ready
            case .failure(let error):
                self.track = nil
                self.currentIndex = nil
                self.lyricsStatus = .failed(error.errorDescription ?? "歌词匹配失败")
            }

            self.maybeAutoStart()
            self.syncIndex(allowPush: true)
        }
    }

    func reloadLyrics() async {
        loadTask?.cancel()
        pendingIdentity = nil
        loadedIdentity = nil
        track = nil
        currentIndex = nil

        guard !snapshot.isEmpty else {
            lyricsStatus = .idle
            showToast("先播放一首歌再匹配歌词")
            return
        }
        loadLyrics(for: snapshot)
    }

    // MARK: - 自动上岛

    private func maybeAutoStart() {
        guard autoStartOnPlay,
              !isActivityActive,
              snapshot.isPlaying,
              let track, !track.isEmpty,
              currentIndex != nil else {
            autoStartSince = nil
            return
        }

        if let since = autoStartSince {
            if Date().timeIntervalSince(since) >= 2.0 {
                autoStartSince = nil
                startActivity(manual: false)
            }
        } else {
            autoStartSince = Date()
        }
    }

    // MARK: - 实时活动

    func toggleActivity() {
        if isActivityActive { stopActivity() } else { startActivity(manual: true) }
    }

    private func startActivity(manual: Bool) {
        guard let track, !track.isEmpty, let index = currentIndex, index < track.lines.count else {
            if manual { showToast("还没有匹配到歌词，先播放一首歌") }
            return
        }

        let state = makeState(lineIndex: index)
        let ok = LiveActivityController.shared.start(
            title: snapshot.title,
            artist: snapshot.artist,
            lineCount: track.lines.count,
            state: state
        )

        guard ok else {
            if manual { showToast("实时活动被关闭了：到 设置 › IslandLyric 打开实时活动") }
            return
        }

        isActivityActive = true
        lastPushedLine = track.lines[index].text
        lastPushedProgress = trackProgress
        lastPushDate = Date()
        if manual { showToast("已上岛，锁屏与 CarPlay 同步显示") }
    }

    func stopActivity() {
        LiveActivityController.shared.end()
        isActivityActive = false
        lastPushedLine = ""
        lastPushedProgress = -1
        lastPushDate = .distantPast
    }

    private func syncIndex(allowPush: Bool) {
        guard let track, !track.isEmpty else { return }
        let index = track.index(at: elapsed)

        if index != currentIndex {
            currentIndex = index
            pushActivity(force: true)
        } else if allowPush {
            pushActivity(force: false)
        }
    }

    private func pushActivity(force: Bool) {
        guard isActivityActive,
              let track,
              let index = currentIndex,
              index < track.lines.count else { return }

        let line = track.lines[index]
        let now = Date()
        let lineChanged = line.text != lastPushedLine
        let progressDelta = abs(trackProgress - lastPushedProgress)
        let cooldownPassed = now.timeIntervalSince(lastPushDate) >= 4

        guard force || lineChanged || progressDelta > 0.12 || cooldownPassed else { return }

        LiveActivityController.shared.update(makeState(lineIndex: index))
        lastPushedLine = line.text
        lastPushedProgress = trackProgress
        lastPushDate = now
    }

    private func makeState(lineIndex: Int) -> LyricActivityAttributes.ContentState {
        let line = track?.lines[safe: lineIndex]
        let next = track?.lines[safe: lineIndex + 1]
        let span = max(0.4, (line?.end ?? 0) - (line?.start ?? 0))

        return LyricActivityAttributes.ContentState(
            current: line?.text ?? "",
            next: next?.text ?? "",
            lineProgress: lineProgress,
            trackProgress: trackProgress,
            isPlaying: snapshot.isPlaying,
            lineStart: line?.start ?? 0,
            lineDuration: span,
            anchorTimestamp: Date().timeIntervalSince1970
        )
    }

    // MARK: - 派生状态

    var trackProgress: Double {
        guard snapshot.duration > 0 else { return 0 }
        return min(max(elapsed / snapshot.duration, 0), 1)
    }

    var lineProgress: Double {
        guard let track, let index = currentIndex, index < track.lines.count else { return 0 }
        let line = track.lines[index]
        let span = max(0.4, line.end - line.start)
        return min(max((elapsed - line.start) / span, 0), 1)
    }

    func line(at offset: Int) -> LyricLine? {
        guard let track, let index = currentIndex else { return nil }
        return track.lines[safe: index + offset]
    }

    // MARK: - 提示

    private func showToast(_ text: String) {
        toastTask?.cancel()
        withAnimation(.easeOut(duration: 0.24)) { toast = text }
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if Task.isCancelled { return }
            self?.dismissToast()
        }
    }

    func dismissToast() {
        toast = nil
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
