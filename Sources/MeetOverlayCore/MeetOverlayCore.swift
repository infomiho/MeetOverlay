import Foundation

public struct AppPreferences: Codable, Equatable {
    public var selectedCalendarIDs: Set<String>?
    public var isOverlayEnabled: Bool
    public var launchAtLogin: Bool
    public var hidesFinishedEvents: Bool
    public var reminderSoundID: String

    public init(
        selectedCalendarIDs: Set<String>? = nil,
        isOverlayEnabled: Bool = true,
        launchAtLogin: Bool = false,
        hidesFinishedEvents: Bool = true,
        reminderSoundID: String = ReminderSoundCatalog.defaultSound.id
    ) {
        self.selectedCalendarIDs = selectedCalendarIDs
        self.isOverlayEnabled = isOverlayEnabled
        self.launchAtLogin = launchAtLogin
        self.hidesFinishedEvents = hidesFinishedEvents
        self.reminderSoundID = reminderSoundID
    }

    private enum CodingKeys: String, CodingKey {
        case selectedCalendarIDs
        case isOverlayEnabled
        case launchAtLogin
        case hidesFinishedEvents
        case reminderSoundID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        selectedCalendarIDs = try container.decodeIfPresent(Set<String>.self, forKey: .selectedCalendarIDs)
        isOverlayEnabled = try container.decodeIfPresent(Bool.self, forKey: .isOverlayEnabled) ?? true
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        hidesFinishedEvents = try container.decodeIfPresent(Bool.self, forKey: .hidesFinishedEvents) ?? true
        let decodedReminderSoundID = try container.decodeIfPresent(String.self, forKey: .reminderSoundID) ?? ReminderSoundCatalog.defaultSound.id
        reminderSoundID = ReminderSoundCatalog.sound(for: decodedReminderSoundID).id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(selectedCalendarIDs, forKey: .selectedCalendarIDs)
        try container.encode(isOverlayEnabled, forKey: .isOverlayEnabled)
        try container.encode(launchAtLogin, forKey: .launchAtLogin)
        try container.encode(hidesFinishedEvents, forKey: .hidesFinishedEvents)
        try container.encode(reminderSoundID, forKey: .reminderSoundID)
    }
}

public struct ReminderSound: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let resourceName: String
    public let fileExtension: String
}

public enum ReminderSoundCatalog {
    public static let defaultSound = ReminderSound(
        id: "classic",
        title: "Classic",
        resourceName: "notification",
        fileExtension: "mp3"
    )

    public static let sounds: [ReminderSound] = [
        defaultSound,
        ReminderSound(
            id: "soft-chime",
            title: "Soft Chime",
            resourceName: "notification-soft",
            fileExtension: "wav"
        ),
        ReminderSound(
            id: "bright-chime",
            title: "Bright Chime",
            resourceName: "notification-bright",
            fileExtension: "wav"
        )
    ]

    public static func sound(for id: String) -> ReminderSound {
        sounds.first { $0.id == id } ?? defaultSound
    }
}

public final class AppPreferencesStore {
    private let defaults: UserDefaults
    private let key = "appPreferences"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() -> AppPreferences {
        guard let data = defaults.data(forKey: key) else {
            return AppPreferences()
        }

        return (try? JSONDecoder().decode(AppPreferences.self, from: data)) ?? AppPreferences()
    }

    public func save(_ preferences: AppPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }
}

public enum EventParticipationStatus: Equatable {
    case unknown
    case accepted
    case tentative
    case declined
}

public struct CalendarEventSnapshot: Equatable {
    public let id: String
    public let calendarID: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let participationStatus: EventParticipationStatus
    public let url: URL?
    public let notes: String?
    public let location: String?

    public init(
        id: String,
        calendarID: String = "",
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        participationStatus: EventParticipationStatus,
        url: URL?,
        notes: String?,
        location: String?
    ) {
        self.id = id
        self.calendarID = calendarID
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.participationStatus = participationStatus
        self.url = url
        self.notes = notes
        self.location = location
    }
}

public extension CalendarEventSnapshot {
    var meetLinks: [URL] {
        GoogleMeetLinkFinder.links(in: [url?.absoluteString, notes, location, title].compactMap { $0 })
    }
}

public enum CalendarEventFilter {
    public static func events(
        _ events: [CalendarEventSnapshot],
        selectedCalendarIDs: Set<String>?
    ) -> [CalendarEventSnapshot] {
        guard let selectedCalendarIDs else {
            return events
        }

        return events.filter { selectedCalendarIDs.contains($0.calendarID) }
    }
}

