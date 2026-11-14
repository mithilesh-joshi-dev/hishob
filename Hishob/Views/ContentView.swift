import SwiftUI

struct ContentView: View {
    @State private var showingQuickAdd = false

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(showingQuickAdd: $showingQuickAdd)
            }
            .tabItem { Label("Spending", systemImage: "chart.bar.fill") }

            NavigationStack {
                HistoryView(showingQuickAdd: $showingQuickAdd)
            }
            .tabItem { Label("History", systemImage: "list.bullet") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .sheet(isPresented: $showingQuickAdd) {
            QuickAddView()
        }
        .onAppear {
            AppModel.shared.refreshWidgetSummary()
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-openQuickAdd") {
                showingQuickAdd = true
            }
            #endif
        }
        .onOpenURL { url in
            // hishob://add — used by the widget's tap target
            if url.scheme == "hishob" {
                showingQuickAdd = true
            }
        }
        .tint(Theme.brand)
    }
}

#Preview {
    ContentView()
        .modelContainer(AppModel.shared.container)
}
