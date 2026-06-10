import XCTest
@testable import MeetOverlayCore

final class MeetingReminderStateTests: XCTestCase {
    func testSnoozedEventIsHiddenUntilSnoozeExpires() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        var state = MeetingReminderState()

        state.snooze(eventID: "planning", until: now.addingTimeInterval(60))

        XCTAssertEqual(state.hiddenEventIDs(now: now.addingTimeInterval(59)), ["planning"])
        XCTAssertEqual(state.hiddenEventIDs(now: now.addingTimeInterval(60)), [])
    }

    func testDismissedEventStaysHidden() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        var state = MeetingReminderState()

        state.dismiss(eventID: "planning")

        XCTAssertEqual(state.hiddenEventIDs(now: now), ["planning"])
        XCTAssertEqual(state.hiddenEventIDs(now: now.addingTimeInterval(60 * 60)), ["planning"])
    }

    func testJoinedEventStaysHidden() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        var state = MeetingReminderState()

        state.join(eventID: "planning")

        XCTAssertEqual(state.hiddenEventIDs(now: now), ["planning"])
        XCTAssertEqual(state.hiddenEventIDs(now: now.addingTimeInterval(60 * 60)), ["planning"])
    }

    func testJoinClearsActiveSnooze() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        var state = MeetingReminderState()

        state.snooze(eventID: "planning", until: now.addingTimeInterval(60))
        state.join(eventID: "planning")

        XCTAssertEqual(state.hiddenEventIDs(now: now.addingTimeInterval(60)), ["planning"])
    }

    func testSnoozeAllowsDeliveringTheSameStageAgain() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        var state = MeetingReminderState()

        state.recordDelivery(eventID: "planning", stage: .fullscreen)
        state.snooze(eventID: "planning", until: now.addingTimeInterval(60))

        XCTAssertTrue(state.shouldDeliver(eventID: "planning", stage: .fullscreen))
    }

    func testExpiredSnoozeIsTrackedUntilEventIsHandled() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        var state = MeetingReminderState()

        state.snooze(eventID: "planning", until: now.addingTimeInterval(60))

        _ = state.hiddenEventIDs(now: now)
        XCTAssertEqual(state.expiredSnoozeEventIDs, [])

        _ = state.hiddenEventIDs(now: now.addingTimeInterval(60))
        XCTAssertEqual(state.expiredSnoozeEventIDs, ["planning"])

        state.dismiss(eventID: "planning")
        XCTAssertEqual(state.expiredSnoozeEventIDs, [])
    }

    func testSnoozingAgainClearsExpiredSnoozeTracking() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        var state = MeetingReminderState()

        state.snooze(eventID: "planning", until: now.addingTimeInterval(60))
        _ = state.hiddenEventIDs(now: now.addingTimeInterval(60))

        state.snooze(eventID: "planning", until: now.addingTimeInterval(120))

        XCTAssertEqual(state.expiredSnoozeEventIDs, [])
        XCTAssertEqual(state.hiddenEventIDs(now: now.addingTimeInterval(90)), ["planning"])
    }

    func testDoesNotDeliverSameAlertStageTwice() throws {
        var state = MeetingReminderState()

        XCTAssertTrue(state.shouldDeliver(eventID: "planning", stage: .gentle))
        state.recordDelivery(eventID: "planning", stage: .gentle)

        XCTAssertFalse(state.shouldDeliver(eventID: "planning", stage: .gentle))
        XCTAssertTrue(state.shouldDeliver(eventID: "planning", stage: .fullscreen))
    }
}
