# Add a focus-safe alert ladder

Type: AFK
Status: Done

## What to build

Add gradual alerting so the app can cue a meeting before it becomes fullscreen urgent. The ladder should start with a gentle cue and escalate to the fullscreen reminder only when the meeting is close and has not been joined, snoozed, or dismissed.

## Acceptance criteria

- [x] A gentle pre-alert can happen before the fullscreen reminder window.
- [x] The fullscreen reminder still appears near the meeting start when the event has not been handled.
- [x] Snoozed events do not escalate during the snooze window.
- [x] Dismissed or joined events do not keep escalating.
- [x] The alert ladder avoids repeated identical cues in the same stage for the same event.
- [x] Tests cover stage selection, stage transitions, snooze interaction, and suppression after dismiss or join.

## Blocked by

- `.scratch/fun-useful-reminders/issues/02-add-snooze-actions-for-current-meeting.md`
