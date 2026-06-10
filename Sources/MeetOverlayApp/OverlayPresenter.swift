import AppKit
import MeetOverlayCore
import SwiftUI

@MainActor
final class OverlayPresenter {
    private var windows: [NSWindow] = []
    private let reminderSoundPlayer = ReminderSoundPlayer()

    func show(
        meeting: JoinableMeeting,
        reminderSound: ReminderSound,
        onJoin: @escaping () -> Void,
        onSnooze: @escaping (TimeInterval) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        hide()
        reminderSoundPlayer.play(reminderSound)

        present(
            MeetingOverlayView(
                meeting: meeting,
                onJoin: onJoin,
                onSnooze: onSnooze,
                onDismiss: onDismiss
            ),
            onDismiss: onDismiss
        )
    }

    func showAirlock(
        transition: BackToBackTransition,
        onJoin: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        hide()
        present(
            BackToBackAirlockView(
                transition: transition,
                onJoin: onJoin,
                onDismiss: onDismiss
            ),
            onDismiss: onDismiss
        )
    }

    func hide() {
        windows.forEach { $0.close() }
        windows.removeAll()
    }

    private func present<Content: View>(_ contentView: Content, onDismiss: @escaping () -> Void) {
        let activeScreen = NSScreen.main ?? NSScreen.screens.first

        for screen in NSScreen.screens {
            let window = OverlayWindow(
                contentRect: screen.frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )

            window.onDismiss = onDismiss
            window.level = .screenSaver
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            window.backgroundColor = .clear
            window.isOpaque = false
            window.isReleasedWhenClosed = false

            if screen == activeScreen {
                window.contentView = NSHostingView(rootView: contentView)
                window.makeKeyAndOrderFront(nil)
            } else {
                window.contentView = NSHostingView(rootView: SecondaryScreenScrimView())
            }

            window.orderFrontRegardless()
            windows.append(window)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

}

private struct SecondaryScreenScrimView: View {
    var body: some View {
        MeetOverlayTheme.Palette.overlayScrim.ignoresSafeArea()
    }
}

@MainActor
private final class OverlayWindow: NSWindow {
    var onDismiss: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onDismiss?()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onDismiss?()
            return
        }

        super.keyDown(with: event)
    }
}

private enum OverlayStyle {
    static let primaryHoverHighlight = Color.white.opacity(0.16)
    static let primaryPressedShade = Color.black.opacity(0.1)
    static let secondaryHoverFill = Color.white.opacity(0.13)
    static let secondaryPressedFill = Color.white.opacity(0.05)
    static let secondaryHoverBorder = Color.white.opacity(0.24)
    static let keycapFill = Color.white.opacity(0.09)
    static let keycapBorder = Color.white.opacity(0.16)
    static let keycapOnAccentFill = Color.black.opacity(0.1)
    static let keycapOnAccentText = Color.black.opacity(0.62)
    static let keycapFont = Font.system(size: 12, weight: .semibold)
    static let compactButtonFont = MeetOverlayTheme.Typography.overlayHint.weight(.semibold)
    static let panelEntranceScale: CGFloat = 0.97
    static let panelEntranceDuration: TimeInterval = 0.18
}

private struct OverlayPrimaryButtonStyle: ButtonStyle {
    var minWidth: CGFloat = 172

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration, minWidth: minWidth)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        let minWidth: CGFloat

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .font(MeetOverlayTheme.Typography.overlayButton.weight(.bold))
                .foregroundStyle(.black)
                .padding(.horizontal, 38)
                .padding(.vertical, 17)
                .frame(minWidth: minWidth)
                .background(
                    Capsule()
                        .fill(MeetOverlayTheme.Palette.accent)
                        .overlay(Capsule().fill(highlight))
                )
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
                .animation(.easeOut(duration: 0.12), value: isHovered)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
                .onHover { isHovered = $0 }
        }

        private var highlight: Color {
            if configuration.isPressed {
                return OverlayStyle.primaryPressedShade
            }

            return isHovered ? OverlayStyle.primaryHoverHighlight : .clear
        }
    }
}

