# Key reminder state by occurrence

Type: AFK
Status: Done

## What to build

EventKit shares `eventIdentifier` across every occurrence of a recurring event, and reminder state keyed on it. After one occurrence alerted, every later occurrence failed `shouldDeliver` for as long as the app ran, dismissing one occurrence suppressed the whole series, and a recurring meeting highlighted today hid its own row under Tomorrow's Events.

## Acceptance criteria

- [x] Occurrence Identity lives in one place, `CalendarEventOccurrenceID.make(...)`, combining the identifier with the occurrence start date.
- [x] Occurrences of a recurring event get distinct IDs; the same occurrence always gets the same ID.
- [x] Events without an `eventIdentifier` fall back to `calendarItemIdentifier`.
- [x] `CalendarEventSource` builds snapshot IDs through the seam.
- [x] CONTEXT.md defines Occurrence Identity.
