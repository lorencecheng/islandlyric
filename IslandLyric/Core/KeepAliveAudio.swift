import AVFoundation

/// 后台保活：循环播放一段全零 PCM，音量输出为 0。
/// 作用：让 App 在后台不被立刻冻结，从而持续刷新实时活动。
final class KeepAliveAudio {

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let queue = DispatchQueue(label: "com.lorence.islandlyric.keepalive")
    private var running = false
    private var attached = false

    func start() {
        queue.async { self._start() }
    }

    func stop() {
        queue.async { self._stop() }
    }

    private func _start() {
        guard !running else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }
        let frames: AVAudioFrameCount = 22_050
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return }
        buffer.frameLength = frames
        if let channel = buffer.floatChannelData?[0] {
            for index in 0..<Int(frames) { channel[index] = 0 }
        }

        if !attached {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            attached = true
        }
        engine.mainMixerNode.outputVolume = 0

        do {
            try engine.start()
        } catch {
            return
        }

        player.scheduleBuffer(buffer, at: nil, options: [.loops])
        player.play()
        running = true
    }

    private func _stop() {
        guard running else { return }
        player.stop()
        engine.stop()
        running = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
