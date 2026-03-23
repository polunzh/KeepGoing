import SwiftUI

enum TimeOfDayTint {
    enum Period: Equatable {
        case morning  // 6–10
        case midday   // 10–16
        case evening  // 16–19
        case night    // 19–6
    }

    static func period(for date: Date) -> Period {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 6..<10: return .morning
        case 10..<16: return .midday
        case 16..<19: return .evening
        default: return .night
        }
    }

    /// Returns a tint color to overlay on the card based on time of day.
    static func tintColor(for date: Date) -> Color {
        switch period(for: date) {
        case .morning: return Color(red: 1.0, green: 0.85, blue: 0.4).opacity(0.15)
        case .midday: return Color.clear
        case .evening: return Color(red: 0.85, green: 0.5, blue: 0.3).opacity(0.15)
        case .night: return Color(red: 0.15, green: 0.2, blue: 0.45).opacity(0.2)
        }
    }
}
