import EventKit
import Foundation
import MeetOverlayCore

@MainActor
final class CalendarEventSource {
    private let eventStore = EKEventStore()

    var calendarAccessStatus: CalendarAccessDiagnosticState {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            return .allowed
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        case .restricted, .writeOnly:
            return .restricted
        @unknown default:
            return .unknown
        }
    }

    func requestAccess(completion: @escaping @MainActor (Bool) -> Void) {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess, .authorized:
            completion(true)
        case .notDetermined:
            Task { @MainActor in
                let granted = (try? await eventStore.requestFullAccessToEvents()) ?? false
                completion(granted)
            }
        case .denied, .restricted, .writeOnly:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    func events(from startDate: Date, to endDate: Date) -> [CalendarEventSnapshot] {
        let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)

        return eventStore.events(matching: predicate)
            .filter { $0.status != .canceled }
            .map(toSnapshot)
    }

    func calendars() -> [CalendarSnapshot] {
        eventStore.calendars(for: .event)
            .map { calendar in
                CalendarSnapshot(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    sourceTitle: calendar.source.title
                )
            }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    private func toSnapshot(_ event: EKEvent) -> CalendarEventSnapshot {
        CalendarEventSnapshot(
            id: stableID(for: event),
            calendarID: event.calendar.calendarIdentifier,
            title: event.title ?? "Untitled meeting",
            startDate: event.startDate,
            endDate: event.endDate,
            isAllDay: event.isAllDay,
            participationStatus: participationStatus(for: event),
            url: event.url,
            notes: event.notes,
            location: event.location
        )
    }

    private func stableID(for event: EKEvent) -> String {
        if let eventIdentifier = event.eventIdentifier, !eventIdentifier.isEmpty {
            return eventIdentifier
        }

        return "\(event.calendarItemIdentifier)|\(event.startDate.timeIntervalSinceReferenceDate)"
    }

    private func participationStatus(for event: EKEvent) -> EventParticipationStatus {
        guard let participantStatus = event.attendees?.first(where: { $0.isCurrentUser })?.participantStatus else {
            return .unknown
        }

        switch participantStatus {
        case .accepted:
            return .accepted
        case .declined:
            return .declined
        case .tentative:
            return .tentative
        case .unknown, .pending, .delegated, .completed, .inProcess:
            return .unknown
        @unknown default:
            return .unknown
        }
    }
}
