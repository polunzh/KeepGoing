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

enum ReminderPalette: String, CaseIterable, Codable, Identifiable {
    case sky
    case leaf
    case amber
    case rose
    case slate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sky: "Sky"
        case .leaf: "Leaf"
        case .amber: "Amber"
        case .rose: "Rose"
        case .slate: "Slate"
        }
    }

    var startColor: Color {
        switch self {
        case .sky: Color(red: 0.23, green: 0.53, blue: 0.98)
        case .leaf: Color(red: 0.14, green: 0.62, blue: 0.46)
        case .amber: Color(red: 0.92, green: 0.58, blue: 0.15)
        case .rose: Color(red: 0.88, green: 0.29, blue: 0.45)
        case .slate: Color(red: 0.33, green: 0.39, blue: 0.48)
        }
    }

    var endColor: Color {
        switch self {
        case .sky: Color(red: 0.50, green: 0.78, blue: 1.0)
        case .leaf: Color(red: 0.48, green: 0.84, blue: 0.64)
        case .amber: Color(red: 0.98, green: 0.79, blue: 0.38)
        case .rose: Color(red: 0.97, green: 0.63, blue: 0.71)
        case .slate: Color(red: 0.62, green: 0.68, blue: 0.77)
        }
    }

    var badgeText: String {
        switch self {
        case .sky: "Calm"
        case .leaf: "Grounded"
        case .amber: "Forward"
        case .rose: "Warm"
        case .slate: "Steady"
        }
    }
}
