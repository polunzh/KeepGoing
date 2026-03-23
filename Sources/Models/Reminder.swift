import SwiftUI

struct Reminder: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var message: String
    var palette: ReminderPalette
    var isEnabled: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        palette: ReminderPalette,
        isEnabled: Bool = true,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.palette = palette
        self.isEnabled = isEnabled
        self.updatedAt = updatedAt
    }
}

// MARK: - Hue-based Palette (256 colors)

struct ReminderPalette: Codable, Equatable, Identifiable {
    let hue: Double // 0.0 – 1.0

    init(hue: Double) {
        self.hue = hue
    }

    var id: Double { hue }

    /// Generate start color: saturated, medium brightness
    var startColor: Color {
        Color(hue: hue, saturation: 0.65, brightness: 0.85)
    }

    /// Generate end color: lighter, less saturated
    var endColor: Color {
        Color(hue: (hue + 0.03).truncatingRemainder(dividingBy: 1.0), saturation: 0.35, brightness: 0.95)
    }

    /// Badge text derived from hue range
    var badgeText: String {
        let segment = Int(hue * 8) % 8
        return ["平静", "清新", "扎根", "向前", "温暖", "热忱", "灵感", "深远"][segment]
    }

    // MARK: - 256 Presets (16x16 grid)

    /// All 256 preset palettes: 16 hues x 16 saturation/brightness variations
    static let allPresets: [ReminderPalette] = {
        var palettes: [ReminderPalette] = []
        for row in 0..<16 {
            for col in 0..<16 {
                let hue = Double(col) / 16.0
                // Shift hue slightly per row for variety
                let hueShift = Double(row) * 0.003
                let finalHue = (hue + hueShift).truncatingRemainder(dividingBy: 1.0)
                palettes.append(ReminderPalette(hue: finalHue))
            }
        }
        return palettes
    }()

    /// Grid of 16x16 palettes organized by row/col
    static func preset(row: Int, col: Int) -> ReminderPalette {
        allPresets[row * 16 + col]
    }

    // MARK: - Named presets (backward compatible)

    static let sky = ReminderPalette(hue: 0.58)
    static let leaf = ReminderPalette(hue: 0.42)
    static let amber = ReminderPalette(hue: 0.08)
    static let rose = ReminderPalette(hue: 0.95)
    static let slate = ReminderPalette(hue: 0.6)
    static let lavender = ReminderPalette(hue: 0.75)
    static let coral = ReminderPalette(hue: 0.03)
    static let ocean = ReminderPalette(hue: 0.55)

    // MARK: - Codable (backward compatible with old enum strings)

    private static let legacyMap: [String: Double] = [
        "sky": 0.58, "leaf": 0.42, "amber": 0.08, "rose": 0.95,
        "slate": 0.6, "lavender": 0.75, "coral": 0.03, "ocean": 0.55,
    ]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try decoding as Double (new format)
        if let hueValue = try? container.decode(Double.self) {
            self.hue = hueValue
        }
        // Try decoding as String (legacy enum format)
        else if let stringValue = try? container.decode(String.self),
                let mappedHue = Self.legacyMap[stringValue] {
            self.hue = mappedHue
        }
        // Fallback
        else {
            self.hue = 0.58
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(hue)
    }
}
