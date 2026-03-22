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

    private struct PersistedState: Codable {
        var reminders: [Reminder]
        var selectedReminderID: Reminder.ID?
        var isFloatingPanelVisible: Bool
        var cycleInterval: Double
    }

    private let defaultsKey = "keepGoing.persisted.state"
    private let userDefaults: UserDefaults
    private var rotationTimer: Timer?

    private init(userDefaults: UserDefaults = .standard) {
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
                    message: "你不需要一下子追上时代，你只需要今天继续前进。",
                    palette: .sky
                ),
                Reminder(
                    title: "允许自己慢",
                    message: "允许自己慢，但不允许自己彻底停。先做 5 分钟也可以。",
                    palette: .leaf
                ),
                Reminder(
                    title: "用证据说话",
                    message: "只要你还在学、还在做、还在积累，你就没有出局。",
                    palette: .amber
                )
            ]

            initialState = PersistedState(
                reminders: defaultReminders,
                selectedReminderID: defaultReminders.first?.id,
                isFloatingPanelVisible: true,
                cycleInterval: 12
            )
        }

        reminders = initialState.reminders
        selectedReminderID = initialState.selectedReminderID
        isFloatingPanelVisible = initialState.isFloatingPanelVisible
        cycleInterval = initialState.cycleInterval

        stampSelection()
        restartTimer()
    }

    var currentReminder: Reminder? {
        if let selectedReminderID, let selected = reminders.first(where: { $0.id == selectedReminderID }) {
            return selected
        }

        return reminders.first(where: \.isEnabled) ?? reminders.first
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
            cycleInterval: cycleInterval
        )

        guard let data = try? JSONEncoder().encode(state) else { return }
        userDefaults.set(data, forKey: defaultsKey)
    }
}

struct ReminderBinding {
    let reminder: Reminder
    let onChange: (Reminder) -> Void
}