public struct CalendarSnapshot: Equatable, Identifiable {
    public let id: String
    public let title: String
    public let sourceTitle: String?

    public var displayTitle: String {
        guard let sourceTitle, !sourceTitle.isEmpty else {
            return title
        }

        return "\(title) - \(sourceTitle)"
    }

    public init(id: String, title: String, sourceTitle: String? = nil) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
    }
}

public enum CalendarSelectionUpdater {
    public static func updatedSelection(
        currentSelection: Set<String>?,
        allCalendarIDs: Set<String>,
        calendarID: String,
        isSelected: Bool
    ) -> Set<String>? {
        var selection = currentSelection ?? allCalendarIDs

        if isSelected {
            selection.insert(calendarID)
        } else {
            selection.remove(calendarID)
        }

        return selection == allCalendarIDs ? nil : selection
    }
}

public enum CalendarAccessDiagnosticState: Equatable {
    case allowed
    case denied
    case notDetermined
    case restricted
    case unknown
}

public struct CalendarSyncDiagnosticItem: Equatable {
    public let title: String
    public let value: String
}

public struct CalendarSyncDiagnosticProblem: Equatable {
    public let message: String
}

public struct CalendarSyncDiagnostic: Equatable {
    public let calendarAccess: CalendarSyncDiagnosticItem
    public let includedCalendars: CalendarSyncDiagnosticItem
    public let launchAtLogin: CalendarSyncDiagnosticItem
    public let nextMeet: CalendarSyncDiagnosticItem
    public let problem: CalendarSyncDiagnosticProblem?

    public static func summary(
        calendarAccess: CalendarAccessDiagnosticState,
        calendars: [CalendarSnapshot],
        selectedCalendarIDs: Set<String>?,
        launchAtLoginStatus: String,
        now: Date,
        events: [CalendarEventSnapshot]
    ) -> CalendarSyncDiagnostic {
        CalendarSyncDiagnostic(
            calendarAccess: CalendarSyncDiagnosticItem(title: "Calendar Access", value: calendarAccessText(calendarAccess)),
            includedCalendars: CalendarSyncDiagnosticItem(title: "Included Calendars", value: includedCalendarsText(calendars: calendars, selectedCalendarIDs: selectedCalendarIDs)),
            launchAtLogin: CalendarSyncDiagnosticItem(title: "Open at Login", value: launchAtLoginStatus),
            nextMeet: CalendarSyncDiagnosticItem(title: "Next Google Meet", value: nextMeetText(now: now, events: events, selectedCalendarIDs: selectedCalendarIDs)),
            problem: problem(calendarAccess: calendarAccess, calendars: calendars, selectedCalendarIDs: selectedCalendarIDs)
        )
    }

    private static func calendarAccessText(_ state: CalendarAccessDiagnosticState) -> String {
        switch state {
        case .allowed:
            return "Allowed"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not requested yet"
        case .restricted:
            return "Restricted"
        case .unknown:
            return "Unknown"
        }
    }

    private static func includedCalendarsText(calendars: [CalendarSnapshot], selectedCalendarIDs: Set<String>?) -> String {
        guard !calendars.isEmpty else {
            return "No calendars available"
        }

        guard let selectedCalendarIDs else {
            return "All \(calendars.count) calendars"
        }

        let availableCalendarIDs = Set(calendars.map(\.id))
        let includedCalendarCount = selectedCalendarIDs.intersection(availableCalendarIDs).count

        guard includedCalendarCount > 0 else {
            return "No calendars selected"
        }

        guard includedCalendarCount < calendars.count else {
            return "All \(calendars.count) calendars"
        }

        return "\(includedCalendarCount) of \(calendars.count) calendars"
    }

