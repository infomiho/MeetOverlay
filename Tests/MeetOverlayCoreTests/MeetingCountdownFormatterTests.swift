import XCTest
@testable import MeetOverlayCore

final class MeetingCountdownFormatterTests: XCTestCase {
    func testShowsRoundedUpMinutesBeforeStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(119)),
            "Starts in 2m"
        )
    }

    func testShowsSingularMinuteBeforeStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(60)),
            "Starts in 1m"
        )
    }

    func testShowsHoursAndRemainingMinutesBeforeStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(112 * 60)),
            "Starts in 1h 52m"
        )
    }

    func testShowsSingularHourBeforeStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(60 * 60)),
            "Starts in 1h"
        )
    }

    func testShowsSecondsNearStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(30)),
            "Starts in 30s"
        )
    }

    func testShowsStartedTextAfterStart() throws {
        let now = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            MeetingCountdownFormatter.text(now: now, startDate: now.addingTimeInterval(-90)),
            "Started 2m ago"
        )
    }
}
