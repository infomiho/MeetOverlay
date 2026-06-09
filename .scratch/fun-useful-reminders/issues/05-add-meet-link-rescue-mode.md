# Add Meet link rescue mode

Type: AFK
Status: Done

## What to build

Handle messy calendar events that contain more than one Google Meet link. Instead of silently choosing the first link in every case, expose a safe way to choose or copy the detected links while preserving the simple one-link behavior.

## Acceptance criteria

- [x] The app can detect multiple unique Google Meet links from the same event.
- [x] Events with one Meet link keep the existing direct join behavior.
- [x] Events with multiple Meet links expose the detected choices in a clear user-facing path.
- [x] The user can open or copy a detected Meet link.
- [x] Duplicate links are not shown multiple times.
- [x] Tests cover links found in URL, notes, location, title, duplicates, and multiple-link events.

## Blocked by

None - can start immediately
