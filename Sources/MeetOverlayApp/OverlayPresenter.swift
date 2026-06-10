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
            window.contentView = NSHostingView(rootView: contentView)

            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            windows.append(window)
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
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

private struct MeetingOverlayView: View {
    let meeting: JoinableMeeting
    let onJoin: () -> Void
    let onSnooze: (TimeInterval) -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [MeetOverlayTheme.Palette.overlayStart, MeetOverlayTheme.Palette.overlayEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: MeetOverlayTheme.Spacing.overlayContent) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 12) {
                        Text(MeetingCountdownFormatter.text(now: context.date, startDate: meeting.startDate))
                            .font(MeetOverlayTheme.Typography.overlayStatus)
                            .foregroundStyle(MeetOverlayTheme.Palette.accent)

                        Text(meeting.title)
                            .font(MeetOverlayTheme.Typography.overlayTitle)
                            .foregroundStyle(MeetOverlayTheme.Palette.overlayText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.5)

                        Label(timeRangeText, systemImage: "clock")
                            .font(MeetOverlayTheme.Typography.overlayMetadata)
                            .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)
                    }
                }

                HStack(spacing: 12) {
                    Button(action: onJoin) {
                        Text(meeting.meetLinks.count > 1 ? "Join First Room" : "Join Room")
                            .font(MeetOverlayTheme.Typography.overlayButton.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 38)
                            .padding(.vertical, 17)
                            .frame(minWidth: 172)
                            .background(
                                Capsule()
                                    .fill(MeetOverlayTheme.Palette.accent)
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)

                    secondaryButton("Snooze 1m") {
                        onSnooze(60)
                    }

                    secondaryButton("Snooze 5m") {
                        onSnooze(5 * 60)
                    }

                    Button(action: onDismiss) {
                        secondaryButtonLabel("Dismiss")
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.top, 4)

                if meeting.meetLinks.count > 1 {
                    MeetLinkRescueView(links: meeting.meetLinks)
                }

                Text(meeting.meetLinks.count > 1 ? "Return joins the first room. Esc dismisses this reminder." : "Return joins the room. Esc dismisses this reminder.")
                    .font(MeetOverlayTheme.Typography.overlayHint)
                    .foregroundStyle(MeetOverlayTheme.Palette.overlayTertiaryText)
            }
            .padding(.horizontal, MeetOverlayTheme.Spacing.overlayPanelHorizontal)
            .padding(.vertical, MeetOverlayTheme.Spacing.overlayPanelVertical)
            .frame(maxWidth: 840)
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
        }
        .tint(MeetOverlayTheme.Palette.accent)
        .onExitCommand(perform: onDismiss)
    }

    private var timeRangeText: String {
        "\(meeting.startDate.formatted(date: .omitted, time: .shortened)) to \(meeting.endDate.formatted(date: .omitted, time: .shortened))"
    }

    private func secondaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            secondaryButtonLabel(title)
        }
        .buttonStyle(.plain)
    }

    private func secondaryButtonLabel(_ title: String) -> some View {
        Text(title)
            .font(MeetOverlayTheme.Typography.overlaySecondaryButton)
            .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minWidth: 112)
            .background(
                Capsule()
                    .fill(MeetOverlayTheme.Palette.overlayPanel)
            )
            .overlay(
                Capsule()
                    .stroke(MeetOverlayTheme.Palette.overlayPanelBorder, lineWidth: 1)
            )
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
            LinearGradient(
                colors: [MeetOverlayTheme.Palette.overlayStart, MeetOverlayTheme.Palette.overlayEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(spacing: 10) {
                        Text(MeetingCountdownFormatter.text(now: context.date, startDate: nextMeeting.startDate))
                            .font(MeetOverlayTheme.Typography.overlayStatus)
                            .foregroundStyle(MeetOverlayTheme.Palette.accent)

                        Text(nextMeeting.title)
                            .font(MeetOverlayTheme.Typography.overlayTitle)
                            .foregroundStyle(MeetOverlayTheme.Palette.overlayText)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.55)

                        Label(timeRangeText, systemImage: "clock")
                            .font(MeetOverlayTheme.Typography.overlayMetadata)
                            .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)
                    }
                }

                Text("Close notes. Join when ready.")
                    .font(MeetOverlayTheme.Typography.overlayHint)
                    .foregroundStyle(MeetOverlayTheme.Palette.overlayTertiaryText)

                HStack(spacing: 12) {
                    Button(action: onJoin) {
                        Text("Join Next Room")
                            .font(MeetOverlayTheme.Typography.overlayButton.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 38)
                            .padding(.vertical, 17)
                            .frame(minWidth: 210)
                            .background(Capsule().fill(MeetOverlayTheme.Palette.accent))
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)

                    Button(action: onDismiss) {
                        secondaryButtonLabel("Dismiss")
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, MeetOverlayTheme.Spacing.overlayPanelHorizontal)
            .padding(.vertical, MeetOverlayTheme.Spacing.overlayPanelVertical)
            .frame(maxWidth: 780)
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
        }
        .tint(MeetOverlayTheme.Palette.accent)
        .onExitCommand(perform: onDismiss)
    }

    private var timeRangeText: String {
        "\(nextMeeting.startDate.formatted(date: .omitted, time: .shortened)) to \(nextMeeting.endDate.formatted(date: .omitted, time: .shortened))"
    }

    private func secondaryButtonLabel(_ title: String) -> some View {
        Text(title)
            .font(MeetOverlayTheme.Typography.overlaySecondaryButton)
            .foregroundStyle(MeetOverlayTheme.Palette.overlaySecondaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minWidth: 112)
            .background(Capsule().fill(MeetOverlayTheme.Palette.overlayPanel))
            .overlay(
                Capsule()
                    .stroke(MeetOverlayTheme.Palette.overlayPanelBorder, lineWidth: 1)
            )
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
                    .buttonStyle(.borderedProminent)

                    Button("Copy") {
                        copy(link)
                    }
                    .buttonStyle(.bordered)
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