    private static func problem(
        calendarAccess: CalendarAccessDiagnosticState,
        calendars: [CalendarSnapshot],
        selectedCalendarIDs: Set<String>?
    ) -> CalendarSyncDiagnosticProblem? {
        switch calendarAccess {
        case .allowed:
            break
        case .denied:
            return CalendarSyncDiagnosticProblem(message: "Calendar access is denied. Allow access in System Settings so MeetOverlay can read events.")
        case .notDetermined:
            return CalendarSyncDiagnosticProblem(message: "Calendar access has not been requested yet. Allow access so MeetOverlay can read events.")
        case .restricted:
            return CalendarSyncDiagnosticProblem(message: "Calendar access is restricted. Check System Settings so MeetOverlay can read events.")
        case .unknown:
            return CalendarSyncDiagnosticProblem(message: "Calendar access status is unknown. Check System Settings so MeetOverlay can read events.")
        }

        guard !calendars.isEmpty else {
            return CalendarSyncDiagnosticProblem(message: "No calendars are available. Check Calendar access and account sync in System Settings.")
        }

        guard let selectedCalendarIDs else {
            return nil
        }

        let availableCalendarIDs = Set(calendars.map(\.id))
        guard selectedCalendarIDs.intersection(availableCalendarIDs).isEmpty else {
            return nil
        }

        return CalendarSyncDiagnosticProblem(message: "No calendars are selected. Choose at least one calendar so MeetOverlay can catch meetings.")
    }

    private static func nextMeetText(
        now: Date,
        events: [CalendarEventSnapshot],
        selectedCalendarIDs: Set<String>?
    ) -> String {
        CalendarEventFilter.events(events, selectedCalendarIDs: selectedCalendarIDs)
            .filter { $0.endDate > now }
            .filter { JoinableMeeting.from($0) != nil }
            .sorted { $0.startDate < $1.startDate }
            .first?
            .title ?? "No upcoming Google Meet events"
    }
}

public struct JoinableMeeting: Equatable {
    public let eventID: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let meetURL: URL
    public let meetLinks: [URL]
}

public enum MeetingAlertStage: Equatable, Hashable {
    case gentle
    case fullscreen
}

public struct MeetingAlert: Equatable {
    public let stage: MeetingAlertStage
    public let meeting: JoinableMeeting
}

public struct BackToBackTransition: Equatable {
    public let currentEventID: String
    public let nextMeeting: JoinableMeeting
}

public struct BackToBackAirlock {
    private let transitionLeadTime: TimeInterval
    private let maximumGap: TimeInterval
    private let currentGraceTime: TimeInterval

    public init(
        transitionLeadTime: TimeInterval = 5 * 60,
        maximumGap: TimeInterval = 10 * 60,
        currentGraceTime: TimeInterval = 5 * 60
    ) {
        self.transitionLeadTime = transitionLeadTime
        self.maximumGap = maximumGap
        self.currentGraceTime = currentGraceTime
    }

    public func transition(
        now: Date,
        events: [CalendarEventSnapshot],
        hiddenEventIDs: Set<String>,
        dismissedTransitionEventIDs: Set<String>
    ) -> BackToBackTransition? {
        let joinableEvents = events
            .filter { JoinableMeeting.from($0) != nil }

        guard let current = joinableEvents
            .filter({ $0.startDate <= now })
            .filter({ $0.endDate >= now.addingTimeInterval(-currentGraceTime) })
            .sorted(by: { $0.endDate > $1.endDate })
            .first else {
            return nil
        }

        guard let next = joinableEvents
            .filter({ $0.id != current.id })
            .filter({ !hiddenEventIDs.contains($0.id) })
            .filter({ !dismissedTransitionEventIDs.contains($0.id) })
            .filter({ $0.startDate >= now })
            .filter({ $0.startDate <= now.addingTimeInterval(transitionLeadTime) })
            .filter({ $0.startDate >= current.endDate })
            .filter({ $0.startDate <= current.endDate.addingTimeInterval(maximumGap) })
            .sorted(by: { $0.startDate < $1.startDate })
            .compactMap(JoinableMeeting.from)
            .first else {
            return nil
        }

        return BackToBackTransition(currentEventID: current.id, nextMeeting: next)
    }
}

public struct MeetingAlertLadder {
    private let gentleLeadTime: TimeInterval
    private let fullscreenLeadTime: TimeInterval
    private let lateAlertGraceTime: TimeInterval

    public init(
        gentleLeadTime: TimeInterval = 5 * 60,
        fullscreenLeadTime: TimeInterval = 60,
        lateAlertGraceTime: TimeInterval = 120
    ) {
        self.gentleLeadTime = gentleLeadTime
        self.fullscreenLeadTime = fullscreenLeadTime
        self.lateAlertGraceTime = lateAlertGraceTime
    }

