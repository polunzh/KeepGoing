import Foundation
import Testing
@testable import KeepGoing

// MARK: - Bug 1: Floating panel should use currentReminder, not dailyReminder

@Suite("Floating Panel Switching")
struct FloatingPanelSwitchingTests {

    /// After calling selectNextReminder(), currentReminder should change to the next one.
    /// This is the core bug: the floating panel used dailyReminder (date-based, static)
    /// instead of currentReminder (selection-based, dynamic).
    @Test @MainActor
    func selectNextReminder_changesCurrentReminder() {
        let store = ReminderStore(userDefaults: .ephemeral())
        let initial = store.currentReminder
        store.selectNextReminder()
        let next = store.currentReminder

        #expect(initial != nil)
        #expect(next != nil)
        #expect(initial?.id != next?.id, "currentReminder should change after selectNextReminder()")
    }

    /// selectNextReminder should wrap around to the first reminder after the last one.
    @Test @MainActor
    func selectNextReminder_wrapsAroundAtEnd() {
        let store = ReminderStore(userDefaults: .ephemeral())
        let enabledCount = store.reminders.filter(\.isEnabled).count
        let firstEnabled = store.reminders.filter(\.isEnabled).first

        // Cycle through all enabled reminders
        for _ in 0..<enabledCount {
            store.selectNextReminder()
        }

        // Should wrap back to first enabled
        #expect(store.currentReminder?.id == firstEnabled?.id)
    }

    /// selectNextReminder should skip disabled reminders.
    @Test @MainActor
    func selectNextReminder_skipsDisabledReminders() {
        let store = ReminderStore(userDefaults: .ephemeral())

        // Disable all but first and last
        let first = store.reminders[0]
        let last = store.reminders[store.reminders.count - 1]
        for i in 1..<(store.reminders.count - 1) {
            var r = store.reminders[i]
            r.isEnabled = false
            store.updateReminder(r)
        }

        store.selectReminder(id: first.id)
        store.selectNextReminder()

        #expect(store.currentReminder?.id == last.id,
                "Should jump to last (next enabled), skipping disabled ones")
    }

    /// currentReminder must always reflect selectedReminderID.
    @Test @MainActor
    func currentReminder_reflectsSelectedID() {
        let store = ReminderStore(userDefaults: .ephemeral())
        let target = store.reminders[2]
        store.selectReminder(id: target.id)

        #expect(store.currentReminder?.id == target.id)
    }

    /// The floating panel's displayed reminder must change when selectNextReminder is called.
    /// This tests `floatingPanelReminder`, the property the floating panel view should use.
    @Test @MainActor
    func floatingPanelReminder_changesOnSelectNext() {
        let store = ReminderStore(userDefaults: .ephemeral())
        let initial = store.floatingPanelReminder
        store.selectNextReminder()
        let next = store.floatingPanelReminder

        #expect(initial != nil)
        #expect(next != nil)
        #expect(initial?.id != next?.id,
                "floatingPanelReminder must change when selectNextReminder() is called")
    }
}

// MARK: - Bug 2: Cycle interval model behavior

@Suite("Cycle Interval")
struct CycleIntervalTests {

    /// Setting cycleInterval should persist and be retrievable.
    @Test @MainActor
    func cycleInterval_persists() {
        let defaults = UserDefaults.ephemeral()
        let store = ReminderStore(userDefaults: defaults)
        store.cycleInterval = 300 // 5 minutes

        let store2 = ReminderStore(userDefaults: defaults)
        #expect(store2.cycleInterval == 300)
    }

    /// The default cycle interval should be 86400 (daily).
    @Test @MainActor
    func cycleInterval_defaultIsDaily() {
        let store = ReminderStore(userDefaults: .ephemeral())
        #expect(store.cycleInterval == 86400)
    }
}

// MARK: - Palette variety

@Suite("Palette")
struct PaletteTests {

    /// Should have 256 presets (16x16 grid).
    @Test
    func palette_has256Presets() {
        #expect(ReminderPalette.allPresets.count == 256)
    }

    /// Every palette must have distinct start and end colors (gradient, not flat).
    @Test
    func palette_allHaveGradient() {
        for palette in ReminderPalette.allPresets {
            #expect(palette.startColor != palette.endColor,
                    "hue \(palette.hue) should have a gradient, not a flat color")
        }
    }

    /// Every palette must have a badgeText label.
    @Test
    func palette_allHaveBadgeText() {
        for palette in ReminderPalette.allPresets {
            #expect(!palette.badgeText.isEmpty,
                    "hue \(palette.hue) should have a badge text")
        }
    }

    /// Legacy enum strings should decode correctly.
    @Test
    func palette_legacyDecoding() throws {
        let json = Data(#""sky""#.utf8)
        let palette = try JSONDecoder().decode(ReminderPalette.self, from: json)
        #expect(abs(palette.hue - 0.58) < 0.001)
    }

    /// New hue values should round-trip correctly.
    @Test
    func palette_hueRoundTrip() throws {
        let original = ReminderPalette(hue: 0.42)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ReminderPalette.self, from: data)
        #expect(abs(decoded.hue - 0.42) < 0.001)
    }
}

// MARK: - Day Progress & Time-of-Day Tinting

