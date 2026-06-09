import AppKit
import MeetOverlayCore

@MainActor
final class ReminderSoundPlayer {
    private var soundsByID: [String: NSSound] = [:]

    func play(_ sound: ReminderSound) {
        guard let url = Bundle.main.url(forResource: sound.resourceName, withExtension: sound.fileExtension) else {
            return
        }

        let nsSound = soundsByID[sound.id] ?? NSSound(contentsOf: url, byReference: false)
        guard let nsSound else { return }

        soundsByID[sound.id] = nsSound
        nsSound.stop()
        nsSound.play()
    }
}
