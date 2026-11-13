import SwiftUI
import SwiftData

@main
struct TappyCloneApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(AppModel.shared.container)
    }
}
