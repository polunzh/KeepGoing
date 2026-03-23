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

        store.$panelSizeMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncPanelSize()
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

    private func syncPanelSize() {
        guard let panel = window else { return }
        let size = Self.panelSize(for: store.panelSizeMode)
        let origin = panel.frame.origin
        panel.setFrame(NSRect(x: origin.x, y: origin.y, width: size.width, height: size.height), display: true, animate: true)
    }

    static func panelSize(for mode: PanelSizeMode) -> NSSize {
        switch mode {
        case .standard: NSSize(width: 280, height: 130)
        case .compact: NSSize(width: 320, height: 50)
        }
    }

    private static func defaultOrigin(for panel: NSPanel) -> NSPoint {
        let visibleFrame = NSScreen.main?.visibleFrame ?? .zero
        let size = panelSize(for: .standard)
        return NSPoint(
            x: visibleFrame.maxX - size.width - 24,
            y: visibleFrame.maxY - size.height - 24
        )
    }
}

// MARK: - Floating Panel View

struct FloatingReminderPanelView: View {
    @ObservedObject var store: ReminderStore
    @State private var isHovering = false
    @State private var currentTime = Date.now
    @State private var animationTick = false

    private let clockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var panelSize: NSSize {
        FloatingPanelController.panelSize(for: store.panelSizeMode)
    }

    private var isCompact: Bool { store.panelSizeMode == .compact }

