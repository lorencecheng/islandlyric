import SwiftUI

@main
struct IslandLyricApp: App {
    @StateObject private var manager = LyricManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .preferredColorScheme(.dark)
                .task { await manager.start() }
                .onChange(of: scenePhase) { _, phase in
                    manager.handleScenePhase(phase)
                }
        }
    }
}
