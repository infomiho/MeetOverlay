import AppKit
import MeetOverlayCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitorController: MeetingMonitorController?
    private var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusMenu = StatusMenuController()
        let calendarEventSource = CalendarEventSource()
        let overlayPresenter = OverlayPresenter()
        let preferencesStore = AppPreferencesStore()
        let loginItemController = LoginItemController()

        let monitorController = MeetingMonitorController(
            calendarEventSource: calendarEventSource,
            overlayPresenter: overlayPresenter,
            statusMenu: statusMenu,
            preferencesStore: preferencesStore
        )
        let preferencesWindowController = PreferencesWindowController(
            calendarEventSource: calendarEventSource,
            preferencesStore: preferencesStore,
            loginItemController: loginItemController,
            onPreferencesChanged: { [weak monitorController] in
                monitorController?.refreshFromPreferences()
            },
            onPreviewReminder: { [weak monitorController] in
                monitorController?.previewReminder()
            }
        )

        statusMenu.onOpenPreferences = { [weak preferencesWindowController] in
            preferencesWindowController?.show()
        }

        self.monitorController = monitorController
        self.preferencesWindowController = preferencesWindowController
        monitorController.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
