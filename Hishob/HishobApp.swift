import SwiftUI
import SwiftData

@main
struct HishobApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(AppModel.shared.container)
    }
}
