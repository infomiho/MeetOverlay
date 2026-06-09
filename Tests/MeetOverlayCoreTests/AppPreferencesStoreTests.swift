import XCTest
@testable import MeetOverlayCore

final class AppPreferencesStoreTests: XCTestCase {
    func testLoadsDefaultsWhenNothingWasSaved() throws {
        let defaults = makeDefaults()
        let store = AppPreferencesStore(defaults: defaults)

        let preferences = store.load()

        XCTAssertNil(preferences.selectedCalendarIDs)
        XCTAssertTrue(preferences.isOverlayEnabled)
        XCTAssertFalse(preferences.launchAtLogin)
        XCTAssertTrue(preferences.hidesFinishedEvents)
        XCTAssertEqual(preferences.reminderSoundID, ReminderSoundCatalog.defaultSound.id)
    }

    func testPersistsPreferences() throws {
        let defaults = makeDefaults()
        let store = AppPreferencesStore(defaults: defaults)
        let savedPreferences = AppPreferences(
            selectedCalendarIDs: ["work", "personal"],
            isOverlayEnabled: false,
            launchAtLogin: true,
            hidesFinishedEvents: false,
            reminderSoundID: "soft-chime"
        )

        store.save(savedPreferences)

        XCTAssertEqual(store.load(), savedPreferences)
    }

    func testLoadsOldSavedPreferencesWithHideFinishedEventsEnabled() throws {
        let defaults = makeDefaults()
        let oldSavedPreferences = """
        {
          "selectedCalendarIDs": ["work"],
          "isOverlayEnabled": false,
          "launchAtLogin": true
        }
        """.data(using: .utf8)!
        defaults.set(oldSavedPreferences, forKey: "appPreferences")

        let preferences = AppPreferencesStore(defaults: defaults).load()

        XCTAssertEqual(preferences.selectedCalendarIDs, ["work"])
        XCTAssertFalse(preferences.isOverlayEnabled)
        XCTAssertTrue(preferences.launchAtLogin)
        XCTAssertTrue(preferences.hidesFinishedEvents)
        XCTAssertEqual(preferences.reminderSoundID, ReminderSoundCatalog.defaultSound.id)
    }

    func testLoadsUnknownReminderSoundAsDefault() throws {
        let defaults = makeDefaults()
        let savedPreferences = """
        {
          "reminderSoundID": "missing"
        }
        """.data(using: .utf8)!
        defaults.set(savedPreferences, forKey: "appPreferences")

        let preferences = AppPreferencesStore(defaults: defaults).load()

        XCTAssertEqual(preferences.reminderSoundID, ReminderSoundCatalog.defaultSound.id)
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "MeetOverlayTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
