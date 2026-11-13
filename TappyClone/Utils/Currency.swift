import Foundation
import SwiftUI

enum Currency {
    static let storageKey = "currencyCode"

    static let common = ["USD", "EUR", "GBP", "INR", "JPY", "AUD", "CAD", "SGD", "AED", "CNY"]

    static var selectedCode: String {
        UserDefaults.standard.string(forKey: storageKey)
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    static func format(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: selectedCode))
    }
}

extension Color {
    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex.replacingOccurrences(of: "#", with: "")).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
