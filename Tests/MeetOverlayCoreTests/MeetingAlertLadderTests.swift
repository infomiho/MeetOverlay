import XCTest
@testable import MeetOverlayCore

final class MeetingAlertLadderTests: XCTestCase {
    func testSelectsGentleStageBeforeFullscreenWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "planning",
            title: "Planning",
            startDate: now.addingTimeInterval(5 * 60),
            now: now
        )

        let alert = MeetingAlertLadder(gentleLeadTime: 5 * 60, fullscreenLeadTime: 60)
            .alert(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertEqual(alert?.stage, .gentle)
        XCTAssertEqual(alert?.meeting.eventID, "planning")
    }

    func testEscalatesToFullscreenInsideFullscreenWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "planning",
            title: "Planning",
            startDate: now.addingTimeInterval(60),
            now: now
        )

        let alert = MeetingAlertLadder(gentleLeadTime: 5 * 60, fullscreenLeadTime: 60)
            .alert(now: now, events: [event], hiddenEventIDs: [])

        XCTAssertEqual(alert?.stage, .fullscreen)
        XCTAssertEqual(alert?.meeting.eventID, "planning")
    }

    func testSnoozedEventDoesNotAlertDuringSnoozeWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "planning",
            title: "Planning",
            startDate: now.addingTimeInterval(60),
            now: now
        )
        var state = MeetingReminderState()
        state.snooze(eventID: "planning", until: now.addingTimeInterval(5 * 60))

        let alert = MeetingAlertLadder(gentleLeadTime: 5 * 60, fullscreenLeadTime: 60)
            .alert(now: now, events: [event], hiddenEventIDs: state.hiddenEventIDs(now: now))

        XCTAssertNil(alert)
    }

    func testLateAlertExemptEventStillAlertsPastGraceWindow() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = makeEvent(
            id: "planning",
            title: "Planning",
            startDate: now.addingTimeInterval(-4 * 60),
            now: now
        )
        let ladder = MeetingAlertLadder(gentleLeadTime: 5 * 60, fullscreenLeadTime: 60, lateAlertGraceTime: 120)

        XCTAssertNil(ladder.alert(now: now, events: [event], hiddenEventIDs: []))

        let alert = ladder.alert(
            now: now,
            events: [event],
            hiddenEventIDs: [],
            lateAlertExemptEventIDs: ["planning"]
        )

        XCTAssertEqual(alert?.stage, .fullscreen)
        XCTAssertEqual(alert?.meeting.eventID, "planning")
    }

    func testLateAlertExemptEventDoesNotAlertAfterItEnds() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let event = CalendarEventSnapshot(
            id: "planning",
            title: "Planning",
            startDate: now.addingTimeInterval(-30 * 60),
            endDate: now.addingTimeInterval(-60),
            isAllDay: false,
            participationStatus: .accepted,
            url: nil,
            notes: "https://meet.google.com/abc-defg-hij",
            location: nil
        )
        let ladder = MeetingAlertLadder(gentleLeadTime: 5 * 60, fullscreenLeadTime: 60, lateAlertGraceTime: 120)

        let alert = ladder.alert(
            now: now,
            events: [event],
            hiddenEventIDs: [],
            lateAlertExemptEventIDs: ["planning"]
        )

        XCTAssertNil(alert)
    }

    func testJoinedOrDismissedEventsDoNotAlert() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let joinedEvent = makeEvent(
            id: "joined",
            title: "Joined",
            startDate: now.addingTimeInterval(60),
            now: now
        )
        let dismissedEvent = makeEvent(
            id: "dismissed",
            title: "Dismissed",
            startDate: now.addingTimeInterval(60),
            now: now
        )
        var state = MeetingReminderState()
        state.join(eventID: "joined")
        state.dismiss(eventID: "dismissed")

        let alert = MeetingAlertLadder(gentleLeadTime: 5 * 60, fullscreenLeadTime: 60)
            .alert(now: now, events: [joinedEvent, dismissedEvent], hiddenEventIDs: state.hiddenEventIDs(now: now))

        XCTAssertNil(alert)
    }

    private func makeEvent(
        id: String,
        title: String,
        startDate: Date,
        now: Date,
        participationStatus: EventParticipationStatus = .accepted
    ) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: id,
            title: title,
            startDate: startDate,
            endDate: now.addingTimeInterval(3_600),
            isAllDay: false,
            participationStatus: participationStatus,
            url: nil,
            notes: "https://meet.google.com/abc-defg-hij",
            location: nil
        )
    }
}
