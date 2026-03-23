import SwiftUI

struct ReminderWorkspaceView: View {
    @ObservedObject var store: ReminderStore
    @State private var selection: Reminder.ID?

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } detail: {
            detail
        }
        .onAppear {
            selection = store.selectedReminderID
        }
        .onChange(of: selection) { _, newValue in
            if let newValue {
                store.selectReminder(id: newValue)
            }
        }
        .onChange(of: store.selectedReminderID) { _, newValue in
            selection = newValue
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selection) {
            Section {
                ForEach(store.reminders) { reminder in
                    ReminderRow(reminder: reminder)
                        .tag(reminder.id)
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        store.deleteReminder(id: store.reminders[index].id)
                    }
                }
            }

            Section {
                Button(action: store.addReminder) {
                    Label("添加提醒", systemImage: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }

            Section("轮播间隔") {
                CycleIntervalPicker(interval: $store.cycleInterval)

                #if os(macOS)
                AnimationStylePicker(style: $store.panelAnimationStyle)

                Button {
                    store.isFloatingPanelVisible.toggle()
                    FloatingPanelController.shared.syncVisibility()
                } label: {
                    Label(
                        store.isFloatingPanelVisible ? "隐藏悬浮窗" : "显示悬浮窗",
                        systemImage: store.isFloatingPanelVisible ? "eye.slash" : "eye"
                    )
                }
                #endif
            }
        }
        .navigationTitle("KeepGoing")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: store.addReminder) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let selectedID = selection,
           let binding = store.binding(for: selectedID) {
            ScrollView {
                VStack(spacing: 24) {
                    ReminderCardView(reminder: binding.reminder)
                        .padding(.horizontal)

                    ReminderDetailForm(binding: binding) {
                        store.deleteReminder(id: selectedID)
                    }
                    .id(selectedID)
                }
                .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("detailScrollView")
        } else {
            ContentUnavailableView(
                "选择一条提醒",
                systemImage: "hand.tap",
                description: Text("在左侧列表中选择一条提醒来查看和编辑。")
            )
        }
    }
}

// MARK: - Cycle Interval Picker

private struct CycleIntervalPicker: View {
    @Binding var interval: Double

    private static let presets: [(String, Double)] = [
        ("30 秒", 30),
        ("5 分钟", 300),
        ("25 分钟", 1500),
        ("1 小时", 3600),
        ("每天", 86400),
    ]

    private var currentLabel: String {
        Self.presets.first { $0.1 == interval }?.0 ?? formatCustom(interval)
    }

    var body: some View {
        Menu {
            ForEach(Self.presets, id: \.1) { label, value in
                Button {
                    interval = value
                } label: {
                    if interval == value {
                        Label(label, systemImage: "checkmark")
                    } else {
                        Text(label)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currentLabel)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func formatCustom(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) 分钟"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours) 小时"
        }
        return "\(hours) 小时 \(remainingMinutes) 分"
    }
}

// MARK: - Animation Style Picker

private struct AnimationStylePicker: View {
    @Binding var style: PanelAnimationStyle

    var body: some View {
        Menu {
            ForEach(PanelAnimationStyle.allCases) { option in
                Button {
                    style = option
                } label: {
                    if style == option {
                        Label(option.label, systemImage: "checkmark")
                    } else {
                        Text(option.label)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(style.label)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
            }
            .font(.subheadline)
            .foregroundStyle(.primary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Sidebar Row

private struct ReminderRow: View {
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [reminder.palette.startColor, reminder.palette.endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 12, height: 12)

            Text(reminder.title)
                .lineLimit(1)

            Spacer()

            if !reminder.isEnabled {
                Image(systemName: "eye.slash")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ReminderWorkspaceView(store: ReminderStore.shared)
}
