# Polish reminder UX 80/20

Type: AFK
Status: Done

## What to build

A pass over the highest-friction UX gaps: the overlay blacked out every display, snooze needed the mouse, urgent yellow was unreadable on the light menu bar, plain agenda rows looked disabled, the Sync Doctor model was computed but never rendered, and there was no way to see the reminder without a real meeting.

## Acceptance criteria

- [x] The overlay panel shows on the active screen only; secondary displays get a light scrim.
- [x] Keys 1 and 5 snooze the fullscreen reminder; the hint line documents them.
- [x] The overlay countdown switches to the attention color once the meeting has started.
- [x] The urgent menu bar tint is dynamic: #ffcc00 in dark appearance, dark amber in light.
- [x] Agenda rows without a Meet link render enabled instead of gray (autoenablesItems off).
- [x] Countdown text under a minute is compact ("30s"), matching the design language.
- [x] Settings shows a Sync Doctor card with calendar access, included calendars, login item, and next detected Meet.
- [x] "Show Sample Reminder" in Settings previews the fullscreen overlay with a sample meeting; the monitor tick does not hide it, and Join does not open a URL.
