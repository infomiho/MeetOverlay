import XCTest
@testable import MeetOverlayCore

final class CalendarEventOccurrenceIDTests: XCTestCase {
    func testOccurrencesOfRecurringEventGetDistinctIDs() throws {
        let firstOccurrence = CalendarEventOccurrenceID.make(
            eventIdentifier: "standup",
            calendarItemIdentifier: "item",
            startDate: Date(timeIntervalSinceReferenceDate: 1_000)
        )
        let nextOccurrence = CalendarEventOccurrenceID.make(
            eventIdentifier: "standup",
            calendarItemIdentifier: "item",
            startDate: Date(timeIntervalSinceReferenceDate: 1_000 + 24 * 60 * 60)
        )

        XCTAssertNotEqual(firstOccurrence, nextOccurrence)
    }

    func testFallsBackToCalendarItemIdentifierWithoutEventIdentifier() throws {
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000)

        let withNilIdentifier = CalendarEventOccurrenceID.make(
            eventIdentifier: nil,
            calendarItemIdentifier: "item-a",
            startDate: startDate
        )
        let withEmptyIdentifier = CalendarEventOccurrenceID.make(
            eventIdentifier: "",
            calendarItemIdentifier: "item-b",
            startDate: startDate
        )

        XCTAssertTrue(withNilIdentifier.hasPrefix("item-a"))
        XCTAssertTrue(withEmptyIdentifier.hasPrefix("item-b"))
    }

    func testSameOccurrenceAlwaysGetsTheSameID() throws {
        let startDate = Date(timeIntervalSinceReferenceDate: 1_000)

        XCTAssertEqual(
            CalendarEventOccurrenceID.make(eventIdentifier: "standup", calendarItemIdentifier: "item", startDate: startDate),
            CalendarEventOccurrenceID.make(eventIdentifier: "standup", calendarItemIdentifier: "item", startDate: startDate)
        )
    }
}
