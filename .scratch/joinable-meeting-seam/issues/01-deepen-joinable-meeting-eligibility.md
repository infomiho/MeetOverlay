# Deepen joinable-meeting eligibility into one seam

Type: AFK
Status: Done

## What to build

The rule for a [Joinable Meeting](../../../CONTEXT.md) (not all-day, not declined, has a Meet Link) was reimplemented at six sites in `MeetOverlayCore.swift`. The reimplementations disagreed: `CalendarMenuPresenter.menuBarPresentation` and `highlightSections` omitted the declined check, so a meeting the user declined still drove the menu bar countdown (urgent yellow) and the Happening Now / Next Up highlights, while the Alert Ladder, Alert Selector, Back-to-back Airlock, and Calendar Sync Doctor all skipped it.

Capture the eligibility rule in one seam and route every site through it. Fixing the menu-bar leak then falls out of the deepening.

## Acceptance criteria

- [x] `JoinableMeeting.from(_:)` is the single place that decides joinability; it returns nil for all-day, declined, and link-less events.
- [x] Meet Link derivation lives in one place, `CalendarEventSnapshot.meetLinks`; the duplicated field extraction is gone.
- [x] The Alert Ladder, Alert Selector, Back-to-back Airlock, Calendar Sync Doctor, and menu presenter all consume the seam.
- [x] A declined meeting no longer drives the menu bar title or the Happening Now / Next Up highlights.
- [x] A declined meeting still appears in the neutral Today's / Tomorrow's agenda list.
- [x] Tentative and unknown participation stay joinable; only declined is excluded.
- [x] Tests cover the seam directly and the menu-bar declined behaviour through the presenter interface.

## Blocked by

None
