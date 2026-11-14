import Foundation

/// Snapshot of today's spending, shared between the app and the widget
/// through App Group UserDefaults. The app rewrites it after every change;
/// the widget only reads.
struct SpendSummary: Codable {
    static let appGroupID = "group.com.mithilesh.hishob"
    static let key = "spendSummary"

    var todayTotal: Decimal
    var todayCount: Int
    var currencyCode: String
    var updatedAt: Date = .now

    var formattedTotal: String {
        todayTotal.formatted(.currency(code: currencyCode))
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupID),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.key)
    }

    static func load() -> SpendSummary? {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(SpendSummary.self, from: data)
    }
}
