import SwiftUI

enum AppTheme {
    static let backgroundColor = Color(hex: "0A0A0A")
    static let cardBackground = Color(hex: "1C1C1E")
    static let accentBlue = Color(hex: "0A84FF")
    static let accentGold = Color(hex: "FFD700")
    static let secondaryText = Color(hex: "8E8E93")
    static let divider = Color(hex: "2C2C2E")
    
    static let cardRadius: CGFloat = 16
    static let cardShadow: CGFloat = 5
    static let glassEffect = 0.15
    
    static let gradientStart = Color(hex: "1A1A1A")
    static let gradientEnd = Color(hex: "0A0A0A")
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 