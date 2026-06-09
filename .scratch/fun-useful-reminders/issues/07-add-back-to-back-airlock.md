# Add a back-to-back airlock

Type: AFK
Status: Done

## What to build

When another Google Meet event starts soon after the current one, show a calm transition state that helps the user move between calls. The airlock should be useful, not wellness spam: next meeting, compact countdown, join action, and one tiny reset prompt.

## Acceptance criteria

- [x] The app detects a joinable next meeting that starts soon after the current meeting.
- [x] The user sees a back-to-back transition state with the next meeting title and compact countdown.
- [x] The transition state includes a direct join action for the next meeting.
- [x] The transition state can be dismissed without suppressing unrelated future reminders.
- [x] The airlock does not appear for all-day, declined, finished, or non-Meet events.
- [x] Tests cover back-to-back detection, non-back-to-back events, and dismissed transition behavior.

## Blocked by

- `.scratch/fun-useful-reminders/issues/01-ship-utility-first-overlay.md`
