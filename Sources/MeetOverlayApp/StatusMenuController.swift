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

        menu.autoenablesItems = false
        statusItem.button?.font = MenuStyle.menuBarTitleFont
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
        statusItem.button?.contentTintColor = menuBarUrgency == .urgent ? MeetOverlayTheme.Palette.menuBarUrgentColor : nil
        statusItem.button?.toolTip = nextMeetingSummary() ?? status
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
            let timeColumnWidth = timeColumnWidth()
            for section in sections {
                addSection(section, timeColumnWidth: timeColumnWidth)
            }
        }

        menu.addItem(.separator())
        menu.addItem(preferencesItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    private func addSection(_ section: CalendarMenuSection, timeColumnWidth: CGFloat) {
        let headerItem = NSMenuItem.sectionHeader(title: section.title)
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        for row in section.rows {
            let item = NSMenuItem(title: "", action: nil, keyEquivalent: "")
            item.attributedTitle = attributedTitle(for: row, timeColumnWidth: timeColumnWidth)
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

    private func attributedTitle(for row: CalendarMenuRow, timeColumnWidth: CGFloat) -> NSAttributedString {
        let titleFont = row.phase == .inProgress ? MenuStyle.inProgressTitleFont : MenuStyle.rowTitleFont
        let titleColor: NSColor? = row.phase == .ended ? MenuStyle.rowDetailColor : nil
        let statusColor = row.phase == .inProgress ? MenuStyle.rowUrgentColor : MenuStyle.rowDetailColor

        let title = NSMutableAttributedString()
        title.append(NSAttributedString(
            string: "\(row.timeText)\t",
            attributes: attributes(font: MenuStyle.rowDigitFont, color: MenuStyle.rowDetailColor)
        ))
        title.append(NSAttributedString(
            string: row.title,
            attributes: attributes(font: titleFont, color: titleColor)
        ))

        if let statusText = row.statusText {
            title.append(NSAttributedString(
                string: "  \(statusText)",
                attributes: attributes(font: MenuStyle.rowDigitFont, color: statusColor)
            ))
        }

        if row.meetLinks.count > 1 {
            title.append(NSAttributedString(
                string: "  \(row.meetLinks.count) Meet links",
                attributes: attributes(font: MenuStyle.rowDigitFont, color: MenuStyle.rowDetailColor)
            ))
        }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: timeColumnWidth + MenuStyle.timeColumnGap)]
        title.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: title.length))

        return title
    }

    private func attributes(font: NSFont, color: NSColor?) -> [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [.font: font]

        if let color {
            attributes[.foregroundColor] = color
        }

        return attributes
    }

    private func timeColumnWidth() -> CGFloat {
        let widths = sections.flatMap(\.rows).map { row in
            (row.timeText as NSString).size(withAttributes: [.font: MenuStyle.rowDigitFont]).width
        }

        return (widths.max() ?? 0).rounded(.up)
    }

    private func nextMeetingSummary() -> String? {
        guard let section = sections.first, let row = section.rows.first else {
            return nil
        }

        var summary = "\(section.title): \(row.title), \(row.timeText)"

        if let statusText = row.statusText {
            summary += " (\(statusText))"
        }

        return summary
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

    @MainActor
    private enum MenuStyle {
        static let menuBarTitleFont = NSFont.monospacedDigitSystemFont(
            ofSize: NSFont.menuBarFont(ofSize: 0).pointSize,
            weight: .regular
        )
        static let rowTitleFont = NSFont.menuFont(ofSize: 0)
        static let inProgressTitleFont = NSFont.systemFont(ofSize: rowTitleFont.pointSize, weight: .semibold)
        static let rowDigitFont = NSFont.monospacedDigitSystemFont(ofSize: rowTitleFont.pointSize, weight: .regular)
        static let rowDetailColor = NSColor.secondaryLabelColor
        static let rowUrgentColor = MeetOverlayTheme.Palette.menuBarUrgentColor
        static let timeColumnGap: CGFloat = 10
    }
}
