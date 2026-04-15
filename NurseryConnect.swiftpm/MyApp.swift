import SwiftUI
import SwiftData

@main
struct NurseryConnectApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Child.self,
            DailyActivity.self,
            SleepLog.self,
            NappyLog.self,
            MoodLog.self,
            IncidentReport.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Schema changed (e.g. models added/removed) — wipe the stale store and start fresh.
            print("⚠️ ModelContainer failed (\(error)). Attempting to delete stale store and retry.")
            let supportDir = URL.applicationSupportDirectory
            let storeFiles = (try? FileManager.default.contentsOfDirectory(
                at: supportDir, includingPropertiesForKeys: nil)) ?? []
            for file in storeFiles where file.lastPathComponent.hasSuffix(".store")
                                     || file.lastPathComponent.hasSuffix(".store-shm")
                                     || file.lastPathComponent.hasSuffix(".store-wal") {
                try? FileManager.default.removeItem(at: file)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after store reset: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
