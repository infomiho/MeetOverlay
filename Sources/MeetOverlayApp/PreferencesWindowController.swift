import AppKit
import MeetOverlayCore
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private let calendarEventSource: CalendarEventSource
    private let preferencesStore: AppPreferencesStore
    private let loginItemController: LoginItemController
    private let onPreferencesChanged: () -> Void
    private let onPreviewReminder: () -> Void

    private var window: NSWindow?
    private var viewModel: PreferencesViewModel?

    init(
        calendarEventSource: CalendarEventSource,
        preferencesStore: AppPreferencesStore,
        loginItemController: LoginItemController,
        onPreferencesChanged: @escaping () -> Void,
        onPreviewReminder: @escaping () -> Void
    ) {
        self.calendarEventSource = calendarEventSource
        self.preferencesStore = preferencesStore
        self.loginItemController = loginItemController
        self.onPreferencesChanged = onPreferencesChanged
        self.onPreviewReminder = onPreviewReminder
    }

    func show() {
        let now = Date()
        let preferences = preferencesStore.load()
        let calendarAccessStatus = calendarEventSource.calendarAccessStatus
        let calendars = calendarEventSource.calendars()
        let diagnosticEvents = eventsForDiagnostics(now: now, calendarAccessStatus: calendarAccessStatus)
        let viewModel = PreferencesViewModel(
            calendars: calendars,
            calendarAccessStatus: calendarAccessStatus,
            diagnosticEvents: diagnosticEvents,
            initialPreferences: preferences,
            preferencesStore: preferencesStore,
            loginItemController: loginItemController,
            onPreferencesChanged: onPreferencesChanged,
            onPreviewReminder: onPreviewReminder
        )
        let contentView = SettingsView(viewModel: viewModel)

        if let window {
            window.contentView = NSHostingView(rootView: contentView)
            window.makeKeyAndOrderFront(nil)
        } else {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 640, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )

            window.title = "Settings"
            window.minSize = NSSize(width: 560, height: 520)
            window.contentView = NSHostingView(rootView: contentView)
            window.center()
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            self.window = window
        }

        self.viewModel = viewModel
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func eventsForDiagnostics(
        now: Date,
        calendarAccessStatus: CalendarAccessDiagnosticState
    ) -> [CalendarEventSnapshot] {
        guard calendarAccessStatus == .allowed else {
            return []
        }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: now)
        let endDate = calendar.date(byAdding: .day, value: 2, to: startDate) ?? now.addingTimeInterval(48 * 60 * 60)
        return calendarEventSource.events(from: startDate, to: endDate)
    }
}

@MainActor
private final class PreferencesViewModel: ObservableObject {
    let calendars: [CalendarSnapshot]
    let calendarAccessStatus: CalendarAccessDiagnosticState
    let diagnosticEvents: [CalendarEventSnapshot]

    @Published var selectedCalendarIDs: Set<String>?
    @Published var isOverlayEnabled: Bool
    @Published var hidesFinishedEvents: Bool
    @Published var launchAtLogin: Bool
    @Published var reminderSoundID: String
    @Published var loginItemStatus: String
    @Published var errorMessage: String?

    let reminderSounds = ReminderSoundCatalog.sounds

    var needsStartupAttention: Bool {
        !["Enabled", "Disabled"].contains(loginItemStatus)
    }

    var calendarSelectionSummary: String {
        guard !calendars.isEmpty else {
            return "No calendars available."
        }

        guard let selectedCalendarIDs else {
            return "Using all \(calendars.count) calendars, including calendars added later."
        }

        return "\(selectedCalendarIDs.count) of \(calendars.count) calendars selected."
    }

    var calendarSyncDiagnostic: CalendarSyncDiagnostic {
        CalendarSyncDiagnostic.summary(
            calendarAccess: calendarAccessStatus,
            calendars: calendars,
            selectedCalendarIDs: selectedCalendarIDs,
            launchAtLoginStatus: loginItemStatus,
            now: Date(),
            events: diagnosticEvents
        )
    }

    var allVisibleCalendarsSelected: Bool {
        selectedCalendarIDs == nil || selectedCalendarIDs == Set(calendars.map(\.id))
    }

    var noCalendarsSelected: Bool {
        selectedCalendarIDs == []
    }