    public func alert(
        now: Date,
        events: [CalendarEventSnapshot],
        hiddenEventIDs: Set<String>
    ) -> MeetingAlert? {
        events
            .sorted { $0.startDate < $1.startDate }
            .compactMap { event -> MeetingAlert? in
                guard event.endDate > now else { return nil }
                guard event.startDate <= now.addingTimeInterval(gentleLeadTime) else { return nil }
                guard event.startDate >= now.addingTimeInterval(-lateAlertGraceTime) else { return nil }
                guard !hiddenEventIDs.contains(event.id) else { return nil }
                guard let meeting = JoinableMeeting.from(event) else { return nil }

                let stage: MeetingAlertStage = event.startDate <= now.addingTimeInterval(fullscreenLeadTime) ? .fullscreen : .gentle
                return MeetingAlert(stage: stage, meeting: meeting)
            }
            .first
    }
}

public extension JoinableMeeting {
    static func from(_ event: CalendarEventSnapshot) -> JoinableMeeting? {
        guard !event.isAllDay else { return nil }
        guard event.participationStatus != .declined else { return nil }

        let meetLinks = event.meetLinks
        guard let meetURL = meetLinks.first else { return nil }

        return JoinableMeeting(
            eventID: event.id,
            title: event.title,
            startDate: event.startDate,
            endDate: event.endDate,
            meetURL: meetURL,
            meetLinks: meetLinks
        )
    }
}

public struct MeetingReminderState: Equatable {
    private var handledEventIDs = Set<String>()
    private var snoozedUntilByEventID: [String: Date] = [:]
    private var deliveredStagesByEventID: [String: Set<MeetingAlertStage>] = [:]
    private var dismissedAirlockIDs = Set<String>()

    public init() {}

    public mutating func join(eventID: String) {
        suppress(eventID: eventID)
    }

    public mutating func dismiss(eventID: String) {
        suppress(eventID: eventID)
    }

    public mutating func snooze(eventID: String, until date: Date) {
        snoozedUntilByEventID[eventID] = date
    }

    public mutating func hiddenEventIDs(now: Date) -> Set<String> {
        snoozedUntilByEventID = snoozedUntilByEventID.filter { $0.value > now }
        return handledEventIDs.union(snoozedUntilByEventID.keys)
    }

    public func shouldDeliver(eventID: String, stage: MeetingAlertStage) -> Bool {
        !(deliveredStagesByEventID[eventID]?.contains(stage) ?? false)
    }

    public mutating func recordDelivery(eventID: String, stage: MeetingAlertStage) {
        deliveredStagesByEventID[eventID, default: []].insert(stage)
    }

    public var dismissedAirlockEventIDs: Set<String> {
        dismissedAirlockIDs
    }

    public mutating func dismissAirlock(eventID: String) {
        dismissedAirlockIDs.insert(eventID)
    }

    private mutating func suppress(eventID: String) {
        handledEventIDs.insert(eventID)
        snoozedUntilByEventID[eventID] = nil
    }
}

public struct MeetingAlertSelector {
    private let alertLeadTime: TimeInterval
    private let lateAlertGraceTime: TimeInterval

    public init(alertLeadTime: TimeInterval, lateAlertGraceTime: TimeInterval = 120) {
        self.alertLeadTime = alertLeadTime
        self.lateAlertGraceTime = lateAlertGraceTime
    }

    public func meetingToShow(
        now: Date,
        events: [CalendarEventSnapshot],
        hiddenEventIDs: Set<String>
    ) -> JoinableMeeting? {
        events
            .sorted { $0.startDate < $1.startDate }
            .compactMap { event -> JoinableMeeting? in
                guard event.endDate > now else { return nil }
                guard event.startDate <= now.addingTimeInterval(alertLeadTime) else { return nil }
                guard event.startDate >= now.addingTimeInterval(-lateAlertGraceTime) else { return nil }
                guard !hiddenEventIDs.contains(event.id) else { return nil }

                return JoinableMeeting.from(event)
            }
            .first
    }
}

public struct CalendarMenuSection: Equatable {
    public let title: String
    public let rows: [CalendarMenuRow]
}

public struct CalendarMenuRow: Equatable {
    public let eventID: String
    public let title: String
    public let timeText: String
    public let statusText: String?
    public let hasMeetLink: Bool
    public let meetURL: URL?
    public let meetLinks: [URL]
}

public enum CalendarMenuBarUrgency: Equatable {
    case idle
    case upcoming
    case active
    case urgent
}

public struct CalendarMenuBarPresentation: Equatable {
    public let title: String
    public let urgency: CalendarMenuBarUrgency
}

