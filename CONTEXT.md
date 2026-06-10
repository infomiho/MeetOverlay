# MeetOverlay

A macOS menu bar app that watches Calendar for Google Meet events and reminds you to join. This document fixes the language the code and its architecture reviews should use.

## Language

**Joinable Meeting**:
A calendar event the user can act on as a call: it is not all-day, the user has not declined it, and it carries at least one Meet Link. Eligibility is decided in one place, `JoinableMeeting.from(_:)`. Time-window rules (how soon before the start, how long after) are the caller's concern, not part of joinability.
_Avoid_: meeting candidate, actionable event, valid meeting

**Meet Link**:
A `meet.google.com` room URL found in an event's url, notes, location, or title. Derived once via `CalendarEventSnapshot.meetLinks`; duplicates across fields collapse to one room.
_Avoid_: conference URL, video link, room URL

**Occurrence Identity**:
The identity of one occurrence of a calendar event, built by `CalendarEventOccurrenceID.make(...)`. EventKit shares `eventIdentifier` across every occurrence of a recurring event, so reminder state (delivered stages, dismiss, snooze) keys on identifier plus occurrence start date. Dismissing today's standup must not silence tomorrow's.
_Avoid_: event ID (ambiguous about series vs occurrence)

**Alert Ladder**:
The escalation from a gentle passive notification to the fullscreen reminder as a Joinable Meeting approaches, owned by `MeetingAlertLadder`.
_Avoid_: alert chain, notification pipeline

**Back-to-back Airlock**:
The transition reminder shown while one Joinable Meeting is ending and the next is about to start, owned by `BackToBackAirlock`.
_Avoid_: handoff, gap reminder

## Example dialogue

> **Dev:** A meeting the user declined still lit up the menu bar in urgent yellow.
> **Domain expert:** It should not. A declined event is not a Joinable Meeting, so it should never drive the menu bar or the highlights.
> **Dev:** But it still shows in the agenda list.
> **Domain expert:** Right, the agenda is a neutral list of the day. Joinability decides what we *promote* and what we *alert* on, not what we *list*. So `JoinableMeeting.from` returns nil for it, and the menu bar and Alert Ladder skip it, while the timeline still shows it.