    private let preferencesStore: AppPreferencesStore
    private let loginItemController: LoginItemController
    private let reminderSoundPlayer = ReminderSoundPlayer()
    private let onPreferencesChanged: () -> Void
    private let onPreviewReminder: () -> Void

    init(
        calendars: [CalendarSnapshot],
        calendarAccessStatus: CalendarAccessDiagnosticState,
        diagnosticEvents: [CalendarEventSnapshot],
        initialPreferences: AppPreferences,
        preferencesStore: AppPreferencesStore,
        loginItemController: LoginItemController,
        onPreferencesChanged: @escaping () -> Void,
        onPreviewReminder: @escaping () -> Void
    ) {
        self.calendars = calendars
        self.calendarAccessStatus = calendarAccessStatus
        self.diagnosticEvents = diagnosticEvents
        self.selectedCalendarIDs = initialPreferences.selectedCalendarIDs
        self.isOverlayEnabled = initialPreferences.isOverlayEnabled
        self.hidesFinishedEvents = initialPreferences.hidesFinishedEvents
        self.reminderSoundID = initialPreferences.reminderSoundID
        self.launchAtLogin = loginItemController.isEnabled
        self.loginItemStatus = loginItemController.statusText
        self.preferencesStore = preferencesStore
        self.loginItemController = loginItemController
        self.onPreferencesChanged = onPreferencesChanged
        self.onPreviewReminder = onPreviewReminder
    }

    func isCalendarSelected(_ calendarID: String) -> Bool {
        selectedCalendarIDs?.contains(calendarID) ?? true
    }

    func setOverlayEnabled(_ isEnabled: Bool) {
        isOverlayEnabled = isEnabled
        savePreferences()
    }

    func setHidesFinishedEvents(_ isEnabled: Bool) {
        hidesFinishedEvents = isEnabled
        savePreferences()
    }

    func setReminderSound(_ soundID: String) {
        reminderSoundID = soundID
        savePreferences()
    }

    func previewReminderSound() {
        reminderSoundPlayer.play(ReminderSoundCatalog.sound(for: reminderSoundID))
    }

    func previewReminder() {
        onPreviewReminder()
    }

    func setLaunchAtLogin(_ isEnabled: Bool) {
        do {
            try loginItemController.setEnabled(isEnabled)
            launchAtLogin = loginItemController.isEnabled
            loginItemStatus = loginItemController.statusText
            errorMessage = nil
        } catch {
            launchAtLogin = loginItemController.isEnabled
            loginItemStatus = loginItemController.statusText
            errorMessage = "Could not update startup setting: \(error.localizedDescription)"
        }

        savePreferences()
    }

    func setCalendar(_ calendarID: String, isSelected: Bool) {
        selectedCalendarIDs = CalendarSelectionUpdater.updatedSelection(
            currentSelection: selectedCalendarIDs,
            allCalendarIDs: Set(calendars.map(\.id)),
            calendarID: calendarID,
            isSelected: isSelected
        )
        savePreferences()
    }

    func selectAllCalendars() {
        selectedCalendarIDs = nil
        savePreferences()
    }

    func selectNoCalendars() {
        selectedCalendarIDs = []
        savePreferences()
    }

    private func savePreferences() {
        let preferences = AppPreferences(
            selectedCalendarIDs: selectedCalendarIDs,
            isOverlayEnabled: isOverlayEnabled,
            launchAtLogin: launchAtLogin,
            hidesFinishedEvents: hidesFinishedEvents,
            reminderSoundID: reminderSoundID
        )

        preferencesStore.save(preferences)
        onPreferencesChanged()
    }
}

private struct SettingsView: View {
    @StateObject private var viewModel: PreferencesViewModel

