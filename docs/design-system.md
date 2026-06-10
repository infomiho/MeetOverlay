# MeetOverlay Design System

MeetOverlay uses a native macOS utility style: quiet settings, clear calendar hierarchy, and a high-contrast reminder overlay.

## Principles

- Use platform controls, SF Symbols, system fonts, and semantic system colors.
- Use bright yellow (`#ffcc00`) for primary emphasis.
- Keep Settings calm and compact.
- Make the fullscreen overlay unmistakable and legible.
- Avoid decorative labels or visual elements that do not help the user join, dismiss, or understand the meeting.
- Give the overlay one hierarchy: countdown, meeting title, time, actions.
- Prefer one metadata line over separate metric cards unless the data needs comparison.
- Keep secondary actions visually lighter than the join action.
- Add new UI through `MeetOverlayTheme` tokens before introducing new ad-hoc styling.

## Tokens

- Colors: semantic macOS backgrounds, text, separators, warnings, and a bright yellow accent.
- Surfaces: card, inset list, overlay panel.
- Typography: system hierarchy for Settings, large system type for overlay.
- Spacing: shared small, medium, large, card, page, and overlay spacing.
- Radius: icon badge, inset, card, and overlay panel radii.

## Usage

- Settings cards use the shared card surface and icon badge treatment.
- Calendar lists use the shared inset surface.
- The overlay uses a fixed dark backdrop, bright yellow emphasis, a compact panel, and a single action row.
- The overlay panel appears on the active screen only; other displays get a light scrim so reference material stays readable.
- The overlay countdown turns to the attention color once the meeting has started.
- Menu bar urgency uses the dynamic urgent color so it stays legible in light and dark menu bars.