private struct OverlaySecondaryButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        StyledLabel(configuration: configuration, compact: compact)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        let compact: Bool

        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        @State private var isHovered = false

        var body: some View {
            configuration.label
                .font(compact ? OverlayStyle.compactButtonFont : MeetOverlayTheme.Typography.overlaySecondaryButton)
                .foregroundStyle(
                    isHovered
                        ? MeetOverlayTheme.Palette.overlayText
                        : MeetOverlayTheme.Palette.overlaySecondaryText
                )
                .padding(.horizontal, compact ? 14 : 20)
                .padding(.vertical, compact ? 7 : 14)
                .frame(minWidth: compact ? 0 : 112)
                .background(Capsule().fill(fill))
                .overlay(
                    Capsule()
                        .stroke(
                            isHovered ? OverlayStyle.secondaryHoverBorder : MeetOverlayTheme.Palette.overlayPanelBorder,
                            lineWidth: 1
                        )
                )
                .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
                .animation(.easeOut(duration: 0.12), value: isHovered)
                .animation(.easeOut(duration: 0.08), value: configuration.isPressed)
                .onHover { isHovered = $0 }
        }

        private var fill: Color {
            if configuration.isPressed {
                return OverlayStyle.secondaryPressedFill
            }

            return isHovered ? OverlayStyle.secondaryHoverFill : MeetOverlayTheme.Palette.overlayPanel
        }
    }
}

private struct KeycapHint: View {
    enum Tone {
        case onPanel
        case onAccent
    }

    let symbol: String
    var tone: Tone = .onPanel

    var body: some View {
        Text(symbol)
            .font(OverlayStyle.keycapFont)
            .foregroundStyle(
                tone == .onAccent
                    ? OverlayStyle.keycapOnAccentText
                    : MeetOverlayTheme.Palette.overlayTertiaryText
            )
            .padding(.horizontal, 5)
            .frame(minWidth: 20, minHeight: 20)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(tone == .onAccent ? OverlayStyle.keycapOnAccentFill : OverlayStyle.keycapFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(tone == .onAccent ? Color.clear : OverlayStyle.keycapBorder, lineWidth: 1)
            )
            .accessibilityHidden(true)
    }
}

private struct OverlayBackdropView: View {
    var body: some View {
        LinearGradient(
            colors: [MeetOverlayTheme.Palette.overlayStart, MeetOverlayTheme.Palette.overlayEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

private struct OverlayPanelModifier: ViewModifier {
    let maxWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasEntered = false

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, MeetOverlayTheme.Spacing.overlayPanelHorizontal)
            .padding(.vertical, MeetOverlayTheme.Spacing.overlayPanelVertical)
            .frame(maxWidth: maxWidth)
            .background(
                RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.overlayPanel)
                    .fill(MeetOverlayTheme.Palette.overlayPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.overlayPanel)
                    .stroke(MeetOverlayTheme.Palette.overlayPanelBorder, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.28), radius: 30, y: 18)
            .padding(48)
            .opacity(hasEntered ? 1 : 0)
            .scaleEffect(hasEntered || reduceMotion ? 1 : OverlayStyle.panelEntranceScale)
            .onAppear {
                withAnimation(.easeOut(duration: OverlayStyle.panelEntranceDuration)) {
                    hasEntered = true
                }
            }
    }
}

extension View {
    fileprivate func overlayPanel(maxWidth: CGFloat) -> some View {
        modifier(OverlayPanelModifier(maxWidth: maxWidth))
    }
}

private func meetingTimeRangeText(from startDate: Date, to endDate: Date) -> String {
    "\(startDate.formatted(date: .omitted, time: .shortened)) to \(endDate.formatted(date: .omitted, time: .shortened))"
}

private struct MeetingOverlayView: View {
    let meeting: JoinableMeeting
    let onJoin: () -> Void
    let onSnooze: (TimeInterval) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            OverlayBackdropView()

            VStack(spacing: MeetOverlayTheme.Spacing.overlayContent) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 12) {
                        Text(MeetingCountdownFormatter.text(now: context.date, startDate: meeting.startDate))
                            .font(MeetOverlayTheme.Typography.overlayStatus)
                            .monospacedDigit()
                            .foregroundStyle(
                                context.date >= meeting.startDate
                                    ? MeetOverlayTheme.Palette.attention
                                    : MeetOverlayTheme.Palette.accent
                            )

                        Text(meeting.title)
                            .font(MeetOverlayTheme.Typography.overlayTitle)
                            .foregroundStyle(MeetOverlayTheme.Palette.overlayText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)

                        Label(
                            meetingTimeRangeText(from: meeting.startDate, to: meeting.endDate),
                            systemImage: "clock"
                        )
                        .font(MeetOverlayTheme.Typography.overlayMetadata)
                        .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: onJoin) {
                        HStack(spacing: 10) {
                            Text(meeting.meetLinks.count > 1 ? "Join First Room" : "Join Room")
                            KeycapHint(symbol: "⏎", tone: .onAccent)
                        }
                    }
                    .buttonStyle(OverlayPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)

