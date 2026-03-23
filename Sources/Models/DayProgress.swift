import Foundation

enum DayProgress {
    /// Returns the fraction of the day elapsed (0.0 at midnight, ~1.0 at 23:59).
    static func fraction(for date: Date) -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let elapsed = date.timeIntervalSince(startOfDay)
        let totalSeconds: Double = 24 * 60 * 60
        return min(max(elapsed / totalSeconds, 0), 1)
    }

    /// Returns the integer percentage of the day elapsed (0–99).
    static func percent(for date: Date) -> Int {
        Int(fraction(for: date) * 100)
    }
}
