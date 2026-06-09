import XCTest
@testable import MeetOverlayCore

final class MeetingAlertSelectorTests: XCTestCase {
    func testShowsUpcomingMeetEventInsideAlertWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Planning",
            startDate: now.addingTimeInterval(60),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertEqual(selectedMeeting?.eventID, "event-1")
        XCTAssertEqual(selectedMeeting?.meetURL.absoluteString, "https://meet.google.com/abc-defg-hij")
    }

    func testSelectedMeetingKeepsMultipleMeetLinks() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Planning https://meet.google.com/title-room-abc",
            startDate: now.addingTimeInterval(60),
            now: now,
            url: URL(string: "https://meet.google.com/url-room-abc"),
            notes: "Notes https://meet.google.com/notes-room-abc duplicate https://meet.google.com/url-room-abc",
            location: "Room https://meet.google.com/location-room-abc"
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertEqual(selectedMeeting?.meetURL.absoluteString, "https://meet.google.com/url-room-abc")
        XCTAssertEqual(selectedMeeting?.meetLinks.map(\.absoluteString), [
            "https://meet.google.com/url-room-abc",
            "https://meet.google.com/notes-room-abc",
            "https://meet.google.com/location-room-abc",
            "https://meet.google.com/title-room-abc"
        ])
    }

    func testDoesNotShowDeclinedEvent() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Declined planning",
            startDate: now.addingTimeInterval(60),
            now: now,
            participationStatus: .declined
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertNil(selectedMeeting)
    }

    func testDoesNotShowHiddenEvent() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Planning",
            startDate: now.addingTimeInterval(60),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: ["event-1"])

        XCTAssertNil(selectedMeeting)
    }

    func testDoesNotShowEventBeforeAlertWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Later planning",
            startDate: now.addingTimeInterval(61),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertNil(selectedMeeting)
    }

    func testDoesNotShowEventThatStartedTooLongAgo() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Already started",
            startDate: now.addingTimeInterval(-25 * 60),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60, lateAlertGraceTime: 120)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertNil(selectedMeeting)
    }

    func testShowsEventThatJustStarted() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "Just started",
            startDate: now.addingTimeInterval(-30),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60, lateAlertGraceTime: 120)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertEqual(selectedMeeting?.eventID, "event-1")
    }

    func testShowsInProgressMeetEventInsideLateAlertGraceWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "event-1",
            title: "In progress",
            startDate: now.addingTimeInterval(-119),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60, lateAlertGraceTime: 120)
            .meetingToShow(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertEqual(selectedMeeting?.eventID, "event-1")
    }

    func testShowsUpcomingMeetEventWhenOlderMeetIsStillInProgress() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let oldInProgressEvent = makeEvent(
            id: "old-meet",
            title: "Old Meet",
            startDate: now.addingTimeInterval(-9 * 60),
            now: now
        )
        let upcomingEvent = makeEvent(
            id: "next-meet",
            title: "Next Meet",
            startDate: now.addingTimeInterval(60),
            now: now
        )

        let selectedMeeting = MeetingAlertSelector(alertLeadTime: 60, lateAlertGraceTime: 120)
            .meetingToShow(now: now, events: [oldInProgressEvent, upcomingEvent], hiddenEventIDs: [])

        XCTAssertEqual(selectedMeeting?.eventID, "next-meet")
    }

    private func makeEvent(
        id: String,
        title: String,
        startDate: Date,
        now: Date,
        participationStatus: EventParticipationStatus = .accepted,
        url: URL? = nil,
        notes: String? = "https://meet.google.com/abc-defg-hij",
        location: String? = nil
    ) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: id,
            title: title,
            startDate: startDate,
            endDate: now.addingTimeInterval(3_600),
            isAllDay: false,
            participationStatus: participationStatus,
            url: url,
            notes: notes,
            location: location
        )
    }
}
