# Add private on-time feedback

Type: HITL
Status: Skipped

## What to build

Design and implement a tiny local-only positive feedback moment after the user joins a meeting on time. This should feel personal and useful, not decorative for its own sake, and must avoid streak pressure, public scoring, or shame for missed meetings.

## Acceptance criteria

- [ ] A human approves the tone and visual direction before implementation.
- [ ] Joining on time triggers one small positive feedback moment.
- [ ] Missed or late meetings do not produce negative feedback.
- [ ] The feedback adds useful context or reassurance instead of a decorative-only flourish.
- [ ] The feedback is local-only and does not require analytics, network calls, or account state.
- [ ] The user can disable the feedback.
- [ ] Tests cover the on-time eligibility rule and disabled state.

## Blocked by

- `.scratch/fun-useful-reminders/issues/01-ship-utility-first-overlay.md`
