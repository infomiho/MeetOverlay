import Foundation
import MeetOverlayCore
import UserNotifications

@MainActor
final class GentleAlertPresenter {
    private let notificationCenter = UNUserNotificationCenter.current()
    private var hasRequestedAuthorization = false
    private var isAuthorized = false

    func show(meeting: JoinableMeeting) {
        guard isAuthorized else {
            requestAuthorization(eventID: meeting.eventID, title: meeting.title)
            return
        }

        deliver(eventID: meeting.eventID, title: meeting.title)
    }

    private func requestAuthorization(eventID: String, title: String) {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true

        notificationCenter.requestAuthorization(options: [.alert]) { [weak self] granted, _ in
            guard granted else { return }

            Task { @MainActor in
                self?.isAuthorized = true
                self?.deliver(eventID: eventID, title: title)
            }
        }
    }

    private func deliver(eventID: String, title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Meeting soon"
        content.body = "\(title) starts soon."
        content.interruptionLevel = .passive

        let request = UNNotificationRequest(
            identifier: "MeetOverlay.gentle.\(eventID)",
            content: content,
            trigger: nil
        )
        notificationCenter.add(request)
    }
}
