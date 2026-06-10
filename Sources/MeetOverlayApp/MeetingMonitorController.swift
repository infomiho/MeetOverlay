import AppKit
import Foundation
import MeetOverlayCore

@MainActor
final class MeetingMonitorController {
    private let calendarEventSource: CalendarEventSource
    private let overlayPresenter: OverlayPresenter
    private let statusMenu: StatusMenuController
    private let preferencesStore: AppPreferencesStore
    private let alertLadder = MeetingAlertLadder()
    private let airlock = BackToBackAirlock()
    private let gentleAlertPresenter = GentleAlertPresenter()
    private let menuPresenter = CalendarMenuPresenter()

    private var timer: Timer?
    private var isEnabled = true
    private var hasCalendarAccess = false
    private var visibleEventID: String?
    private var isPreviewVisible = false
    private var reminderState = MeetingReminderState()

    init(
        calendarEventSource: CalendarEventSource,
        overlayPresenter: OverlayPresenter,
        statusMenu: StatusMenuController,
        preferencesStore: AppPreferencesStore
    ) {
        self.calendarEventSource = calendarEventSource
        self.overlayPresenter = overlayPresenter
        self.statusMenu = statusMenu
        self.preferencesStore = preferencesStore
        self.isEnabled = preferencesStore.load().isOverlayEnabled

        statusMenu.onOpenCalendarSettings = {
            guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") else { return }
            NSWorkspace.shared.open(url)
        }

        calendarEventSource.onEventStoreChanged = { [weak self] in
            self?.checkNow()
        }
    }

    func start() {
        statusMenu.update(status: "Requesting Calendar access", isEnabled: isEnabled)

        calendarEventSource.requestAccess { [weak self] granted in
            guard let self else { return }

            self.hasCalendarAccess = granted

            if granted {
                self.statusMenu.update(status: "Watching for meetings", isEnabled: self.isEnabled)
                self.startTimer()
                self.checkNow()
            } else {
                self.statusMenu.update(status: "Calendar access denied", isEnabled: self.isEnabled)
            }
        }
    }

    func refreshFromPreferences() {
        isEnabled = preferencesStore.load().isOverlayEnabled
        checkNow()
    }

    func previewReminder() {
        guard visibleEventID == nil, !isPreviewVisible else { return }

        let now = Date()
        let sampleEvent = CalendarEventSnapshot(
            id: "preview",
            title: "Sample Meeting",
            startDate: now.addingTimeInterval(60),
            endDate: now.addingTimeInterval(30 * 60),
            isAllDay: false,
            participationStatus: .accepted,
            url: nil,
            notes: "https://meet.google.com/abc-defg-hij",
            location: nil
        )

        guard let meeting = JoinableMeeting.from(sampleEvent) else { return }

        isPreviewVisible = true
        overlayPresenter.show(
            meeting: meeting,
            reminderSound: ReminderSoundCatalog.sound(for: preferencesStore.load().reminderSoundID),
            onJoin: { [weak self] in self?.endPreview() },
            onSnooze: { [weak self] _ in self?.endPreview() },
            onDismiss: { [weak self] in self?.endPreview() }
        )
    }

