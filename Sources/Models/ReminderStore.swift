import Combine
import Foundation

@MainActor
final class ReminderStore: ObservableObject {
    static let shared = ReminderStore()

    @Published var reminders: [Reminder] {
        didSet {
            stampSelection()
            saveState()
        }
    }

    @Published var selectedReminderID: Reminder.ID? {
        didSet {
            stampSelection()
            saveState()
        }
    }

    @Published var isFloatingPanelVisible: Bool {
        didSet { saveState() }
    }

    @Published var cycleInterval: Double {
        didSet {
            restartTimer()
            saveState()
        }
    }

    @Published var panelAnimationStyle: PanelAnimationStyle {
        didSet { saveState() }
    }

    @Published var panelSizeMode: PanelSizeMode {
        didSet { saveState() }
    }

    private struct PersistedState: Codable {
        var reminders: [Reminder]
        var selectedReminderID: Reminder.ID?
        var isFloatingPanelVisible: Bool
        var cycleInterval: Double
        var panelAnimationStyle: PanelAnimationStyle?
        var panelSizeMode: PanelSizeMode?
    }

    private let defaultsKey = "keepGoing.persisted.state"
    private let userDefaults: UserDefaults
    private var rotationTimer: Timer?

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        let initialState: PersistedState

        if
            let data = userDefaults.data(forKey: defaultsKey),
            let state = try? JSONDecoder().decode(PersistedState.self, from: data)
        {
            initialState = state
        } else {
            let defaultReminders = [
                Reminder(
                    title: "先开始就算赢",
                    message: "只做 5 分钟也可以。先开始，比做好更重要。",
                    palette: .amber
                ),
                Reminder(
                    title: "情绪不是结论",
                    message: "我感到绝望，只说明我现在压力很大，不说明我真的没有未来。",
                    palette: .sky
                ),
                Reminder(
                    title: "允许自己慢",
                    message: "允许自己慢，但不允许自己彻底停。先做 5 分钟也可以。",
                    palette: .leaf
                ),
                Reminder(
                    title: "我没有出局",
                    message: "只要我还在学、还在做、还在积累，我就没有出局。",
                    palette: .amber
                ),
                Reminder(
                    title: "今天只做一件小事",
                    message: "小步不是没用，小步是在恢复掌控感。",
                    palette: .leaf
                ),
                Reminder(
                    title: "先不要把自己耗坏",
                    message: "先保护基本秩序：吃饭、睡觉、出门、做一点事。能守住这些，不是没出息，而是在保命。",
                    palette: .rose
                ),
                Reminder(
                    title: "休息不是投降",
                    message: "真正的休息应该让我更能呼吸、更能清醒，而不是让我陷入更深的麻木。",
                    palette: .rose
                ),
                Reminder(
                    title: "穿过这段黑路",
                    message: "穿过去，靠的不是瞬间爆发，而是不停下。",
                    palette: .slate
                ),
            ]

            initialState = PersistedState(
                reminders: defaultReminders,
                selectedReminderID: defaultReminders.first?.id,
                isFloatingPanelVisible: true,
                cycleInterval: 86400
            )
        }

        reminders = initialState.reminders
        selectedReminderID = initialState.selectedReminderID
        isFloatingPanelVisible = initialState.isFloatingPanelVisible
        cycleInterval = initialState.cycleInterval
        panelAnimationStyle = initialState.panelAnimationStyle ?? .pulse
        panelSizeMode = initialState.panelSizeMode ?? .standard

        stampSelection()
        restartTimer()
    }

    var currentReminder: Reminder? {
        if let selectedReminderID, let selected = reminders.first(where: { $0.id == selectedReminderID }) {
            return selected
        }

        return reminders.first(where: \.isEnabled) ?? reminders.first
    }

    /// The reminder to display in the floating panel — follows selection, changes on selectNextReminder().
    var floatingPanelReminder: Reminder? {
        currentReminder
    }

    var dailyReminder: Reminder? {
        let enabled = reminders.filter(\.isEnabled)
        let source = enabled.isEmpty ? reminders : enabled
        guard !source.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 0
        return source[dayOfYear % source.count]
    }

    func addReminder() {
        let reminder = Reminder(
            title: "新的提醒",
            message: "现在先做一件 25 分钟内可以完成的小事。",
            palette: .rose
        )
        reminders.append(reminder)
        selectedReminderID = reminder.id
    }

    func deleteReminder(id: Reminder.ID) {
        reminders.removeAll { $0.id == id }

        if reminders.isEmpty {
            addReminder()
            return
        }

        if currentReminder == nil {
            selectedReminderID = reminders.first?.id
        }
    }

    func selectReminder(id: Reminder.ID) {
        selectedReminderID = id
    }

    func selectNextReminder() {
        let candidates = reminders.filter(\.isEnabled)
        let source = candidates.isEmpty ? reminders : candidates

        guard !source.isEmpty else { return }

        guard let selectedReminderID, let currentIndex = source.firstIndex(where: { $0.id == selectedReminderID }) else {
            self.selectedReminderID = source.first?.id
            return
        }

        let nextIndex = source.index(after: currentIndex)
        self.selectedReminderID = source[nextIndex == source.endIndex ? source.startIndex : nextIndex].id
    }

    func updateReminder(_ reminder: Reminder) {
        guard let index = reminders.firstIndex(where: { $0.id == reminder.id }) else { return }

        var updatedReminder = reminder
        updatedReminder.updatedAt = .now
        reminders[index] = updatedReminder
    }

    func binding(for id: Reminder.ID) -> ReminderBinding? {
        guard let index = reminders.firstIndex(where: { $0.id == id }) else { return nil }

        return ReminderBinding(
            reminder: reminders[index],
            onChange: { [weak self] updated in
                self?.updateReminder(updated)
            }
        )
    }

    private func restartTimer() {
        rotationTimer?.invalidate()

        let interval = max(cycleInterval, 5)
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.selectNextReminder()
            }
        }

        rotationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stampSelection() {
        guard !reminders.isEmpty else {
            selectedReminderID = nil
            return
        }

        if let selectedReminderID, reminders.contains(where: { $0.id == selectedReminderID }) {
            return
        }

        selectedReminderID = reminders.first(where: \.isEnabled)?.id ?? reminders.first?.id
    }

    private func saveState() {
        let state = PersistedState(
            reminders: reminders,
            selectedReminderID: selectedReminderID,
            isFloatingPanelVisible: isFloatingPanelVisible,
            cycleInterval: cycleInterval,
            panelAnimationStyle: panelAnimationStyle,
            panelSizeMode: panelSizeMode
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(data, forKey: defaultsKey)
    }
}

struct ReminderBinding {
    let reminder: Reminder
    let onChange: (Reminder) -> Void
}
