import Foundation
import SwiftData
import WidgetKit

/// Shared SwiftData container used by both the app and App Intents (Siri / Back Tap).
final class AppModel {
    static let shared = AppModel()

    /// Flip to true to sync via iCloud. Requires a paid Apple Developer account:
    /// in Xcode add the iCloud capability (CloudKit) with container
    /// iCloud.com.mithilesh.hishob to the Hishob target, then rebuild.
    static let cloudSyncEnabled = false

    let container: ModelContainer

    private init() {
        do {
            let config = ModelConfiguration(
                cloudKitDatabase: Self.cloudSyncEnabled ? .automatic : .none
            )
            container = try ModelContainer(
                for: Expense.self, ExpenseCategory.self,
                configurations: config
            )
        } catch {
            fatalError("Failed to create model container: \(error)")
        }
        seedDefaultCategoriesIfNeeded()
    }

    private func seedDefaultCategoriesIfNeeded() {
        let context = ModelContext(container)
        let count = (try? context.fetchCount(FetchDescriptor<ExpenseCategory>())) ?? 0
        guard count == 0 else { return }
        for category in ExpenseCategory.makeDefaults() {
            context.insert(category)
        }
        try? context.save()
    }

    /// Recomputes today's totals into the App Group store and reloads widgets.
    /// Call after any change to expenses.
    @MainActor
    func refreshWidgetSummary() {
        let context = ModelContext(container)
        let startOfDay = Calendar.current.startOfDay(for: .now)
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate { $0.date >= startOfDay }
        )
        let todayExpenses = (try? context.fetch(descriptor)) ?? []
        let total = todayExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        SpendSummary(
            todayTotal: total,
            todayCount: todayExpenses.count,
            currencyCode: Currency.selectedCode
        ).save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
