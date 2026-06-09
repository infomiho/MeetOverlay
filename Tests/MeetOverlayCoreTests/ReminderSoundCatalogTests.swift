import XCTest
@testable import MeetOverlayCore

final class ReminderSoundCatalogTests: XCTestCase {
    func testResolvesSelectedSound() throws {
        let sound = ReminderSoundCatalog.sound(for: "soft-chime")

        XCTAssertEqual(sound.id, "soft-chime")
        XCTAssertEqual(sound.resourceName, "notification-soft")
        XCTAssertEqual(sound.fileExtension, "wav")
    }

    func testUnknownSoundFallsBackToDefault() throws {
        XCTAssertEqual(ReminderSoundCatalog.sound(for: "missing"), ReminderSoundCatalog.defaultSound)
    }

    func testSoundIDsAreUnique() throws {
        let ids = ReminderSoundCatalog.sounds.map(\.id)

        XCTAssertEqual(Set(ids).count, ids.count)
    }
}
