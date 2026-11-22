import Foundation

enum LyricsStatus: Equatable {
    case idle
    case loading
    case ready
    case failed(String)
}

enum LyricsError: LocalizedError {
    case notFound
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "没找到这首歌的逐句歌词"
        case .network(let message):
            return "歌词请求失败：\(message)"
        }
    }
}

/// 歌词源：LRCLIB（公开在线歌词库，无需 key）
/// 三级匹配：/api/get 精确 → /api/search 结构化 → 分数选最优
final class LyricsService {

    private struct Item: Decodable {
        let trackName: String?
        let artistName: String?
        let albumName: String?
        let duration: Double?
        let instrumental: Bool?
        let plainLyrics: String?
        let syncedLyrics: String?
    }

    private let session: URLSession
    private let decoder = JSONDecoder()
    private var memory: [String: LyricTrack] = [:]

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 12
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
    }

    func lookup(title: String, artist: String, album: String, duration: TimeInterval) async -> Result<LyricTrack, LyricsError> {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return .failure(.notFound) }

        let key = cacheKey(title: trimmedTitle, artist: artist, duration: duration)

        if let cached = memory[key] { return .success(cached) }
        if let disk = loadFromDisk(key: key, title: trimmedTitle, artist: artist) {
            memory[key] = disk
            return .success(disk)
        }

        var query = [URLQueryItem(name: "track_name", value: trimmedTitle)]
        if !artist.isEmpty { query.append(URLQueryItem(name: "artist_name", value: artist)) }
        if !album.isEmpty { query.append(URLQueryItem(name: "album_name", value: album)) }
        if duration > 0 { query.append(URLQueryItem(name: "duration", value: String(Int(duration.rounded())))) }

        do {
            let (data, status) = try await fetch(path: "/api/get", query: query)
            if status == 200, let item = try? decoder.decode(Item.self, from: data),
               let track = makeTrack(item, fallbackTitle: trimmedTitle, fallbackArtist: artist) {
                memory[key] = track
                saveToDisk(track, key: key)
                return .success(track)
            }

            if let track = try await search(title: trimmedTitle, artist: artist, duration: duration) {
                memory[key] = track
                saveToDisk(track, key: key)
                return .success(track)
            }

            return .failure(.notFound)
        } catch {
            return .failure(.network(error.localizedDescription))
        }
    }

    static func clearCache() {
        guard let dir = cacheDirectory() else { return }
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.lastPathComponent.hasPrefix("lyrics-") {
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - 搜索

    private func search(title: String, artist: String, duration: TimeInterval) async throws -> LyricTrack? {
        var query = [URLQueryItem(name: "track_name", value: title)]
        if !artist.isEmpty { query.append(URLQueryItem(name: "artist_name", value: artist)) }

        let (data, status) = try await fetch(path: "/api/search", query: query)
        guard status == 200, let items = try? decoder.decode([Item].self, from: data) else { return nil }

        let candidates = items.filter { item in
            guard let synced = item.syncedLyrics, !synced.isEmpty else { return false }
            return (item.instrumental ?? false) == false
        }

        let ranked = candidates.sorted { score($0, duration: duration, artist: artist) > score($1, duration: duration, artist: artist) }
        guard let best = ranked.first else { return nil }
        return makeTrack(best, fallbackTitle: title, fallbackArtist: artist)
    }

    private func score(_ item: Item, duration: TimeInterval, artist: String) -> Double {
        var score = 0.0
        if let itemDuration = item.duration, duration > 0 {
            score += max(0, 3.0 - abs(itemDuration - duration))
        }
        if let itemArtist = item.artistName, !artist.isEmpty,
           itemArtist.lowercased().contains(artist.lowercased()) {
            score += 2.0
        }
        return score
    }

    private func makeTrack(_ item: Item, fallbackTitle: String, fallbackArtist: String) -> LyricTrack? {
        guard let synced = item.syncedLyrics, !synced.isEmpty else { return nil }
        let lines = LRCParser.parse(synced)
        guard !lines.isEmpty else { return nil }
        return LyricTrack(
            title: item.trackName ?? fallbackTitle,
            artist: item.artistName ?? fallbackArtist,
            album: item.albumName ?? "",
            duration: item.duration ?? 0,
            lines: lines,
            source: "LRCLIB"
        )
    }

    // MARK: - 网络

    private func fetch(path: String, query: [URLQueryItem]) async throws -> (data: Data, status: Int) {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "lrclib.net"
        components.path = path
        components.queryItems = query
        guard let url = components.url else { throw LyricsError.notFound }

        var request = URLRequest(url: url)
        request.setValue("IslandLyric/1.0 (iOS; personal build)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 429, let header = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Retry-After"),
           let seconds = Double(header) {
            let delay = UInt64(min(max(seconds, 0.5), 5) * 1_000_000_000)
            try await Task.sleep(nanoseconds: delay)
            let (retryData, retryResponse) = try await session.data(for: request)
            return (retryData, (retryResponse as? HTTPURLResponse)?.statusCode ?? 0)
        }

        return (data, status)
    }

    // MARK: - 缓存

    private func cacheKey(title: String, artist: String, duration: TimeInterval) -> String {
        let minutes = duration > 0 ? Int(duration.rounded()) : 0
        return "\(title.lowercased())|\(artist.lowercased())|\(minutes)"
    }

    private func stableHash(_ input: String) -> String {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in input.utf8 {
            hash = (hash ^ UInt64(byte)) * 0x100_0000_01b3
        }
        return String(hash, radix: 16)
    }

    private static func cacheDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent("Lyrics", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func diskURL(for key: String) -> URL? {
        Self.cacheDirectory()?.appendingPathComponent("lyrics-\(stableHash(key)).lrc")
    }

    private func loadFromDisk(key: String, title: String, artist: String) -> LyricTrack? {
        guard let url = diskURL(for: key), let data = try? Data(contentsOf: url) else { return nil }
        let lines = LRCParser.parse(String(decoding: data, as: UTF8.self))
        guard !lines.isEmpty else { return nil }
        return LyricTrack(title: title, artist: artist, album: "", duration: 0, lines: lines, source: "LRCLIB")
    }

    private func saveToDisk(_ track: LyricTrack, key: String) {
        guard let url = diskURL(for: key) else { return }
        let raw = track.lines
            .map { line in
                let minutes = Int(line.start) / 60
                let seconds = line.start - Double(minutes * 60)
                return String(format: "[%02d:%05.2f]%@", minutes, seconds, line.text)
            }
            .joined(separator: "\n")
        try? raw.data(using: .utf8)?.write(to: url, options: .atomic)
    }
}
