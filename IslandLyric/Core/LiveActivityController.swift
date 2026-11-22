import ActivityKit
import Foundation

/// 实时活动的创建 / 更新 / 结束
final class LiveActivityController {

    static let shared = LiveActivityController()

    private var activity: Activity<LyricActivityAttributes>?

    var isActive: Bool { activity != nil }

    var areActivitiesEnabled: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    /// 返回是否成功创建
    @discardableResult
    func start(title: String, artist: String, lineCount: Int, state: LyricActivityAttributes.ContentState) -> Bool {
        guard areActivitiesEnabled else { return false }
        if activity != nil { return true }

        let attributes = LyricActivityAttributes(title: title, artist: artist, lineCount: lineCount)
        do {
            let content = ActivityContent(state: state, staleDate: nil)
            activity = try Activity.request(attributes: attributes, content: content)
            return true
        } catch {
            activity = nil
            return false
        }
    }

    func update(_ state: LyricActivityAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// 回收系统里残留的实时活动（上次进程被杀死没关掉的情况）
    func endAllStale() {
        Task {
            for activity in Activity<LyricActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
