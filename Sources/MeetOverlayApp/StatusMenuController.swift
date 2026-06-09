import AppKit
import MeetOverlayCore

@MainActor
final class StatusMenuController: NSObject {
    var onOpenPreferences: (() -> Void)?
    var onOpenCalendarSettings: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private let preferencesItem = NSMenuItem(title: "Settings...", action: #selector(openPreferences), keyEquivalent: ",")
    private let calendarSettingsItem = NSMenuItem(title: "Open Calendar Privacy Settings...", action: #selector(openCalendarSettings), keyEquivalent: "")

    private var sections: [CalendarMenuSection] = []
    private var emptyMessage = "No events today or tomorrow"
    private var showsCalendarSettingsAction = false

    override init() {
        super.init()

        statusItem.button?.title = "Meet"
        statusItem.button?.setAccessibilityLabel("MeetOverlay")
        statusItem.button?.setAccessibilityHelp("Opens upcoming calendar events and meeting reminder settings.")
        preferencesItem.target = self
        calendarSettingsItem.target = self

        statusItem.menu = menu
        rebuildMenu()
    }

    func update(
        status: String,
        isEnabled: Bool,
        menuBarTitle: String = "Meet",
        menuBarUrgency: CalendarMenuBarUrgency = .idle,
        sections: [CalendarMenuSection] = [],
        emptyMessage: String = "No events today or tomorrow",
        showsCalendarSettingsAction: Bool = false
    ) {
        self.sections = sections
        self.emptyMessage = emptyMessage
        self.showsCalendarSettingsAction = showsCalendarSettingsAction
        statusItem.button?.title = menuBarTitle
        statusItem.button?.contentTintColor = menuBarUrgency == .urgent ? MeetOverlayTheme.Palette.accentColor : nil
        statusItem.button?.setAccessibilityLabel("MeetOverlay, \(menuBarTitle), \(status). Opens meeting menu.")
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        if sections.isEmpty {
            let emptyItem = NSMenuItem(title: emptyMessage, action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
            if showsCalendarSettingsAction {
                menu.addItem(calendarSettingsItem)
            }
        } else {
            for section in sections {
                addSection(section)
            }
        }

        menu.addItem(.separator())
        menu.addItem(preferencesItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func addSection(_ section: CalendarMenuSection) {
        let headerItem = NSMenuItem(title: section.title, action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        for row in section.rows {
            let title = title(for: row)
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            item.image = NSImage(
                systemSymbolName: row.hasMeetLink ? "video.fill" : "calendar",
                accessibilityDescription: row.hasMeetLink ? "Google Meet link" : "Calendar event"
            )

            if row.meetLinks.count > 1 {
                item.submenu = meetLinksMenu(for: row.meetLinks)
            } else if let meetURL = row.meetURL {
                item.action = #selector(openMeetLink)
                item.target = self
                item.representedObject = meetURL
            } else {
                item.isEnabled = true
            }

            menu.addItem(item)
        }
    }

    private func meetLinksMenu(for links: [URL]) -> NSMenu {
        let submenu = NSMenu()

        for (index, link) in links.enumerated() {
            let linkNumber = index + 1
            let label = "\(linkNumber): \(GoogleMeetLinkFormatter.roomCode(for: link))"
            submenu.addItem(meetLinkItem(title: "Open \(label)", action: #selector(openMeetLink), link: link))
            submenu.addItem(meetLinkItem(title: "Copy \(label)", action: #selector(copyMeetLink), link: link))
        }

        return submenu
    }

    private func meetLinkItem(title: String, action: Selector, link: URL) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.representedObject = link
        return item
    }

    private func title(for row: CalendarMenuRow) -> String {
        let title = "\(row.timeText)  \(row.title)"
        var details: [String] = []

        if let statusText = row.statusText {
            details.append(statusText)
        }

        if row.meetLinks.count > 1 {
            details.append("\(row.meetLinks.count) Meet links")
        }

        return details.isEmpty ? title : "\(title) - \(details.joined(separator: ", "))"
    }

    @objc private func openPreferences() {
        onOpenPreferences?()
    }

    @objc private func openCalendarSettings() {
        onOpenCalendarSettings?()
    }

    @objc private func openMeetLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func copyMeetLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url.absoluteString, forType: .string)
    }
}
