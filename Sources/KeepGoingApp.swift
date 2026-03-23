import SwiftUI

@main
struct KeepGoingApp: App {
    @StateObject private var store = ReminderStore.shared

    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    #endif

    var body: some Scene {
        WindowGroup(id: "editor") {
            ReminderWorkspaceView(store: store)
        }
        .defaultSize(width: 780, height: 600)

        #if os(macOS)
        MenuBarExtra("KeepGoing", systemImage: "sun.max.circle.fill") {
            MacMenuBarView(store: store)
        }
        #endif
    }
}

#if os(macOS)
private struct MacMenuBarView: View {
    @ObservedObject var store: ReminderStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let reminder = store.currentReminder {
                Text(reminder.title)
                    .font(.headline)

                Text(reminder.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button(store.isFloatingPanelVisible ? "隐藏悬浮窗" : "显示悬浮窗") {
                store.isFloatingPanelVisible.toggle()
                FloatingPanelController.shared.syncVisibility()
            }

            Button("切换下一条提醒") {
                store.selectNextReminder()
            }

            Button("打开编辑窗口") {
                openWindow(id: "editor")
                FloatingPanelController.shared.showEditor()
            }

            Divider()

            Button("退出 KeepGoing") {
                NSApp.terminate(nil)
            }
        }
        .frame(width: 260)
        .padding(10)
    }
}
#endif