    var body: some View {
        Group {
            if let reminder = store.floatingPanelReminder {
                if isCompact {
                    compactContent(reminder: reminder)
                } else {
                    panelContent(reminder: reminder)
                }
            } else {
                RoundedRectangle(cornerRadius: isCompact ? 12 : 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
        .frame(width: panelSize.width, height: panelSize.height)
        .background(Color.clear)
        .onReceive(clockTimer) { time in
            currentTime = time
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

    private func compactContent(reminder: Reminder) -> some View {
        let progress = DayProgress.fraction(for: currentTime)
        let maxW: CGFloat = 320

        return ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [reminder.palette.startColor, reminder.palette.endColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            GeometryReader { geo in
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: geo.size.width * (1 - progress))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(TimeOfDayTint.tintColor(for: currentTime))

            animationLayer(progress: progress)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(currentTime, format: .dateTime.hour().minute().second())
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(isBreathGlowActive ? 1.0 : 0.5))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .shadow(color: .white.opacity(isBreathGlowActive ? 0.9 : 0), radius: isBreathGlowActive ? 8 : 0)

                    Text("·")
                        .foregroundStyle(.white.opacity(0.4))

                    Text(reminder.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .accessibilityIdentifier("floatingPanelTitle")

                    Spacer(minLength: 0)

                    if isHovering {
                        HStack(spacing: 4) {
                            Button {
                                store.selectNextReminder()
                            } label: {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 18, height: 18)
                            .background(.white.opacity(0.18), in: Circle())
                            .accessibilityIdentifier("nextReminderButton")

                            Button {
                                store.isFloatingPanelVisible = false
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            .frame(width: 18, height: 18)
                            .background(.white.opacity(0.18), in: Circle())
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(maxWidth: maxW)
        .fixedSize(horizontal: true, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .frame(width: panelSize.width, height: panelSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var isBreathGlowActive: Bool {
        animationTick && store.panelAnimationStyle == .breathGlow
    }

    @ViewBuilder
    private func animationLayer(progress: Double) -> some View {
        switch store.panelAnimationStyle {
        case .breathGlow:
            // Heart shape that pulses like a heartbeat
            GeometryReader { geo in
                HeartShape()
                    .fill(.white.opacity(animationTick ? 0.15 : 0.03))
                    .shadow(color: .white.opacity(animationTick ? 0.4 : 0), radius: animationTick ? 16 : 0)
                    .frame(width: 50, height: 45)
                    .scaleEffect(animationTick ? 1.15 : 0.9)
                    .position(x: geo.size.width - 30, y: geo.size.height - 25)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            // Smooth 60fps particles drifting down like hourglass sand
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                GeometryReader { geo in
                    let x = geo.size.width * progress
                    ForEach(0..<7, id: \.self) { i in
                        let seed = Double(i)
                        // Each particle loops over its own period (3-5 seconds)
                        let period = 3.0 + seed * 0.3
                        let phase = (t / period + seed * 0.37).truncatingRemainder(dividingBy: 1.0)
                        // Vertical: smooth fall from top to bottom
                        let y = geo.size.height * phase
                        // Horizontal: gentle sine drift
                        let drift = sin(t * 0.7 + seed * 2.1) * 14
                        let size = 2.0 + sin(seed * 1.7) * 1.5
                        // Fade in/out at edges
                        let opacity = phase < 0.1
                            ? phase / 0.1
                            : phase > 0.85 ? (1 - phase) / 0.15 : 1.0

                        Circle()
                            .fill(.white.opacity(0.75 * opacity))
                            .frame(width: size, height: size)
                            .shadow(color: .white.opacity(0.5 * opacity), radius: 5)
                            .position(x: x + drift, y: y)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Heart Shape

private struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.size.width
        let h = rect.size.height

        path.move(to: CGPoint(x: 0.49616*w, y: 0.89542*h))
        path.addCurve(to: CGPoint(x: 0.48666*w, y: 0.8901*h), control1: CGPoint(x: 0.49477*w, y: 0.89542*h), control2: CGPoint(x: 0.4916*w, y: 0.89365*h))
        path.addCurve(to: CGPoint(x: 0.33791*w, y: 0.769*h), control1: CGPoint(x: 0.43473*w, y: 0.85308*h), control2: CGPoint(x: 0.38515*w, y: 0.81271*h))
        path.addCurve(to: CGPoint(x: 0.21169*w, y: 0.63198*h), control1: CGPoint(x: 0.29067*w, y: 0.72529*h), control2: CGPoint(x: 0.2486*w, y: 0.67961*h))
        path.addCurve(to: CGPoint(x: 0.12417*w, y: 0.48678*h), control1: CGPoint(x: 0.17478*w, y: 0.58434*h), control2: CGPoint(x: 0.14561*w, y: 0.53594*h))
        path.addCurve(to: CGPoint(x: 0.09202*w, y: 0.3411*h), control1: CGPoint(x: 0.10274*w, y: 0.43762*h), control2: CGPoint(x: 0.09202*w, y: 0.38906*h))
        path.addCurve(to: CGPoint(x: 0.11764*w, y: 0.22099*h), control1: CGPoint(x: 0.09202*w, y: 0.29531*h), control2: CGPoint(x: 0.10056*w, y: 0.25527*h))
        path.addCurve(to: CGPoint(x: 0.18729*w, y: 0.14084*h), control1: CGPoint(x: 0.13472*w, y: 0.18672*h), control2: CGPoint(x: 0.15793*w, y: 0.16*h))
        path.addCurve(to: CGPoint(x: 0.28757*w, y: 0.1121*h), control1: CGPoint(x: 0.21665*w, y: 0.12168*h), control2: CGPoint(x: 0.25008*w, y: 0.1121*h))
        path.addCurve(to: CGPoint(x: 0.36607*w, y: 0.12915*h), control1: CGPoint(x: 0.31787*w, y: 0.1121*h), control2: CGPoint(x: 0.34403*w, y: 0.11778*h))
        path.addCurve(to: CGPoint(x: 0.42233*w, y: 0.17195*h), control1: CGPoint(x: 0.38811*w, y: 0.14052*h), control2: CGPoint(x: 0.40686*w, y: 0.15478*h))
        path.addCurve(to: CGPoint(x: 0.46149*w, y: 0.22335*h), control1: CGPoint(x: 0.43779*w, y: 0.18912*h), control2: CGPoint(x: 0.45085*w, y: 0.20626*h))
        path.addCurve(to: CGPoint(x: 0.47917*w, y: 0.24549*h), control1: CGPoint(x: 0.46816*w, y: 0.2342*h), control2: CGPoint(x: 0.47405*w, y: 0.24158*h))
        path.addCurve(to: CGPoint(x: 0.49616*w, y: 0.25135*h), control1: CGPoint(x: 0.48429*w, y: 0.2494*h), control2: CGPoint(x: 0.48995*w, y: 0.25135*h))
        path.addCurve(to: CGPoint(x: 0.5129*w, y: 0.24524*h), control1: CGPoint(x: 0.5024*w, y: 0.25135*h), control2: CGPoint(x: 0.50798*w, y: 0.24931*h))
        path.addCurve(to: CGPoint(x: 0.53079*w, y: 0.22335*h), control1: CGPoint(x: 0.51781*w, y: 0.24116*h), control2: CGPoint(x: 0.52377*w, y: 0.23387*h))
        path.addCurve(to: CGPoint(x: 0.57099*w, y: 0.1724*h), control1: CGPoint(x: 0.54212*w, y: 0.20656*h), control2: CGPoint(x: 0.55552*w, y: 0.18958*h))
        path.addCurve(to: CGPoint(x: 0.62677*w, y: 0.12937*h), control1: CGPoint(x: 0.58645*w, y: 0.15523*h), control2: CGPoint(x: 0.60504*w, y: 0.14089*h))
        path.addCurve(to: CGPoint(x: 0.70475*w, y: 0.1121*h), control1: CGPoint(x: 0.6485*w, y: 0.11786*h), control2: CGPoint(x: 0.67449*w, y: 0.1121*h))
        path.addCurve(to: CGPoint(x: 0.8053*w, y: 0.14084*h), control1: CGPoint(x: 0.74225*w, y: 0.1121*h), control2: CGPoint(x: 0.77576*w, y: 0.12168*h))
        path.addCurve(to: CGPoint(x: 0.87497*w, y: 0.22099*h), control1: CGPoint(x: 0.83483*w, y: 0.16*h), control2: CGPoint(x: 0.85805*w, y: 0.18672*h))
        path.addCurve(to: CGPoint(x: 0.90035*w, y: 0.3411*h), control1: CGPoint(x: 0.89189*w, y: 0.25527*h), control2: CGPoint(x: 0.90035*w, y: 0.29531*h))
        path.addCurve(to: CGPoint(x: 0.8682*w, y: 0.48678*h), control1: CGPoint(x: 0.90035*w, y: 0.38906*h), control2: CGPoint(x: 0.88964*w, y: 0.43762*h))
        path.addCurve(to: CGPoint(x: 0.78066*w, y: 0.63198*h), control1: CGPoint(x: 0.84676*w, y: 0.53594*h), control2: CGPoint(x: 0.81758*w, y: 0.58434*h))
        path.addCurve(to: CGPoint(x: 0.65442*w, y: 0.769*h), control1: CGPoint(x: 0.74374*w, y: 0.67961*h), control2: CGPoint(x: 0.70165*w, y: 0.72529*h))
        path.addCurve(to: CGPoint(x: 0.50567*w, y: 0.8901*h), control1: CGPoint(x: 0.60718*w, y: 0.81271*h), control2: CGPoint(x: 0.55759*w, y: 0.85308*h))
        path.addCurve(to: CGPoint(x: 0.49616*w, y: 0.89542*h), control1: CGPoint(x: 0.50072*w, y: 0.89365*h), control2: CGPoint(x: 0.49755*w, y: 0.89542*h))
        path.closeSubpath()

        return path
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
