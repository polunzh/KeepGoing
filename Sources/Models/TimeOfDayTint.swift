import SwiftUI

enum TimeOfDayTint {

    // MARK: - Anchor definition

    private struct Anchor {
        let hour: Double
        let r, g, b: Double
        let opacity: Double
    }

    // MARK: - 18 anchor points: sun's journey through the day

    private static let anchors: [Anchor] = [
        Anchor(hour:  0.00, r: 0.06, g: 0.08, b: 0.30, opacity: 0.28),  // Deep night
        Anchor(hour:  3.00, r: 0.07, g: 0.09, b: 0.32, opacity: 0.30),  // Darkest hour
        Anchor(hour:  4.50, r: 0.12, g: 0.10, b: 0.35, opacity: 0.26),  // First light
        Anchor(hour:  5.25, r: 0.25, g: 0.15, b: 0.38, opacity: 0.22),  // Purple dawn
        Anchor(hour:  5.75, r: 0.70, g: 0.35, b: 0.30, opacity: 0.22),  // Red glow
        Anchor(hour:  6.25, r: 1.00, g: 0.55, b: 0.30, opacity: 0.20),  // Sunrise
        Anchor(hour:  6.75, r: 1.00, g: 0.70, b: 0.35, opacity: 0.18),  // Bright sunrise
        Anchor(hour:  7.50, r: 1.00, g: 0.85, b: 0.50, opacity: 0.14),  // Golden morning
        Anchor(hour:  9.00, r: 1.00, g: 0.95, b: 0.80, opacity: 0.08),  // Fading warmth
        Anchor(hour: 11.00, r: 1.00, g: 0.98, b: 0.92, opacity: 0.03),  // Near noon
        Anchor(hour: 13.00, r: 1.00, g: 1.00, b: 1.00, opacity: 0.00),  // Noon (clear)
        Anchor(hour: 15.00, r: 1.00, g: 0.96, b: 0.85, opacity: 0.05),  // Afternoon warm
        Anchor(hour: 16.50, r: 1.00, g: 0.85, b: 0.55, opacity: 0.10),  // Afternoon gold
        Anchor(hour: 17.50, r: 0.98, g: 0.60, b: 0.30, opacity: 0.18),  // Pre-sunset
        Anchor(hour: 18.00, r: 0.95, g: 0.40, b: 0.22, opacity: 0.24),  // Sunset red
        Anchor(hour: 18.50, r: 0.75, g: 0.28, b: 0.30, opacity: 0.22),  // Afterglow
        Anchor(hour: 19.25, r: 0.40, g: 0.18, b: 0.38, opacity: 0.22),  // Dusk purple
        Anchor(hour: 20.50, r: 0.12, g: 0.12, b: 0.35, opacity: 0.26),  // Nightfall
    ]

    // MARK: - Public API (unchanged)

    /// Returns a tint color to overlay on the card based on time of day.
    /// Smoothly interpolates between 18 anchor points across 24 hours.
    static func tintColor(for date: Date) -> Color {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)
        let second = cal.component(.second, from: date)
        let fractionalHour = Double(hour) + Double(minute) / 60.0 + Double(second) / 3600.0

        let (prev, next) = surroundingAnchors(for: fractionalHour)
        let t = interpolationFactor(current: fractionalHour, prev: prev.hour, next: next.hour)

        let r = prev.r + t * (next.r - prev.r)
        let g = prev.g + t * (next.g - prev.g)
        let b = prev.b + t * (next.b - prev.b)
        let opacity = prev.opacity + t * (next.opacity - prev.opacity)

        if opacity < 0.001 {
            return .clear
        }
        return Color(red: r, green: g, blue: b).opacity(opacity)
    }

    // MARK: - Internal (visible for testing)

    /// Exposed for unit tests: returns (r, g, b, opacity) at a fractional hour.
    static func interpolatedComponents(at fractionalHour: Double) -> (r: Double, g: Double, b: Double, opacity: Double) {
        let (prev, next) = surroundingAnchors(for: fractionalHour)
        let t = interpolationFactor(current: fractionalHour, prev: prev.hour, next: next.hour)
        return (
            r: prev.r + t * (next.r - prev.r),
            g: prev.g + t * (next.g - prev.g),
            b: prev.b + t * (next.b - prev.b),
            opacity: prev.opacity + t * (next.opacity - prev.opacity)
        )
    }

    // MARK: - Private helpers

    private static func surroundingAnchors(for hour: Double) -> (prev: Anchor, next: Anchor) {
        // Find the last anchor whose hour <= current hour
        // If current hour is before the first anchor or after the last, wrap around
        let count = anchors.count

        if hour < anchors[0].hour || hour >= anchors[count - 1].hour {
            // Wrap-around: between last anchor and first anchor (across midnight)
            return (anchors[count - 1], anchors[0])
        }

        for i in 0..<(count - 1) {
            if hour >= anchors[i].hour && hour < anchors[i + 1].hour {
                return (anchors[i], anchors[i + 1])
            }
        }

        // Should not reach here, but fallback to last segment
        return (anchors[count - 2], anchors[count - 1])
    }

    private static func interpolationFactor(current: Double, prev: Double, next: Double) -> Double {
        let gap: Double
        let elapsed: Double

        if next <= prev {
            // Wrap-around across midnight
            gap = (24.0 - prev) + next
            elapsed = current >= prev ? current - prev : (24.0 - prev) + current
        } else {
            gap = next - prev
            elapsed = current - prev
        }

        guard gap > 0 else { return 0 }
        return min(max(elapsed / gap, 0), 1)
    }
}
