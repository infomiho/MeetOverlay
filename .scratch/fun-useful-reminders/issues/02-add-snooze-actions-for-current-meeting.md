# Add snooze actions for the current meeting

Type: AFK
Status: Done

## What to build

Add functional snooze actions for the meeting currently shown in the fullscreen reminder. A snoozed meeting should hide the overlay temporarily, then become eligible for alerting again when the snooze expires, without permanently dismissing the event.

## Acceptance criteria

- [x] The overlay exposes `Snooze 1m` and `Snooze 5m` actions.
- [x] Snoozing hides the overlay immediately.
- [x] A snoozed event can alert again after the chosen snooze duration expires.
- [x] Dismiss still suppresses the event for the rest of that event's lifecycle.
- [x] Join still opens the meeting link and suppresses the current event.
- [x] Tests cover snooze expiry, dismiss suppression, and join suppression with deterministic time inputs.

## Blocked by

None - can start immediately
