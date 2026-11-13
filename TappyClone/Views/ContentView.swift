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
        }
        .onOpenURL { url in
            // tappyclone://add — used by the widget's tap target
            if url.scheme == "tappyclone" {
                showingQuickAdd = true
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(AppModel.shared.container)
}