@Suite("Day Progress")
struct DayProgressTests {

    /// dayProgress should return 0.0 at midnight, ~0.5 at noon, ~1.0 at 23:59.
    @Test
    func dayProgress_returnsCorrectFraction() {
        // Midnight
        let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: .now)!
        #expect(DayProgress.fraction(for: midnight) == 0.0)

        // Noon
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        let noonProgress = DayProgress.fraction(for: noon)
        #expect(noonProgress > 0.49 && noonProgress < 0.51, "Noon should be ~0.5, got \(noonProgress)")

        // 23:59
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 0, of: .now)!
        let endProgress = DayProgress.fraction(for: endOfDay)
        #expect(endProgress > 0.99, "23:59 should be >0.99, got \(endProgress)")
    }

    /// dayProgressPercent should return an integer percentage string.
    @Test
    func dayProgress_percentFormatting() {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        #expect(DayProgress.percent(for: noon) == 50)
    }

    private var calendar: Calendar { Calendar.current }
}

@Suite("Time-of-Day Tinting")
struct TimeOfDayTintTests {

    /// Morning (6-10) should return .morning tint.
    @Test
    func tint_morning() {
        let time = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        #expect(TimeOfDayTint.period(for: time) == .morning)
    }

    /// Midday (10-16) should return .midday tint (neutral).
    @Test
    func tint_midday() {
        let time = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: .now)!
        #expect(TimeOfDayTint.period(for: time) == .midday)
    }

    /// Evening (16-19) should return .evening tint.
    @Test
    func tint_evening() {
        let time = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: .now)!
        #expect(TimeOfDayTint.period(for: time) == .evening)
    }

    /// Night (19-6) should return .night tint.
    @Test
    func tint_night() {
        let time = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: .now)!
        #expect(TimeOfDayTint.period(for: time) == .night)

        let earlyMorning = calendar.date(bySettingHour: 4, minute: 0, second: 0, of: .now)!
        #expect(TimeOfDayTint.period(for: earlyMorning) == .night)
    }

    private var calendar: Calendar { Calendar.current }
}

// MARK: - Panel Size Mode

@Suite("Panel Size Mode")
struct PanelSizeModeTests {

    /// Should have exactly 2 size modes.
    @Test
    func hasTwoModes() {
        #expect(PanelSizeMode.allCases.count == 2)
    }

    /// Default should be .standard.
    @Test @MainActor
    func defaultIsStandard() {
        let store = ReminderStore(userDefaults: .ephemeral())
        #expect(store.panelSizeMode == .standard)
    }

    /// Should persist.
    @Test @MainActor
    func persists() {
        let defaults = UserDefaults.ephemeral()
        let store = ReminderStore(userDefaults: defaults)
        store.panelSizeMode = .compact

        let store2 = ReminderStore(userDefaults: defaults)
        #expect(store2.panelSizeMode == .compact)
    }
}

// MARK: - Animation Style

@Suite("Animation Style")
struct AnimationStyleTests {

    /// Should have exactly 3 animation options.
    @Test
    func hasThreeOptions() {
        #expect(PanelAnimationStyle.allCases.count == 3)
    }

    /// Default animation style should be .pulse (进度脉搏).
    @Test @MainActor
    func defaultIsPulse() {
        let store = ReminderStore(userDefaults: .ephemeral())
        #expect(store.panelAnimationStyle == .pulse)
    }

    /// Animation style should persist across store instances.
    @Test @MainActor
    func persists() {
        let defaults = UserDefaults.ephemeral()
        let store = ReminderStore(userDefaults: defaults)
        store.panelAnimationStyle = .particle

        let store2 = ReminderStore(userDefaults: defaults)
        #expect(store2.panelAnimationStyle == .particle)
    }

    /// Each style should have a display label.
    @Test
    func allHaveLabels() {
        for style in PanelAnimationStyle.allCases {
            #expect(!style.label.isEmpty)
        }
    }
}

// MARK: - Update Checker

@Suite("Update Checker")
struct UpdateCheckerTests {

    /// Should detect when a newer version is available.
    @Test
    func detectsNewerVersion() {
        #expect(UpdateChecker.isNewer("0.0.5", than: "0.0.4") == true)
        #expect(UpdateChecker.isNewer("0.1.0", than: "0.0.9") == true)
        #expect(UpdateChecker.isNewer("1.0.0", than: "0.9.9") == true)
    }

    /// Should not flag same or older versions.
    @Test
    func ignoresSameOrOlderVersion() {
        #expect(UpdateChecker.isNewer("0.0.4", than: "0.0.4") == false)
        #expect(UpdateChecker.isNewer("0.0.3", than: "0.0.4") == false)
    }

    /// Should parse GitHub release tag name to version string.
    @Test
    func parsesTagName() {
        #expect(UpdateChecker.versionFromTag("v0.0.5") == "0.0.5")
        #expect(UpdateChecker.versionFromTag("0.0.5") == "0.0.5")
    }
}

// MARK: - Helpers

extension UserDefaults {
    /// Creates an ephemeral UserDefaults that doesn't persist to disk.
    static func ephemeral() -> UserDefaults {
        let suiteName = "test.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        return defaults
    }
}
