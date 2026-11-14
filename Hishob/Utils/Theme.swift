import SwiftUI

/// Single brand accent plus two budget-state colors. Everything else uses
/// system surfaces so the money numbers carry the screen.
enum Theme {
    static let brand = Color(hex: "0E6B5C")
    static let brandDeep = Color(hex: "0A4F45")
    static let warning = Color(hex: "E8A33D")
    static let over = Color(hex: "D94F30")

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [brand, brandDeep],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension Font {
    /// Heavy rounded numerals — the app's typographic signature.
    static func money(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}