public struct CalendarMenuPresenter {
    private let calendar: Calendar
    private let timeFormatter: DateFormatter
    private let menuBarTitleLimit = 24
    private let urgentMenuBarThreshold: TimeInterval = 5 * 60

    public init(calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar

        let timeFormatter = DateFormatter()
        timeFormatter.calendar = calendar
        timeFormatter.timeZone = calendar.timeZone
        timeFormatter.locale = locale
        timeFormatter.dateStyle = .none
        timeFormatter.timeStyle = .short
        self.timeFormatter = timeFormatter
    }

    public func sections(
        now: Date,
        events: [CalendarEventSnapshot],
        hideFinishedEvents: Bool = true
    ) -> [CalendarMenuSection] {
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let visibleEvents = hideFinishedEvents ? events.filter { $0.endDate > now } : events
        let highlightSections = highlightSections(now: now, events: visibleEvents)
        let highlightedEventIDs = Set(highlightSections.flatMap { $0.rows.map(\.eventID) })
        let timelineEvents = visibleEvents.filter { !highlightedEventIDs.contains($0.id) }

        let timelineSections: [CalendarMenuSection] = [
            section(title: "Today's Events", day: now, now: now, events: timelineEvents),
            section(title: "Tomorrow's Events", day: tomorrow, now: now, events: timelineEvents)
        ].compactMap { section -> CalendarMenuSection? in
            section.rows.isEmpty ? nil : section
        }

        return highlightSections + timelineSections
    }

    public func menuBarTitle(now: Date, events: [CalendarEventSnapshot]) -> String {
        menuBarPresentation(now: now, events: events).title
    }

    public func menuBarPresentation(now: Date, events: [CalendarEventSnapshot]) -> CalendarMenuBarPresentation {
        let meetEvents = events
            .filter({ calendar.isDate($0.startDate, inSameDayAs: now) })
            .filter({ $0.endDate > now })
            .filter({ JoinableMeeting.from($0) != nil })

        if let activeEvent = meetEvents
            .filter({ $0.startDate <= now })
            .sorted(by: { $0.startDate > $1.startDate })
            .first {
            return menuBarPresentation(now: now, event: activeEvent)
        }

        guard let event = meetEvents
            .filter({ $0.startDate > now })
            .sorted(by: { $0.startDate < $1.startDate })
            .first else {
            return CalendarMenuBarPresentation(title: "Meet", urgency: .idle)
        }

        return menuBarPresentation(now: now, event: event)
    }

    private func menuBarPresentation(now: Date, event: CalendarEventSnapshot) -> CalendarMenuBarPresentation {
        let title = shortTitle(event.title)

        switch timing(now: now, event: event) {
        case .future(let secondsUntilStart):
            let urgency: CalendarMenuBarUrgency = TimeInterval(secondsUntilStart) <= urgentMenuBarThreshold ? .urgent : .upcoming
            return CalendarMenuBarPresentation(
                title: "\(title) \(CountdownDurationFormatter.text(seconds: secondsUntilStart))",
                urgency: urgency
            )
        case .starting:
            return CalendarMenuBarPresentation(title: "\(title) now", urgency: .urgent)
        case .active:
            return CalendarMenuBarPresentation(title: "\(title) now", urgency: .active)
        case .ended:
            return CalendarMenuBarPresentation(title: "Meet", urgency: .idle)
        }
    }

    private func shortTitle(_ title: String) -> String {
        guard title.count > menuBarTitleLimit else {
            return title
        }

        return "\(title.prefix(menuBarTitleLimit - 3))..."
    }

    private func highlightSections(now: Date, events: [CalendarEventSnapshot]) -> [CalendarMenuSection] {
        let meetEvents = events
            .filter { calendar.isDate($0.startDate, inSameDayAs: now) }
            .filter { JoinableMeeting.from($0) != nil }

        let activeMeet = meetEvents
            .filter { $0.startDate <= now && $0.endDate > now }
            .sorted { $0.startDate > $1.startDate }
            .first
        let nextMeet = meetEvents
            .filter { $0.startDate > now }
            .sorted { $0.startDate < $1.startDate }
            .first

        guard activeMeet != nil || isUrgentNextUp(now: now, event: nextMeet) else {
            return []
        }

        return [
            activeMeet.map { CalendarMenuSection(title: "Happening Now", rows: [row(for: $0, now: now)]) },
            nextMeet.map { CalendarMenuSection(title: "Next Up", rows: [row(for: $0, now: now)]) }
        ].compactMap { $0 }
    }

