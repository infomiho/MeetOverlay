import XCTest
@testable import MeetOverlayCore

final class GoogleMeetLinkFinderTests: XCTestCase {
    func testFindsMeetLinkInEventText() throws {
        let text = "Join with Google Meet: https://meet.google.com/abc-defg-hij"

        let url = GoogleMeetLinkFinder.firstLink(in: [text])

        XCTAssertEqual(url?.absoluteString, "https://meet.google.com/abc-defg-hij")
    }

    func testFindsUniqueMeetLinksAcrossEventFields() throws {
        let links = GoogleMeetLinkFinder.links(in: [
            "https://meet.google.com/abc-defg-hij",
            "Notes include https://meet.google.com/xyz-abcd-efg and duplicate https://meet.google.com/abc-defg-hij",
            "Location https://meet.google.com/xyz-abcd-efg",
            "Title without link"
        ])

        XCTAssertEqual(links.map(\.absoluteString), [
            "https://meet.google.com/abc-defg-hij",
            "https://meet.google.com/xyz-abcd-efg"
        ])
    }

    func testDeduplicatesMeetLinksWithQueryFragmentAndTrailingSlash() throws {
        let links = GoogleMeetLinkFinder.links(in: [
            "https://meet.google.com/abc-defg-hij?authuser=0#chat",
            "https://meet.google.com/abc-defg-hij/",
            "https://meet.google.com/abc-defg-hij"
        ])

        XCTAssertEqual(links.map(\.absoluteString), [
            "https://meet.google.com/abc-defg-hij?authuser=0#chat"
        ])
    }
}
