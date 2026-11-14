import AppIntents
import Foundation
import SwiftData

/// Logs an expense without opening the app. Exposed to Siri and the Shortcuts
/// app, which makes it assignable to Back Tap (Accessibility → Touch → Back Tap).
struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Quickly log an expense to Hishob.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Amount", requestValueDialog: "How much did you spend?")
    var amount: Double

    @Parameter(title: "Category", optionsProvider: CategoryOptionsProvider())
    var categoryName: String?

    @Parameter(title: "Note")
    var note: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let context = ModelContext(AppModel.shared.container)

        var category: ExpenseCategory?
        if let categoryName {
            let descriptor = FetchDescriptor<ExpenseCategory>(
                predicate: #Predicate { $0.name == categoryName }
            )
            category = try? context.fetch(descriptor).first
        }

        let expense = Expense(
            amount: Decimal(amount),
            note: note ?? "",
            category: category
        )
        context.insert(expense)
        try context.save()
        AppModel.shared.refreshWidgetSummary()

        let formatted = Currency.format(Decimal(amount))
        return .result(dialog: "Logged \(formatted)\(category.map { " to \($0.name)" } ?? "")")
    }
}

struct CategoryOptionsProvider: DynamicOptionsProvider {
    @MainActor
    func results() async throws -> [String] {
        let context = ModelContext(AppModel.shared.container)
        let categories = (try? context.fetch(FetchDescriptor<ExpenseCategory>())) ?? []
        return categories.map(\.name).sorted()
    }
}

struct HishobShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log expense in \(.applicationName)",
                "Add expense to \(.applicationName)"
            ],
            shortTitle: "Log Expense",
            systemImageName: "plus.circle.fill"
        )
    }
}