    init(viewModel: PreferencesViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        TabView {
            GeneralSettingsView(
                viewModel: viewModel,
                launchAtLoginBinding: launchAtLoginBinding,
                overlayBinding: overlayBinding,
                hidesFinishedEventsBinding: hidesFinishedEventsBinding,
                reminderSoundBinding: reminderSoundBinding
            )
            .tabItem {
                Label("General", systemImage: "gearshape")
            }

            CalendarSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Calendars", systemImage: "calendar")
                }
        }
        .tint(MeetOverlayTheme.Palette.accent)
        .padding(MeetOverlayTheme.Spacing.xLarge)
        .frame(minWidth: 560, minHeight: 520, alignment: .topLeading)
        .background(MeetOverlayTheme.Palette.settingsBackground)
    }

    private var overlayBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isOverlayEnabled },
            set: { viewModel.setOverlayEnabled($0) }
        )
    }

    private var hidesFinishedEventsBinding: Binding<Bool> {
        Binding(
            get: { viewModel.hidesFinishedEvents },
            set: { viewModel.setHidesFinishedEvents($0) }
        )
    }

    private var reminderSoundBinding: Binding<String> {
        Binding(
            get: { viewModel.reminderSoundID },
            set: { viewModel.setReminderSound($0) }
        )
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { viewModel.launchAtLogin },
            set: { viewModel.setLaunchAtLogin($0) }
        )
    }
}

private struct GeneralSettingsView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    let launchAtLoginBinding: Binding<Bool>
    let overlayBinding: Binding<Bool>
    let hidesFinishedEventsBinding: Binding<Bool>
    let reminderSoundBinding: Binding<String>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "General",
                    subtitle: "Keep the menu quiet and the reminder behavior predictable."
                )

                SettingsCard(
                    systemImage: "power",
                    title: "Startup",
                    description: "Control whether MeetOverlay is ready after sign-in."
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Open at Login", isOn: launchAtLoginBinding)

                        if viewModel.needsStartupAttention {
                            Text("Startup: \(viewModel.loginItemStatus)")
                                .font(MeetOverlayTheme.Typography.helper.weight(.medium))
                                .foregroundStyle(MeetOverlayTheme.Palette.attention)
                        }
                    }
                }

                SettingsCard(
                    systemImage: "bell.and.waves.left.and.right",
                    title: "Reminders",
                    description: "Fullscreen reminders appear only for joinable Google Meet events."
                ) {
                    VStack(alignment: .leading, spacing: MeetOverlayTheme.Spacing.medium) {
                        Toggle("Show fullscreen reminders", isOn: overlayBinding)

                        HStack(spacing: MeetOverlayTheme.Spacing.small) {
                            Picker("Sound", selection: reminderSoundBinding) {
                                ForEach(viewModel.reminderSounds) { sound in
                                    Text(sound.title).tag(sound.id)
                                }
                            }
                            .frame(maxWidth: 280)

                            Button("Preview") {
                                viewModel.previewReminderSound()
                            }
                        }

                        Text("Used by fullscreen reminders. Back-to-back airlock stays silent.")
                            .font(MeetOverlayTheme.Typography.helper)
                            .foregroundStyle(.secondary)

                        Button("Show Sample Reminder") {
                            viewModel.previewReminder()
                        }
                    }
                }

                SettingsCard(
                    systemImage: "menubar.rectangle",
                    title: "Menu",
                    description: "Keep the menu focused on events that still matter."
                ) {
                    Toggle("Hide finished events", isOn: hidesFinishedEventsBinding)
                }

                SettingsCard(
                    systemImage: "stethoscope",
                    title: "Sync Doctor",
                    description: "Whether MeetOverlay is ready to catch your next meeting."
                ) {
                    SyncDoctorView(diagnostic: viewModel.calendarSyncDiagnostic)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(MeetOverlayTheme.Typography.helper)
                        .foregroundStyle(MeetOverlayTheme.Palette.warning)
                }

                Spacer()
            }
            .padding(MeetOverlayTheme.Spacing.page)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct CalendarSettingsView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SettingsPageHeader(
                    title: "Calendars",
                    subtitle: "Choose which synced calendars can appear in the menu and trigger reminders."
                )

                SettingsCard(
                    systemImage: "calendar",
                    title: "Included Calendars",
                    description: "Using all calendars also includes calendars added later."
                ) {
                    VStack(alignment: .leading, spacing: MeetOverlayTheme.Spacing.medium) {
                        if let problem = viewModel.calendarSyncDiagnostic.problem {
                            CalendarSyncProblemBanner(problem: problem)
                        }

                        CalendarSelectionView(viewModel: viewModel)
                    }
                }

                Spacer()
            }
            .padding(MeetOverlayTheme.Spacing.page)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}

