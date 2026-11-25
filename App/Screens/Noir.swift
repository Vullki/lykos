import SwiftUI

/// Brushed Silver Noir colours for the screens Lykos draws itself. Black, silver and off-white only.
enum Noir {
    static let background = Color.black
    static let surface = hex(0x0D0D0D)
    /// Body text.
    static let text = hex(0xE6E4DF)
    /// Labels: flat silver, uppercase, wide tracking.
    static let label = hex(0xC2C2C2)
    static let muted = hex(0x808080)
    static let deep = hex(0x464646)

    /// About 0.3em tracking for a label of the given point size.
    static func labelTracking(_ size: CGFloat) -> CGFloat { size * 0.3 }

    private static func hex(_ value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
