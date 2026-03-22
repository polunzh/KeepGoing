#if os(macOS)
import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingPanelController: NSWindowController {
    static let shared = FloatingPanelController()

    private let store = ReminderStore.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {
        let controller = NSHostingController(rootView: FloatingReminderPanelView(store: ReminderStore.shared))

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 260),
            styleMask: [.titled, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentViewController = controller
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.setFrameOrigin(Self.defaultOrigin(for: panel))

        super.init(window: panel)

        store.$isFloatingPanelVisible
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncVisibility()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.repositionIfNeeded()
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func syncVisibility() {
        guard let panel = window else { return }

        if store.isFloatingPanelVisible {
            panel.orderFrontRegardless()
        } else {
            panel.orderOut(nil)
        }
    }

    func showEditor() {
        NSApp.activate(ignoringOtherApps: true)
    }

    private func repositionIfNeeded() {
        guard let panel = window else { return }
        let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let minX = visibleFrame.minX + 24
        let maxX = visibleFrame.maxX - panel.frame.width - 24
        let minY = visibleFrame.minY + 24
        let maxY = visibleFrame.maxY - panel.frame.height - 24

        let clampedOrigin = NSPoint(
            x: min(max(panel.frame.origin.x, minX), maxX),
            y: min(max(panel.frame.origin.y, minY), maxY)
        )

        panel.setFrameOrigin(clampedOrigin)
    }

    private static func defaultOrigin(for panel: NSPanel) -> NSPoint {
        let visibleFrame = panel.screen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        return NSPoint(
            x: visibleFrame.maxX - panel.frame.width - 28,
            y: visibleFrame.maxY - panel.frame.height - 44
        )
    }
}

struct FloatingReminderPanelView: View {
    @ObservedObject var store: ReminderStore

    var body: some View {
        ZStack {
            if let reminder = store.currentReminder {
                ReminderCardView(reminder: reminder, compact: true)
            } else {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            }

            VStack {
                HStack {
                    Spacer()

                    Button {
                        store.selectNextReminder()
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.body.weight(.bold))
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())

                    Button {
                        store.isFloatingPanelVisible = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.bold))
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
                }

                Spacer()
            }
            .padding(16)
        }
        .padding(10)
        .frame(width: 360, height: 260)
        .background(Color.clear)
    }
}

@MainActor
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FloatingPanelController.shared.syncVisibility()
    }
}
#endif
