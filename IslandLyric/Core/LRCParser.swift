import Foundation

/// 标准 LRC 解析器（支持一行多时间戳、增强型 LRC 的尖括号标签）
enum LRCParser {

    static func parse(_ raw: String) -> [LyricLine] {
        var entries: [(time: TimeInterval, text: String)] = []

        for line in raw.split(separator: "\n", omittingEmptySubsequences: true) {
            var rest = String(line)
            var times: [TimeInterval] = []

            // 逐个剥离开头的时间标签
            while rest.hasPrefix("[") {
                guard let close = rest.firstIndex(of: "]") else { break }
                let tag = String(rest[rest.index(after: rest.startIndex)..<close])
                guard let time = timeFromTag(tag) else {
                    // 元数据标签（[ar:] [ti:] 等），整行跳过
                    times.removeAll()
                    break
                }
                times.append(time)
                rest = String(rest[rest.index(after: close)...])
            }

            guard !times.isEmpty else { continue }
            let text = stripInlineTags(rest).trimmingCharacters(in: .whitespacesAndNewlines)
            for time in times {
                entries.append((time, text))
            }
        }

        entries.sort { $0.time < $1.time }

        // 同一时间点的重复行保留文字更长的那条
        var unique: [(time: TimeInterval, text: String)] = []
        for entry in entries {
            if let last = unique.last, abs(last.time - entry.time) < 0.02 {
                if entry.text.count > last.text.count {
                    unique[unique.count - 1] = entry
                }
            } else {
                unique.append(entry)
            }
        }

        // 去掉空文本（纯伴奏行）
        let kept = unique.filter { !$0.text.isEmpty }
        guard !kept.isEmpty else { return [] }

        var lines: [LyricLine] = []
        lines.reserveCapacity(kept.count)
        for (index, entry) in kept.enumerated() {
            let nextStart = index + 1 < kept.count ? kept[index + 1].time : entry.time + 4.0
            let end = max(nextStart, entry.time + 0.35)
            lines.append(LyricLine(id: index, start: entry.time, end: end, text: entry.text))
        }
        return lines
    }

    /// "01:23.45" / "1:23" / "01:23:45"
    private static func timeFromTag(_ tag: String) -> TimeInterval? {
        let parts = tag.split(separator: ":")
        guard parts.count >= 2 else { return nil }

        var minutes: Double = 0
        var seconds: Double = 0
        var hours: Double = 0

        if parts.count == 2 {
            guard let m = Double(parts[0]), let s = Double(parts[1].replacingOccurrences(of: ",", with: ".")) else { return nil }
            minutes = m
            seconds = s
        } else if parts.count == 3 {
            guard let h = Double(parts[0]),
                  let m = Double(parts[1]),
                  let s = Double(parts[2].replacingOccurrences(of: ",", with: ".")) else { return nil }
            hours = h
            minutes = m
            seconds = s
        } else {
            return nil
        }

        guard minutes < 100, seconds < 70, hours < 100 else { return nil }
        return hours * 3600 + minutes * 60 + seconds
    }

    /// 去掉增强型 LRC 的 <mm:ss.xx> 与 {\an8} 这类标签
    private static func stripInlineTags(_ text: String) -> String {
        var result = ""
        var depth = 0
        for character in text {
            if character == "<" || character == "{" {
                depth += 1
                continue
            }
            if character == ">" || character == "}" {
                depth = max(0, depth - 1)
                continue
            }
            if depth == 0 { result.append(character) }
        }
        return result
    }
}
