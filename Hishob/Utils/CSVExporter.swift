import Foundation

enum CSVExporter {
    static func export(_ expenses: [Expense]) throws -> URL {
        var csv = "Date,Amount,Currency,Category,Note\n"
        let dateFormatter = ISO8601DateFormatter()
        for expense in expenses.sorted(by: { $0.date > $1.date }) {
            let note = expense.note.replacingOccurrences(of: "\"", with: "\"\"")
            let row = [
                dateFormatter.string(from: expense.date),
                "\(expense.amount)",
                Currency.selectedCode,
                expense.category?.name ?? "Uncategorized",
                "\"\(note)\""
            ].joined(separator: ",")
            csv += row + "\n"
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("hishob-expenses.csv")
        try csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