                    secondaryButton("Snooze 1m", keycap: "1", key: "1") {
                        onSnooze(60)
                    }

                    secondaryButton("Snooze 5m", keycap: "5", key: "5") {
                        onSnooze(5 * 60)
                    }

                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Text("Dismiss")
                            KeycapHint(symbol: "esc")
                        }
                    }
                    .buttonStyle(OverlaySecondaryButtonStyle())
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.top, 4)

                if meeting.meetLinks.count > 1 {
                    MeetLinkRescueView(links: meeting.meetLinks)
                }
            }
            .overlayPanel(maxWidth: 840)
        }
        .tint(MeetOverlayTheme.Palette.accent)
        .onExitCommand(perform: onDismiss)
    }

    private func secondaryButton(_ title: String, keycap: String, key: KeyEquivalent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                KeycapHint(symbol: keycap)
            }
        }
        .buttonStyle(OverlaySecondaryButtonStyle())
        .keyboardShortcut(key, modifiers: [])
    }
}

private struct BackToBackAirlockView: View {
    let transition: BackToBackTransition
    let onJoin: () -> Void
    let onDismiss: () -> Void

    private var nextMeeting: JoinableMeeting {
        transition.nextMeeting
    }

    var body: some View {
        ZStack {
            OverlayBackdropView()

            VStack(spacing: 18) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 10) {
                        Text(MeetingCountdownFormatter.text(now: context.date, startDate: nextMeeting.startDate))
                            .font(MeetOverlayTheme.Typography.overlayStatus)
                            .monospacedDigit()
                            .foregroundStyle(MeetOverlayTheme.Palette.accent)

                        Text(nextMeeting.title)
                            .font(MeetOverlayTheme.Typography.overlayTitle)
                            .foregroundStyle(MeetOverlayTheme.Palette.overlayText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.55)

                        Label(
                            meetingTimeRangeText(from: nextMeeting.startDate, to: nextMeeting.endDate),
                            systemImage: "clock"
                        )
                        .font(MeetOverlayTheme.Typography.overlayMetadata)
                        .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)
                    }
                }

                Text("Close notes. Join when ready.")
                    .font(MeetOverlayTheme.Typography.overlayHint)
                    .foregroundStyle(MeetOverlayTheme.Palette.overlayTertiaryText)

                HStack(spacing: 12) {
                    Button(action: onJoin) {
                        HStack(spacing: 10) {
                            Text("Join Next Room")
                            KeycapHint(symbol: "⏎", tone: .onAccent)
                        }
                    }
                    .buttonStyle(OverlayPrimaryButtonStyle(minWidth: 210))
                    .keyboardShortcut(.defaultAction)

                    Button(action: onDismiss) {
                        HStack(spacing: 8) {
                            Text("Dismiss")
                            KeycapHint(symbol: "esc")
                        }
                    }
                    .buttonStyle(OverlaySecondaryButtonStyle())
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.top, 4)
            }
            .overlayPanel(maxWidth: 780)
        }
        .tint(MeetOverlayTheme.Palette.accent)
        .onExitCommand(perform: onDismiss)
    }
}

private struct MeetLinkRescueView: View {
    let links: [URL]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Multiple Meet links detected")
                .font(MeetOverlayTheme.Typography.overlayHint.weight(.semibold))
                .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)

            ForEach(Array(links.enumerated()), id: \.offset) { index, link in
                HStack(spacing: 10) {
                    Text("Room \(index + 1): \(GoogleMeetLinkFormatter.roomCode(for: link))")
                        .font(MeetOverlayTheme.Typography.overlayHint)
                        .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)

                    Spacer()

                    Button("Open") {
                        open(link)
                    }
                    .buttonStyle(OverlaySecondaryButtonStyle(compact: true))

                    Button("Copy") {
                        copy(link)
                    }
                    .buttonStyle(OverlaySecondaryButtonStyle(compact: true))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: 520)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(MeetOverlayTheme.Palette.overlayPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(MeetOverlayTheme.Palette.overlayPanelBorder, lineWidth: 1)
        )
    }

    private func open(_ link: URL) {
        NSWorkspace.shared.open(link)
    }

    private func copy(_ link: URL) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(link.absoluteString, forType: .string)
    }
}