    private func isUrgentNextUp(now: Date, event: CalendarEventSnapshot?) -> Bool {
        guard let event else {
            return false
        }

        return event.startDate.timeIntervalSince(now) <= urgentMenuBarThreshold
    }

    private func section(title: String, day: Date, now: Date, events: [CalendarEventSnapshot]) -> CalendarMenuSection {
        let rows = events
            .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
            .sorted { $0.startDate < $1.startDate }
            .map { row(for: $0, now: now) }

        return CalendarMenuSection(title: title, rows: rows)
    }

    private func row(for event: CalendarEventSnapshot, now: Date) -> CalendarMenuRow {
        let meetLinks = event.meetLinks

        return CalendarMenuRow(
            eventID: event.id,
            title: event.title,
            timeText: event.isAllDay ? "All-day" : timeFormatter.string(from: event.startDate),
            statusText: statusText(now: now, event: event),
            hasMeetLink: !meetLinks.isEmpty,
            meetURL: meetLinks.first,
            meetLinks: meetLinks
        )
    }

    private func timing(now: Date, event: CalendarEventSnapshot) -> MenuEventTiming {
        guard event.endDate > now else {
            return .ended
        }

        let secondsUntilStart = Int(event.startDate.timeIntervalSince(now).rounded(.up))
        if secondsUntilStart > 0 {
            return .future(secondsUntilStart)
        }

        let elapsedSeconds = Int(now.timeIntervalSince(event.startDate).rounded(.down))
        return elapsedSeconds <= 60 ? .starting : .active
    }

    private func statusText(now: Date, event: CalendarEventSnapshot) -> String? {
        guard !event.isAllDay else {
            return nil
        }

        switch timing(now: now, event: event) {
        case .future(let secondsUntilStart):
            return "in \(CountdownDurationFormatter.text(seconds: secondsUntilStart))"
        case .starting:
            return "now"
        case .active:
            return "now"
        case .ended:
            return "ended"
        }
    }

    private enum MenuEventTiming {
        case future(Int)
        case starting
        case active
        case ended
    }
}

public enum MeetingCountdownFormatter {
    public static func text(now: Date, startDate: Date) -> String {
        let seconds = Int(startDate.timeIntervalSince(now).rounded(.up))

        if seconds < 0 {
            let elapsedSeconds = abs(seconds)

            if elapsedSeconds < 60 {
                return "Started just now"
            }

            return "Started \(CountdownDurationFormatter.text(seconds: elapsedSeconds)) ago"
        }

        if seconds == 0 {
            return "Starts now"
        }

        return "Starts in \(CountdownDurationFormatter.text(seconds: seconds))"
    }
}

private enum CountdownDurationFormatter {
    static func text(seconds: Int) -> String {
        if seconds < 60 {
            return unitText(seconds, singular: "second")
        }

        let minutes = Int(ceil(Double(seconds) / 60))
        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        let hourText = "\(hours)h"

        guard remainingMinutes > 0 else {
            return hourText
        }

        return "\(hourText) \(remainingMinutes)m"
    }

    private static func unitText(_ count: Int, singular: String) -> String {
        "\(count) \(count == 1 ? singular : "\(singular)s")"
    }
}

public enum GoogleMeetLinkFormatter {
    public static func roomCode(for url: URL) -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        let roomCode = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return roomCode.isEmpty ? url.absoluteString : roomCode
    }
}

public enum GoogleMeetLinkFinder {
    public static func firstLink(in candidates: [String]) -> URL? {
        links(in: candidates).first
    }

    public static func links(in candidates: [String]) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return []
        }

        var links: [URL] = []
        var seenKeys = Set<String>()

        for candidate in candidates {
            let range = NSRange(candidate.startIndex..<candidate.endIndex, in: candidate)
            let matches = detector.matches(in: candidate, options: [], range: range)

            for match in matches {
                guard let url = match.url, isGoogleMeetURL(url) else { continue }
                let key = canonicalKey(for: url)
                guard seenKeys.insert(key).inserted else { continue }
                links.append(url)
            }
        }

        return links
    }

    private static func isGoogleMeetURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            return false
        }

        return url.host?.lowercased() == "meet.google.com"
    }

    private static func canonicalKey(for url: URL) -> String {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }

        let host = components.host?.lowercased() ?? ""
        let roomPath = GoogleMeetLinkFormatter.roomCode(for: url).lowercased()
        return "\(host)/\(roomPath)"
    }
}
