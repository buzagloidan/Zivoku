import SwiftUI
import SwiftData

@main
struct SudokuForZivApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: ActiveGame.self, CompletedGame.self, DailyRecord.self)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
