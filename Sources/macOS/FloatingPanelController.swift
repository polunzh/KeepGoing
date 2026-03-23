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
        controller.view.wantsLayer = true
        controller.view.layer?.backgroundColor = .clear

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 130),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.contentViewController = controller
        panel.identifier = NSUserInterfaceItemIdentifier("floatingReminderPanel")
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

    private static let panelWidth: CGFloat = 280
    private static let panelHeight: CGFloat = 130

    private static func defaultOrigin(for panel: NSPanel) -> NSPoint {
        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero
        return NSPoint(
            x: visibleFrame.maxX - panelWidth - 24,
            y: visibleFrame.maxY - panelHeight - 24
        )
    }
}

// MARK: - Floating Panel View

struct FloatingReminderPanelView: View {
    @ObservedObject var store: ReminderStore
    @State private var isHovering = false
    @State private var currentTime = Date.now
    @State private var animationTick = false
    @State private var particlePhase: Double = 0

    private static let panelWidth: CGFloat = 280
    private static let panelHeight: CGFloat = 130

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if let reminder = store.floatingPanelReminder {
                panelContent(reminder: reminder)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .frame(width: Self.panelWidth, height: Self.panelHeight)
        .background(Color.clear)
        .onReceive(clockTimer) { time in
            currentTime = time
            particlePhase += 1
            withAnimation(.easeInOut(duration: 0.8)) {
                animationTick.toggle()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
    }

    private func panelContent(reminder: Reminder) -> some View {
        let progress = DayProgress.fraction(for: currentTime)

        return ZStack {
            // Full bright gradient as base
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [reminder.palette.startColor, reminder.palette.endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Dim overlay for the "remaining" portion — clips from the right,
            // respecting the same rounded rectangle shape
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: geo.size.width * (1 - progress))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Time-of-day tint overlay
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(TimeOfDayTint.tintColor(for: currentTime))

            // Animation overlay
            animationLayer(progress: progress)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                // Top row: time with seconds + day progress percentage
                HStack(alignment: .center) {
                    Text(currentTime, format: .dateTime.hour().minute().second())
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(isBreathGlowActive ? 1.0 : 0.5))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .shadow(color: .white.opacity(isBreathGlowActive ? 0.9 : 0), radius: isBreathGlowActive ? 12 : 0)
                        .shadow(color: .white.opacity(isBreathGlowActive ? 0.5 : 0), radius: isBreathGlowActive ? 20 : 0)
                        .scaleEffect(isBreathGlowActive ? 1.05 : 1.0)

                    Spacer()

                    if isHovering {
                        HStack(spacing: 6) {
                            Button {
                                store.selectNextReminder()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 22, height: 22)
                            .background(.white.opacity(0.18), in: Circle())
                            .accessibilityIdentifier("nextReminderButton")

                            Button {
                                store.isFloatingPanelVisible = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 22, height: 22)
                            .background(.white.opacity(0.18), in: Circle())
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    } else {
                        Text("今天已过 \(DayProgress.percent(for: currentTime))%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                            .contentTransition(.numericText())
                    }
                }

                Spacer().frame(height: 10)

                // Reminder title
                Text(reminder.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .accessibilityIdentifier("floatingPanelTitle")

                Spacer().frame(height: 4)

                // Reminder message
                Text(reminder.message)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(3)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 12)
        }
        .frame(width: Self.panelWidth, height: Self.panelHeight)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var isBreathGlowActive: Bool {
        animationTick && store.panelAnimationStyle == .breathGlow
    }

    @ViewBuilder
    private func animationLayer(progress: Double) -> some View {
        switch store.panelAnimationStyle {
        case .breathGlow:
            // Whole-card subtle brightness pulse
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(animationTick ? 0.08 : 0))
                .allowsHitTesting(false)

        case .pulse:
            // Pulsing glow at the progress boundary
            GeometryReader { geo in
                let x = geo.size.width * progress
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white.opacity(animationTick ? 0.35 : 0.05),
                                .clear,
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: geo.size.height)
                    .position(x: x, y: geo.size.height / 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)

        case .particle:
            // Multiple particles drifting down like hourglass sand
            GeometryReader { geo in
                let x = geo.size.width * progress
                ForEach(0..<6, id: \.self) { i in
                    let seed = Double(i)
                    // Each particle has a unique phase offset using sine waves
                    let phase = (particlePhase + seed * 1.7).truncatingRemainder(dividingBy: 6.0)
                    let normalizedPhase = phase / 6.0
                    // Vertical: falls from top to bottom
                    let y = geo.size.height * normalizedPhase
                    // Horizontal: slight sine drift around the boundary
                    let drift = sin((particlePhase + seed * 2.3) * 0.8) * 12
                    let size = 2.5 + sin(seed * 1.3) * 1.5
                    // Fade in at top, fade out at bottom
                    let fadeProgress = normalizedPhase
                    let opacity = fadeProgress < 0.15
                        ? fadeProgress / 0.15
                        : fadeProgress > 0.85 ? (1 - fadeProgress) / 0.15 : 1.0

                    Circle()
                        .fill(.white.opacity(0.8 * opacity))
                        .frame(width: size, height: size)
                        .shadow(color: .white.opacity(0.6 * opacity), radius: 4)
                        .position(x: x + drift, y: y)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)
        }
    }
}

@MainActor
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        FloatingPanelController.shared.syncVisibility()

        Task {
            if let update = await UpdateChecker.checkForUpdate() {
                showUpdateAlert(version: update.version, url: update.url)
            }
        }
    }

    private func showUpdateAlert(version: String, url: URL) {
        let alert = NSAlert()
        alert.messageText = "新版本可用"
        alert.informativeText = "KeepGoing v\(version) 已发布，是否前往下载？"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "前往下载")
        alert.addButton(withTitle: "稍后再说")

        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(url)
        }
    }
}
#endif
