# Sun Gradient Tint Design

## Overview

Replace the 4-step hard-cut `TimeOfDayTint` with a smooth, continuous 18-anchor-point interpolation system that mimics the sun's journey throughout the day — from deep night blue through sunrise orange, transparent midday, sunset red, and back to night.

## Motivation

The current `TimeOfDayTint` uses 4 discrete time periods (morning/midday/evening/night) with abrupt transitions. This feels mechanical. A smooth gradient based on actual clock time creates a living, organic atmosphere that changes imperceptibly throughout the day.

## Design

### Approach: Enhanced Overlay (Option B)

- **Keep** the existing per-reminder 256-color palette as the base gradient
- **Replace** the 4-step `TimeOfDayTint` with continuous interpolation
- **No changes** to calling code — the API `TimeOfDayTint.tintColor(for: Date) -> Color` stays identical

### Color Anchor Points (18 points)

| Hour  | RGB                        | Description    | Opacity |
|-------|----------------------------|----------------|---------|
| 0:00  | (0.06, 0.08, 0.30)        | Deep night     | 0.28    |
| 3:00  | (0.07, 0.09, 0.32)        | Darkest hour   | 0.30    |
| 4:30  | (0.12, 0.10, 0.35)        | First light    | 0.26    |
| 5:15  | (0.25, 0.15, 0.38)        | Purple dawn    | 0.22    |
| 5:45  | (0.70, 0.35, 0.30)        | Red glow       | 0.22    |
| 6:15  | (1.00, 0.55, 0.30)        | Sunrise        | 0.20    |
| 6:45  | (1.00, 0.70, 0.35)        | Bright sunrise | 0.18    |
| 7:30  | (1.00, 0.85, 0.50)        | Golden morning | 0.14    |
| 9:00  | (1.00, 0.95, 0.80)        | Fading warmth  | 0.08    |
| 11:00 | (1.00, 0.98, 0.92)        | Near noon      | 0.03    |
| 13:00 | (1.00, 1.00, 1.00)        | Noon (clear)   | 0.00    |
| 15:00 | (1.00, 0.96, 0.85)        | Afternoon warm | 0.05    |
| 16:30 | (1.00, 0.85, 0.55)        | Afternoon gold | 0.10    |
| 17:30 | (0.98, 0.60, 0.30)        | Pre-sunset     | 0.18    |
| 18:00 | (0.95, 0.40, 0.22)        | Sunset red     | 0.24    |
| 18:30 | (0.75, 0.28, 0.30)        | Afterglow      | 0.22    |
| 19:15 | (0.40, 0.18, 0.38)        | Dusk purple    | 0.22    |
| 20:30 | (0.12, 0.12, 0.35)        | Nightfall      | 0.26    |

The table wraps: 20:30 → 0:00 interpolates back to the first anchor.

### Data Structure

```swift
struct SunAnchor {
    let hour: Double    // fractional hour, e.g. 6.25 = 6:15
    let r, g, b: Double
    let opacity: Double
}
```

Anchors stored as a sorted `[SunAnchor]` array (ascending by hour).

### Interpolation Algorithm

1. Convert current time to fractional hours (e.g., 6:30 → 6.5)
2. Find the two surrounding anchor points via linear scan of the sorted array
3. **Midnight wrap-around**: if `currentHour >= lastAnchor.hour`, then `prev = lastAnchor` and `next = firstAnchor`. Compute the gap as `(24.0 - prev.hour) + next.hour`, and `elapsed = currentHour - prev.hour`
4. Calculate `t = elapsed / gap`, normalized to [0, 1]
5. Linearly interpolate R, G, B, and opacity independently: `value = prev + t * (next - prev)`
6. Return `Color(red:green:blue:).opacity(interpolatedOpacity)`

Note: linear interpolation in sRGB may produce slightly desaturated midpoints during dawn/dusk transitions. With 18 closely-spaced anchors the perceptual impact is minimal. Can be upgraded to Oklab interpolation later if needed.

### Time Model

- Fixed sun times: sunrise ~6:00, sunset ~18:00
- No location services or permissions required
- Consistent behavior across all time zones

## Files Changed

| File | Change |
|------|--------|
| `Sources/Models/TimeOfDayTint.swift` | Rewrite: anchor array + interpolation logic, remove `Period` enum |
| `Tests/KeepGoingTests/ReminderStoreTests.swift` | Rewrite `TimeOfDayTintTests`: replace `Period`-based assertions with color/opacity value checks |

The `FloatingReminderPanelView` already calls `TimeOfDayTint.tintColor(for: currentTime)` every second via its timer — no changes needed there.

## Test Plan

Existing tests (4 tests in `TimeOfDayTintTests`) assert against the `Period` enum which will be removed. Replace with:

- **Noon returns near-zero opacity**: at 13:00, opacity should be ~0.0
- **Night returns high opacity blue tint**: at 3:00, opacity should be ~0.30, blue channel dominant
- **Sunrise returns warm tint**: at 6:15, red channel should be high (~1.0), opacity ~0.20
- **Sunset returns red tint**: at 18:00, red channel dominant, opacity ~0.24
- **Midnight wrap-around**: at 22:00 (between 20:30 and 0:00), should interpolate smoothly without crash
- **Boundary precision**: at exactly an anchor time, output should match that anchor's values exactly

## Backward Compatibility

- The `Period` enum is removed (only consumed by tests, which are rewritten)
- The public API signature `tintColor(for: Date) -> Color` is unchanged
- Visual change is gradual and non-breaking
