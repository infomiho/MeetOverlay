# Make snooze re-alert after expiry

Type: AFK
Status: Done

## What to build

Snooze promised to bring the fullscreen reminder back, but it never did. Two mechanisms blocked it: the delivered-stage record survived the snooze, so `shouldDeliver` rejected the second fullscreen alert, and a 5m snooze expired outside the Alert Ladder's 120s late-alert grace window, so the ladder dropped the event entirely. Both snooze buttons behaved like Dismiss.

## Acceptance criteria

- [x] Snoozing clears the event's delivered stages so the same stage can deliver again.
- [x] An expired snooze is tracked and exempts the event from the late-alert grace window while the meeting is ongoing.
- [x] The exemption never resurrects a meeting that already ended.
- [x] Join and Dismiss clear the expired-snooze tracking; re-snoozing hides the event again.
- [x] Tests cover redelivery after snooze, expired-snooze tracking, and the grace-window exemption with deterministic time inputs.