private struct SettingsPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: MeetOverlayTheme.Spacing.xSmall) {
            Text(title)
                .font(MeetOverlayTheme.Typography.pageTitle)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(MeetOverlayTheme.Typography.helper)
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsCard<Content: View>: View {
    let systemImage: String
    let title: String
    let description: String?
    @ViewBuilder let content: Content

    init(
        systemImage: String,
        title: String,
        description: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.systemImage = systemImage
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MeetOverlayTheme.Spacing.medium) {
            HStack(alignment: .top, spacing: MeetOverlayTheme.Spacing.medium) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MeetOverlayTheme.Palette.accent)
                    .frame(
                        width: MeetOverlayTheme.Size.settingsIconBadge,
                        height: MeetOverlayTheme.Size.settingsIconBadge
                    )
                    .background(
                        RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.iconBadge)
                            .fill(MeetOverlayTheme.Palette.iconBadgeBackground)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(MeetOverlayTheme.Typography.sectionTitle)
                        .foregroundStyle(.primary)

                    if let description {
                        Text(description)
                            .font(MeetOverlayTheme.Typography.helper)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            content
        }
        .padding(MeetOverlayTheme.Spacing.card)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.card)
                .fill(MeetOverlayTheme.Palette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.card)
                .stroke(MeetOverlayTheme.Palette.border, lineWidth: 1)
        )
    }
}

private struct SyncDoctorView: View {
    let diagnostic: CalendarSyncDiagnostic

    var body: some View {
        VStack(alignment: .leading, spacing: MeetOverlayTheme.Spacing.small) {
            if let problem = diagnostic.problem {
                CalendarSyncProblemBanner(problem: problem)
            }

            SyncDoctorRow(item: diagnostic.calendarAccess)
            SyncDoctorRow(item: diagnostic.includedCalendars)
            SyncDoctorRow(item: diagnostic.launchAtLogin)
            SyncDoctorRow(item: diagnostic.nextMeet)
        }
    }
}

private struct SyncDoctorRow: View {
    let item: CalendarSyncDiagnosticItem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MeetOverlayTheme.Spacing.medium) {
            Text(item.title)
                .font(MeetOverlayTheme.Typography.helper)
                .foregroundStyle(.secondary)

            Spacer()

            Text(item.value)
                .font(MeetOverlayTheme.Typography.helper.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct CalendarSyncProblemBanner: View {
    let problem: CalendarSyncDiagnosticProblem

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: MeetOverlayTheme.Spacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(MeetOverlayTheme.Typography.helper.weight(.semibold))
                .foregroundStyle(MeetOverlayTheme.Palette.attention)

            Text(problem.message)
                .font(MeetOverlayTheme.Typography.helper)
                .foregroundStyle(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.inset)
                .fill(MeetOverlayTheme.Palette.attention.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.inset)
                .stroke(MeetOverlayTheme.Palette.attention.opacity(0.25), lineWidth: 1)
        )
    }
}

private struct CalendarSelectionView: View {
    @ObservedObject var viewModel: PreferencesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.calendarSelectionSummary)
                    .font(MeetOverlayTheme.Typography.helper)
                    .foregroundStyle(viewModel.noCalendarsSelected ? MeetOverlayTheme.Palette.warning : .secondary)

                Spacer()

                Button("Use All Calendars") {
                    viewModel.selectAllCalendars()
                }
                .disabled(viewModel.allVisibleCalendarsSelected)

                Button("Deselect All") {
                    viewModel.selectNoCalendars()
                }
                .disabled(viewModel.noCalendarsSelected)
            }
            .controlSize(.small)

            if !viewModel.calendars.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(viewModel.calendars) { calendar in
                            CalendarToggleRow(viewModel: viewModel, calendar: calendar)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(MeetOverlayTheme.Spacing.medium)
                }
                .frame(minHeight: 300)
                .background(
                    RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.inset)
                        .fill(MeetOverlayTheme.Palette.insetBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MeetOverlayTheme.Radius.inset)
                        .stroke(MeetOverlayTheme.Palette.mutedBorder, lineWidth: 1)
                )
            }
        }
    }
}

private struct CalendarToggleRow: View {
    @ObservedObject var viewModel: PreferencesViewModel
    let calendar: CalendarSnapshot

    var body: some View {
        Toggle(calendar.displayTitle, isOn: isSelectedBinding)
            .font(.body)
    }

    private var isSelectedBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isCalendarSelected(calendar.id) },
            set: { viewModel.setCalendar(calendar.id, isSelected: $0) }
        )
    }
}
