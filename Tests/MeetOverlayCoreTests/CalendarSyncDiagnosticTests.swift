import XCTest
@testable import MeetOverlayCore

final class CalendarSyncDiagnosticTests: XCTestCase {
    func testSummarizesHealthyState() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = CalendarEventSnapshot(
            id: "meet-1",
            calendarID: "work",
            title: "Planning",
            startDate: now.addingTimeInterval(600),
            endDate: now.addingTimeInterval(3_600),
            isAllDay: false,
            participationStatus: .accepted,
            url: nil,
            notes: "https://meet.google.com/abc-defg-hij",
            location: nil
        )

        let diagnostic = CalendarSyncDiagnostic.summary(
            calendarAccess: .allowed,
            calendars: [CalendarSnapshot(id: "work", title: "Work")],
            selectedCalendarIDs: nil,
            launchAtLoginStatus: "Enabled",
            now: now,
            events: [event]
        )

        XCTAssertEqual(diagnostic.calendarAccess.value, "Allowed")
        XCTAssertEqual(diagnostic.includedCalendars.value, "All 1 calendars")
        XCTAssertEqual(diagnostic.launchAtLogin.value, "Enabled")
        XCTAssertEqual(diagnostic.nextMeet.value, "Planning")
        XCTAssertNil(diagnostic.problem)
    }

    func testDoesNotReportProblemForNoUpcomingMeetOrDisabledLaunchAtLogin() throws {
        let diagnostic = CalendarSyncDiagnostic.summary(
            calendarAccess: .allowed,
            calendars: [CalendarSnapshot(id: "work", title: "Work")],
            selectedCalendarIDs: nil,
            launchAtLoginStatus: "Disabled",
            now: Date(timeIntervalSinceReferenceDate: 1_000),
            events: []
        )

        XCTAssertNil(diagnostic.problem)
    }

    func testSummarizesNoCalendarsSelected() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let diagnostic = CalendarSyncDiagnostic.summary(
            calendarAccess: .allowed,
            calendars: [CalendarSnapshot(id: "work", title: "Work")],
            selectedCalendarIDs: [],
            launchAtLoginStatus: "Disabled",
            now: now,
            events: [googleMeetEvent(title: "Planning", startDate: now.addingTimeInterval(600), endDate: now.addingTimeInterval(3_600))]
        )

        XCTAssertEqual(diagnostic.includedCalendars.value, "No calendars selected")
        XCTAssertEqual(diagnostic.nextMeet.value, "No upcoming Google Meet events")
        XCTAssertEqual(diagnostic.problem?.message, "No calendars are selected. Choose at least one calendar so MeetOverlay can catch meetings.")
    }

    func testSummarizesSomeCalendarsAndFiltersNextMeet() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let ignoredEvent = googleMeetEvent(
            title: "Ignored Personal Meet",
            calendarID: "personal",
            startDate: now.addingTimeInterval(300),
            endDate: now.addingTimeInterval(3_600)
        )
        let includedEvent = googleMeetEvent(
            title: "Included Work Meet",
            calendarID: "work",
            startDate: now.addingTimeInterval(600),
            endDate: now.addingTimeInterval(3_600)
        )

        let diagnostic = CalendarSyncDiagnostic.summary(
            calendarAccess: .allowed,
            calendars: [
                CalendarSnapshot(id: "personal", title: "Personal"),
                CalendarSnapshot(id: "work", title: "Work")
            ],
            selectedCalendarIDs: ["work"],
            launchAtLoginStatus: "Enabled",
            now: now,
            events: [ignoredEvent, includedEvent]
        )

        XCTAssertEqual(diagnostic.includedCalendars.value, "1 of 2 calendars")
        XCTAssertEqual(diagnostic.nextMeet.value, "Included Work Meet")
        XCTAssertNil(diagnostic.problem)
    }

    func testSummarizesStaleSelectedCalendarsUsingAvailableCoverage() throws {
        let diagnostic = CalendarSyncDiagnostic.summary(
            calendarAccess: .allowed,
            calendars: [CalendarSnapshot(id: "work", title: "Work")],
            selectedCalendarIDs: ["removed"],
            launchAtLoginStatus: "Enabled",
            now: Date(timeIntervalSinceReferenceDate: 1_000),
            events: []
        )

        XCTAssertEqual(diagnostic.includedCalendars.value, "No calendars selected")
        XCTAssertEqual(diagnostic.problem?.message, "No calendars are selected. Choose at least one calendar so MeetOverlay can catch meetings.")
    }

    func testSummarizesDeniedAccessWithoutCalendarsOrUpcomingMeet() throws {
        let diagnostic = CalendarSyncDiagnostic.summary(
            calendarAccess: .denied,
            calendars: [],
            selectedCalendarIDs: nil,
            launchAtLoginStatus: "Disabled",
            now: Date(timeIntervalSinceReferenceDate: 1_000),
            events: []
        )

        XCTAssertEqual(diagnostic.calendarAccess.value, "Denied")
        XCTAssertEqual(diagnostic.includedCalendars.value, "No calendars available")
        XCTAssertEqual(diagnostic.nextMeet.value, "No upcoming Google Meet events")
        XCTAssertEqual(diagnostic.problem?.message, "Calendar access is denied. Allow access in System Settings so MeetOverlay can read events.")
    }

    private func googleMeetEvent(
        title: String,
        calendarID: String = "work",
        startDate: Date,
        endDate: Date
    ) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: title,
            calendarID: calendarID,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: false,
            participationStatus: .accepted,
            url: nil,
            notes: "https://meet.google.com/abc-defg-hij",
            location: nil
        )
    }
}
