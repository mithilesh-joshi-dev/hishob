import XCTest
@testable import TappyClone

final class CSVExporterTests: XCTestCase {
    func testExportProducesHeaderAndRows() throws {
        let food = ExpenseCategory(name: "Food", emoji: "🍔", colorHex: "FF9500")
        let expenses = [
            Expense(amount: 10, note: "lunch", category: food),
            Expense(amount: 2.5, note: "", category: nil)
        ]
        let url = try CSVExporter.export(expenses)
        let lines = try String(contentsOf: url, encoding: .utf8)
            .split(separator: "\n")
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "Date,Amount,Currency,Category,Note")
        XCTAssertTrue(lines.dropFirst().contains { $0.contains("Food") && $0.contains("\"lunch\"") })
        XCTAssertTrue(lines.dropFirst().contains { $0.contains("Uncategorized") })
    }

    func testExportEscapesQuotesInNotes() throws {
        let expenses = [Expense(amount: 5, note: #"the "best" coffee"#)]
        let url = try CSVExporter.export(expenses)
        let csv = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(csv.contains(#""the ""best"" coffee""#))
    }

    func testExportSortsNewestFirst() throws {
        let old = Expense(amount: 1, note: "old", date: Date(timeIntervalSince1970: 0))
        let new = Expense(amount: 2, note: "new", date: Date(timeIntervalSince1970: 1_000_000))
        let url = try CSVExporter.export([old, new])
        let csv = try String(contentsOf: url, encoding: .utf8)
        let newIndex = try XCTUnwrap(csv.range(of: "new")).lowerBound
        let oldIndex = try XCTUnwrap(csv.range(of: "old")).lowerBound
        XCTAssertLessThan(newIndex, oldIndex)
    }
}

final class SpendSummaryTests: XCTestCase {
    func testCodableRoundTrip() throws {
        let summary = SpendSummary(todayTotal: 123.45, todayCount: 7, currencyCode: "INR")
        let data = try JSONEncoder().encode(summary)
        let decoded = try JSONDecoder().decode(SpendSummary.self, from: data)
        XCTAssertEqual(decoded.todayTotal, Decimal(string: "123.45"))
        XCTAssertEqual(decoded.todayCount, 7)
        XCTAssertEqual(decoded.currencyCode, "INR")
    }
}

final class TotalsTests: XCTestCase {
    func testDecimalSumAvoidsFloatingPointDrift() {
        // 0.1 + 0.2 == 0.3 must hold exactly for money.
        let expenses = [Expense(amount: Decimal(string: "0.1")!),
                        Expense(amount: Decimal(string: "0.2")!)]
        let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        XCTAssertEqual(total, Decimal(string: "0.3"))
    }
}
