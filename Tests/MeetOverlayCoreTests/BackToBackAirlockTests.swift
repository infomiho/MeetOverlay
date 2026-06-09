import XCTest
@testable import MeetOverlayCore

final class BackToBackAirlockTests: XCTestCase {
    func testDetectsNextMeetingSoonAfterCurrentMeeting() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let current = makeEvent(
            id: "current",
            title: "Current Meet",
            startDate: now.addingTimeInterval(-55 * 60),
            endDate: now.addingTimeInterval(60)
        )
        let next = makeEvent(
            id: "next",
            title: "Next Meet",
            startDate: now.addingTimeInterval(3 * 60),
            endDate: now.addingTimeInterval(33 * 60)
        )

        let transition = BackToBackAirlock(transitionLeadTime: 5 * 60, maximumGap: 10 * 60)
            .transition(now: now, events: [current, next], hiddenEventIDs: [], dismissedTransitionEventIDs: [])

        XCTAssertEqual(transition?.currentEventID, "current")
        XCTAssertEqual(transition?.nextMeeting.eventID, "next")
        XCTAssertEqual(transition?.nextMeeting.title, "Next Meet")
    }

    func testDoesNotDetectMeetingOutsideBackToBackGap() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let current = makeEvent(
            id: "current",
            title: "Current Meet",
            startDate: now.addingTimeInterval(-55 * 60),
            endDate: now.addingTimeInterval(60)
        )
        let later = makeEvent(
            id: "later",
            title: "Later Meet",
            startDate: now.addingTimeInterval(20 * 60),
            endDate: now.addingTimeInterval(50 * 60)
        )

        let transition = BackToBackAirlock(transitionLeadTime: 30 * 60, maximumGap: 10 * 60)
            .transition(now: now, events: [current, later], hiddenEventIDs: [], dismissedTransitionEventIDs: [])

        XCTAssertNil(transition)
    }

    func testIgnoresInvalidNextEvents() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let current = makeEvent(
            id: "current",
            title: "Current Meet",
            startDate: now.addingTimeInterval(-55 * 60),
            endDate: now.addingTimeInterval(60)
        )
        let allDay = makeEvent(
            id: "all-day",
            title: "All Day Meet",
            startDate: now.addingTimeInterval(3 * 60),
            endDate: now.addingTimeInterval(33 * 60),
            isAllDay: true
        )
        let declined = makeEvent(
            id: "declined",
            title: "Declined Meet",
            startDate: now.addingTimeInterval(3 * 60),
            endDate: now.addingTimeInterval(33 * 60),
            participationStatus: .declined
        )
        let nonMeet = makeEvent(
            id: "non-meet",
            title: "Non Meet",
            startDate: now.addingTimeInterval(3 * 60),
            endDate: now.addingTimeInterval(33 * 60),
            notes: nil
        )
        let finished = makeEvent(
            id: "finished",
            title: "Finished Meet",
            startDate: now.addingTimeInterval(-30 * 60),
            endDate: now.addingTimeInterval(-10 * 60)
        )

        let transition = BackToBackAirlock(transitionLeadTime: 5 * 60, maximumGap: 10 * 60)
            .transition(now: now, events: [current, allDay, declined, nonMeet, finished], hiddenEventIDs: [], dismissedTransitionEventIDs: [])

        XCTAssertNil(transition)
    }

    func testDismissedTransitionDoesNotSuppressFutureReminder() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let current = makeEvent(
            id: "current",
            title: "Current Meet",
            startDate: now.addingTimeInterval(-55 * 60),
            endDate: now.addingTimeInterval(60)
        )
        let next = makeEvent(
            id: "next",
            title: "Next Meet",
            startDate: now.addingTimeInterval(3 * 60),
            endDate: now.addingTimeInterval(33 * 60)
        )
        var state = MeetingReminderState()
        state.dismissAirlock(eventID: "next")

        let transition = BackToBackAirlock(transitionLeadTime: 5 * 60, maximumGap: 10 * 60)
            .transition(now: now, events: [current, next], hiddenEventIDs: state.hiddenEventIDs(now: now), dismissedTransitionEventIDs: state.dismissedAirlockEventIDs)

        XCTAssertNil(transition)
        XCTAssertEqual(state.hiddenEventIDs(now: now), [])
    }

    func testHandledCurrentMeetingCanStillTriggerTransition() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let current = makeEvent(
            id: "current",
            title: "Current Meet",
            startDate: now.addingTimeInterval(-55 * 60),
            endDate: now.addingTimeInterval(60)
        )
        let next = makeEvent(
            id: "next",
            title: "Next Meet",
            startDate: now.addingTimeInterval(3 * 60),
            endDate: now.addingTimeInterval(33 * 60)
        )
        var state = MeetingReminderState()
        state.join(eventID: "current")

        let transition = BackToBackAirlock(transitionLeadTime: 5 * 60, maximumGap: 10 * 60)
            .transition(now: now, events: [current, next], hiddenEventIDs: state.hiddenEventIDs(now: now), dismissedTransitionEventIDs: [])

        XCTAssertEqual(transition?.currentEventID, "current")
        XCTAssertEqual(transition?.nextMeeting.eventID, "next")
    }

    private func makeEvent(
        id: String,
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        participationStatus: EventParticipationStatus = .accepted,
        notes: String? = "https://meet.google.com/abc-defg-hij"
    ) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: id,
            title: title,
            startDate: startDate,
            endDate: endDate,
            isAllDay: isAllDay,
            participationStatus: participationStatus,
            url: nil,
            notes: notes,
            location: nil
        )
    }
}
