# Ship the utility-first overlay

Type: AFK
Status: Done

## What to build

Turn the existing fullscreen meeting alert into a focused personal utility that behaves like a serious reminder. The completed slice should emphasize the countdown, meeting title, meeting time, and the current join/dismiss path end to end.

Do not ship nonfunctional placeholder actions. Snooze behavior is covered by the snooze issue.

## Acceptance criteria

- [x] The fullscreen reminder uses `#ffcc00` only for primary emphasis.
- [x] The overlay keeps a clear primary `Join` action and a clear secondary dismiss action.
- [x] The overlay shows compact countdown text such as `20m`, `1h`, and `1h 30m` where countdowns appear.
- [x] The overlay remains readable on desktop and laptop displays, with keyboard dismissal still working.
- [x] Existing join and dismiss behavior still works.
- [x] The overlay does not include decorative product labels or other visual elements that do not help the reminder.

## Blocked by

None - can start immediately