    private func endPreview() {
        isPreviewVisible = false
        overlayPresenter.hide()
        checkNow()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkNow()
            }
        }
        timer?.tolerance = 3
    }

    private func checkNow() {
        guard !isPreviewVisible else { return }

        guard hasCalendarAccess else {
            statusMenu.update(
                status: "Calendar access needed",
                isEnabled: isEnabled,
                emptyMessage: "Allow Calendar access in System Settings",
                showsCalendarSettingsAction: true
            )
            return
        }

        let now = Date()
        let preferences = preferencesStore.load()
        isEnabled = preferences.isOverlayEnabled
        let events = eventsForMenu(now: now, preferences: preferences)
        let sections = menuPresenter.sections(
            now: now,
            events: events,
            hideFinishedEvents: preferences.hidesFinishedEvents
        )
        let menuBarPresentation = menuPresenter.menuBarPresentation(now: now, events: events)
        let emptyMessage = emptyMessage(for: preferences)

        guard isEnabled else {
            visibleEventID = nil
            overlayPresenter.hide()
            statusMenu.update(
                status: "Fullscreen alerts off",
                isEnabled: isEnabled,
                menuBarTitle: menuBarPresentation.title,
                menuBarUrgency: menuBarPresentation.urgency,
                sections: sections,
                emptyMessage: emptyMessage
            )
            return
        }

        let hiddenEventIDs = reminderState.hiddenEventIDs(now: now)
        let transition = airlock.transition(
            now: now,
            events: events,
            hiddenEventIDs: hiddenEventIDs,
            dismissedTransitionEventIDs: reminderState.dismissedAirlockEventIDs
        )

        if let transition {
            let meeting = transition.nextMeeting
            statusMenu.update(
                status: "Back-to-back: \(meeting.title)",
                isEnabled: isEnabled,
                menuBarTitle: menuBarPresentation.title,
                menuBarUrgency: menuBarPresentation.urgency,
                sections: sections,
                emptyMessage: emptyMessage
            )

            guard visibleEventID != meeting.eventID else {
                return
            }

            visibleEventID = meeting.eventID
            overlayPresenter.showAirlock(
                transition: transition,
                onJoin: { [weak self] in
                    NSWorkspace.shared.open(meeting.meetURL)
                    self?.joinVisibleMeeting(meeting.eventID)
                },
                onDismiss: { [weak self] in
                    self?.dismissAirlock(meeting.eventID)
                }
            )
            return
        }

        let alert = alertLadder.alert(
            now: now,
            events: events,
            hiddenEventIDs: hiddenEventIDs,
            lateAlertExemptEventIDs: reminderState.expiredSnoozeEventIDs
        )

        guard let alert else {
            visibleEventID = nil
            overlayPresenter.hide()
            statusMenu.update(
                status: "No meeting soon",
                isEnabled: isEnabled,
                menuBarTitle: menuBarPresentation.title,
                menuBarUrgency: menuBarPresentation.urgency,
                sections: sections,
                emptyMessage: emptyMessage
            )
            return
        }

        let meeting = alert.meeting

        guard alert.stage == .fullscreen else {
            visibleEventID = nil
            overlayPresenter.hide()
            if reminderState.shouldDeliver(eventID: meeting.eventID, stage: alert.stage) {
                gentleAlertPresenter.show(meeting: meeting)
                reminderState.recordDelivery(eventID: meeting.eventID, stage: alert.stage)
            }

            statusMenu.update(
                status: "Meeting soon: \(meeting.title)",
                isEnabled: isEnabled,
                menuBarTitle: menuBarPresentation.title,
                menuBarUrgency: menuBarPresentation.urgency,
                sections: sections,
                emptyMessage: emptyMessage
            )
            return
        }

        statusMenu.update(
            status: "Upcoming: \(meeting.title)",
            isEnabled: isEnabled,
            menuBarTitle: menuBarPresentation.title,
            menuBarUrgency: menuBarPresentation.urgency,
            sections: sections,
            emptyMessage: emptyMessage
        )

        guard visibleEventID != meeting.eventID else {
            return
        }

        guard reminderState.shouldDeliver(eventID: meeting.eventID, stage: alert.stage) else {
            return
        }

        visibleEventID = meeting.eventID
        reminderState.recordDelivery(eventID: meeting.eventID, stage: alert.stage)
        overlayPresenter.show(
            meeting: meeting,
            reminderSound: ReminderSoundCatalog.sound(for: preferences.reminderSoundID),
            onJoin: { [weak self] in
                NSWorkspace.shared.open(meeting.meetURL)
                self?.joinVisibleMeeting(meeting.eventID)
            },
            onSnooze: { [weak self] duration in
                self?.snoozeVisibleMeeting(meeting.eventID, duration: duration)
            },
            onDismiss: { [weak self] in
                self?.dismissVisibleMeeting(meeting.eventID)
            }
        )
    }

    private func eventsForMenu(now: Date, preferences: AppPreferences) -> [CalendarEventSnapshot] {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 2, to: startDate) ?? now.addingTimeInterval(48 * 60 * 60)
        let events = calendarEventSource.events(from: startDate, to: endDate)

        return CalendarEventFilter.events(events, selectedCalendarIDs: preferences.selectedCalendarIDs)
    }

    private func emptyMessage(for preferences: AppPreferences) -> String {
        if preferences.selectedCalendarIDs == [] {
            return "No calendars selected. Open Settings to choose calendars."
        }

        return "No selected-calendar events today or tomorrow"
    }

    private func joinVisibleMeeting(_ eventID: String) {
        reminderState.join(eventID: eventID)
        hideVisibleMeeting()
        checkNow()
    }

    private func dismissVisibleMeeting(_ eventID: String) {
        reminderState.dismiss(eventID: eventID)
        hideVisibleMeeting()
        checkNow()
    }

    private func snoozeVisibleMeeting(_ eventID: String, duration: TimeInterval) {
        reminderState.snooze(eventID: eventID, until: Date().addingTimeInterval(duration))
        hideVisibleMeeting()
        checkNow()
    }

    private func dismissAirlock(_ eventID: String) {
        reminderState.dismissAirlock(eventID: eventID)
        hideVisibleMeeting()
        checkNow()
    }

    private func hideVisibleMeeting() {
        visibleEventID = nil
        overlayPresenter.hide()
    }
}
