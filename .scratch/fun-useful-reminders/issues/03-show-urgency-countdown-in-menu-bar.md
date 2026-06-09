# Show an urgency countdown in the menu bar

Type: AFK
Status: Done

## What to build

Make the menu bar presence more fun and more useful by surfacing the next relevant meeting with compact timing and a stronger urgent state near the start time. This should improve ambient awareness without forcing the fullscreen overlay early.

## Acceptance criteria

- [x] The menu bar title uses compact countdown units for upcoming meetings, such as `Planning 20m`, `Planning 1h`, or `Planning 1h 30m`.
- [x] The idle state remains calm and recognizable when there is no upcoming meeting.
- [x] The urgent state is visibly or textually stronger near the meeting start without being noisy outside that window.
- [x] The menu still lists today's and tomorrow's events correctly.
- [x] Tests cover compact countdown title behavior, idle behavior, and urgent threshold behavior.

## Blocked by

None - can start immediately
