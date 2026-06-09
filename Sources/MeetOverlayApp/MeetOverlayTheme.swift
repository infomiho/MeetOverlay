import AppKit
import SwiftUI

enum MeetOverlayTheme {
    enum Palette {
        static let accentColor = NSColor(red: 1, green: 0.8, blue: 0, alpha: 1)
        static let accent = Color(nsColor: accentColor)
        static let settingsBackground = Color(nsColor: .windowBackgroundColor)
        static let cardBackground = Color(nsColor: .controlBackgroundColor)
        static let insetBackground = Color(nsColor: .textBackgroundColor).opacity(0.42)
        static let iconBadgeBackground = accent.opacity(0.16)
        static let border = Color(nsColor: .separatorColor).opacity(0.35)
        static let mutedBorder = Color(nsColor: .separatorColor).opacity(0.24)
        static let warning = Color(nsColor: .systemRed)
        static let attention = Color(nsColor: .systemOrange)

        static let overlayStart = Color.black.opacity(0.93)
        static let overlayEnd = Color(red: 0.025, green: 0.035, blue: 0.055).opacity(0.98)
        static let overlayPanel = Color.white.opacity(0.08)
        static let overlayPanelBorder = Color.white.opacity(0.14)
        static let overlayText = Color.white
        static let overlaySecondaryText = Color.white.opacity(0.72)
        static let overlayTertiaryText = Color.white.opacity(0.52)
    }

    enum Spacing {
        static let xSmall: CGFloat = 6
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 20
        static let page: CGFloat = 16
        static let card: CGFloat = 16
        static let overlayContent: CGFloat = 24
        static let overlayPanelHorizontal: CGFloat = 56
        static let overlayPanelVertical: CGFloat = 44
    }

    enum Radius {
        static let iconBadge: CGFloat = 7
        static let inset: CGFloat = 12
        static let card: CGFloat = 16
        static let overlayPanel: CGFloat = 28
    }

    enum Size {
        static let settingsIconBadge: CGFloat = 22
    }

    enum Typography {
        static let pageTitle = Font.title2.weight(.semibold)
        static let sectionTitle = Font.headline
        static let helper = Font.footnote
        static let overlayStatus = Font.system(size: 28, weight: .semibold)
        static let overlayTitle = Font.system(size: 54, weight: .bold)
        static let overlayMetadata = Font.system(size: 19, weight: .medium)
        static let overlayButton = Font.system(size: 20, weight: .semibold)
        static let overlaySecondaryButton = Font.system(size: 18, weight: .semibold)
        static let overlayHint = Font.system(size: 15, weight: .medium)
    }
}
