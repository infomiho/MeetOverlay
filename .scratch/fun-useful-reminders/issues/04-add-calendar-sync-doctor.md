# Add a Calendar Sync Doctor

Type: AFK
Status: Done

## What to build

Add a diagnostics section in Settings that tells the user whether MeetOverlay is ready to catch meetings. The slice should focus on trust: Calendar access, selected calendar coverage, launch-at-login state, and the next detected Google Meet event.

## Acceptance criteria

- [x] Settings show Calendar permission status in plain language.
- [x] Settings show whether all calendars, some calendars, or no calendars are included.
- [x] Settings show launch-at-login status using the existing startup state.
- [x] Settings show the next detected Google Meet event when one is available.
- [x] The diagnostics state handles denied Calendar access, no calendars, and no upcoming Meet events gracefully.
- [x] Tests cover the diagnostic summary logic without requiring live Calendar access.

## Blocked by

None - can start immediately
