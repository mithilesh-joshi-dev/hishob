import Foundation
import SwiftData

@Model
final class Expense {
    // Defaults on all properties keep the schema CloudKit-compatible.
    var amount: Decimal = 0
    var note: String = ""
    var date: Date = Date.now
    var category: ExpenseCategory?

    init(amount: Decimal, note: String = "", date: Date = .now, category: ExpenseCategory? = nil) {
        self.amount = amount
        self.note = note
        self.date = date
        self.category = category
    }
}
