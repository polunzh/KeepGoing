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
    case lavender
    case coral
    case ocean

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sky: "Sky"
        case .leaf: "Leaf"
        case .amber: "Amber"
        case .rose: "Rose"
        case .slate: "Slate"
        case .lavender: "Lavender"
        case .coral: "Coral"
        case .ocean: "Ocean"
        }
    }

    var startColor: Color {
        switch self {
        case .sky: Color(red: 0.23, green: 0.53, blue: 0.98)
        case .leaf: Color(red: 0.14, green: 0.62, blue: 0.46)
        case .amber: Color(red: 0.92, green: 0.58, blue: 0.15)
        case .rose: Color(red: 0.88, green: 0.29, blue: 0.45)
        case .slate: Color(red: 0.33, green: 0.39, blue: 0.48)
        case .lavender: Color(red: 0.55, green: 0.36, blue: 0.85)
        case .coral: Color(red: 0.95, green: 0.40, blue: 0.32)
        case .ocean: Color(red: 0.10, green: 0.45, blue: 0.68)
        }
    }

    var endColor: Color {
        switch self {
        case .sky: Color(red: 0.50, green: 0.78, blue: 1.0)
        case .leaf: Color(red: 0.48, green: 0.84, blue: 0.64)
        case .amber: Color(red: 0.98, green: 0.79, blue: 0.38)
        case .rose: Color(red: 0.97, green: 0.63, blue: 0.71)
        case .slate: Color(red: 0.62, green: 0.68, blue: 0.77)
        case .lavender: Color(red: 0.78, green: 0.62, blue: 0.96)
        case .coral: Color(red: 1.0, green: 0.68, blue: 0.55)
        case .ocean: Color(red: 0.32, green: 0.72, blue: 0.88)
        }
    }

    var badgeText: String {
        switch self {
        case .sky: "平静"
        case .leaf: "扎根"
        case .amber: "向前"
        case .rose: "温暖"
        case .slate: "沉稳"
        case .lavender: "灵感"
        case .coral: "热忱"
        case .ocean: "深远"
        }
    }
}
