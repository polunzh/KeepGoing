import SwiftUI

struct ReminderWorkspaceView: View {
    @ObservedObject var store: ReminderStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    controls
                    reminderList
                    detailPanel
                }
                .padding(24)
            }
            .navigationTitle("KeepGoing")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("把一句能拉住你的话，挂在桌面上。")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("macOS 会显示一个可置顶的悬浮提醒窗；iPhone 上也可以同步编辑同一份本地提醒内容。第一版先专注恢复行动感。")
                .font(.title3)
                .foregroundStyle(.secondary)

            if let currentReminder = store.currentReminder {
                ReminderCardView(reminder: currentReminder)
            }
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button(action: store.addReminder) {
                    Label("新增提醒", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)

                Button(action: store.selectNextReminder) {
                    Label("切换下一条", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)

                #if os(macOS)
                Button(action: toggleFloatingPanel) {
                    Label(
                        store.isFloatingPanelVisible ? "隐藏悬浮窗" : "显示悬浮窗",
                        systemImage: store.isFloatingPanelVisible ? "pin.slash" : "pin"
                    )
                }
                .buttonStyle(.bordered)
                #endif

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("轮播间隔")
                    Spacer()
                    Text("\(Int(store.cycleInterval)) 秒")
                        .foregroundStyle(.secondary)
                }

                Slider(value: $store.cycleInterval, in: 5...60, step: 1)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }

    private var reminderList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("提醒列表")
                .font(.title2.weight(.bold))

            LazyVGrid(columns: adaptiveColumns, spacing: 16) {
                ForEach(store.reminders) { reminder in
                    Button {
                        store.selectReminder(id: reminder.id)
                    } label: {
                        VStack(alignment: .leading, spacing: 10) {
                            ReminderCardView(reminder: reminder, compact: true)

                            HStack {
                                Text(reminder.title)
                                    .font(.headline)
                                    .lineLimit(1)

                                Spacer()

                                if store.selectedReminderID == reminder.id {
                                    Text("当前")
                                        .font(.caption.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.12), in: Capsule())
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var detailPanel: some View {
        if let selectedReminderID = store.selectedReminderID, let binding = store.binding(for: selectedReminderID) {
            ReminderDetailForm(binding: binding) {
                store.deleteReminder(id: selectedReminderID)
            }
            .id(selectedReminderID)
        } else {
            ContentUnavailableView(
                "还没有可编辑的提醒",
                systemImage: "note.text.badge.plus",
                description: Text("先创建一条提醒。")
            )
        }
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 280, maximum: 380), spacing: 16)]
    }

    #if os(macOS)
    private func toggleFloatingPanel() {
        store.isFloatingPanelVisible.toggle()
        FloatingPanelController.shared.syncVisibility()
    }
    #endif
}

#Preview {
    ReminderWorkspaceView(store: ReminderStore.shared)
}
