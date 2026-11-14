import Foundation
import SwiftData

@Model
final class ExpenseCategory {
    // No .unique attribute: CloudKit sync doesn't support unique constraints.
    // Name uniqueness is enforced in CategoriesView instead.
    // Defaults on all properties keep the schema CloudKit-compatible.
    var name: String = ""
    var emoji: String = "🏷️"
    var colorHex: String = "8E8E93"
    var isDefault: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense] = []

    init(name: String, emoji: String, colorHex: String, isDefault: Bool = false) {
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.isDefault = isDefault
    }

    static func makeDefaults() -> [ExpenseCategory] {
        [
            ExpenseCategory(name: "Food", emoji: "🍔", colorHex: "FF9500", isDefault: true),
            ExpenseCategory(name: "Transport", emoji: "🚕", colorHex: "007AFF", isDefault: true),
            ExpenseCategory(name: "Groceries", emoji: "🛒", colorHex: "34C759", isDefault: true),
            ExpenseCategory(name: "Shopping", emoji: "🛍️", colorHex: "AF52DE", isDefault: true),
            ExpenseCategory(name: "Bills", emoji: "🧾", colorHex: "FF3B30", isDefault: true),
            ExpenseCategory(name: "Entertainment", emoji: "🎬", colorHex: "FF2D55", isDefault: true),
            ExpenseCategory(name: "Health", emoji: "💊", colorHex: "32ADE6", isDefault: true),
            ExpenseCategory(name: "Other", emoji: "📦", colorHex: "8E8E93", isDefault: true)
        ]
    }
}
