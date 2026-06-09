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

    func testDoesNotDeliverSameAlertStageTwice() throws {
        var state = MeetingReminderState()

        XCTAssertTrue(state.shouldDeliver(eventID: "planning", stage: .gentle))
        state.recordDelivery(eventID: "planning", stage: .gentle)

        XCTAssertFalse(state.shouldDeliver(eventID: "planning", stage: .gentle))
        XCTAssertTrue(state.shouldDeliver(eventID: "planning", stage: .fullscreen))
    }
}
