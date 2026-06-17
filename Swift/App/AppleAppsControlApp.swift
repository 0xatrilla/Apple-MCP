import AppKit
import EventKit
import Network
import SwiftUI

enum IntegrationID: String, CaseIterable, Identifiable, Codable {
    case calendar
    case reminders
    case notes
    case mail
    case shortcuts
    case music

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calendar: "Calendar"
        case .reminders: "Reminders"
        case .notes: "Notes"
        case .mail: "Mail"
        case .shortcuts: "Shortcuts"
        case .music: "Music"
        }
    }

    var symbol: String {
        switch self {
        case .calendar: "calendar"
        case .reminders: "checklist"
        case .notes: "note.text"
        case .mail: "envelope"
        case .shortcuts: "square.stack.3d.up"
        case .music: "music.note"
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .calendar: "com.apple.iCal"
        case .reminders: "com.apple.reminders"
        case .notes: "com.apple.Notes"
        case .mail: "com.apple.mail"
        case .shortcuts: "com.apple.shortcuts"
        case .music: "com.apple.Music"
        }
    }

    var tint: Color {
        switch self {
        case .calendar: .red
        case .reminders: .blue
        case .notes: .yellow
        case .mail: .cyan
        case .shortcuts: .purple
        case .music: .pink
        }
    }

    var toolNames: [String] {
        switch self {
        case .calendar: ["calendar_list_events", "calendar_create_event"]
        case .reminders: ["reminders_list", "reminders_create", "reminders_complete"]
        case .notes: ["notes_search", "notes_read", "notes_create"]
        case .mail: ["mail_search", "mail_read", "mail_create_draft", "mail_send_draft"]
        case .shortcuts: ["shortcuts_list", "shortcuts_run"]
        case .music: ["music_search", "music_play", "music_pause"]
        }
    }

    var permissionSummary: String {
        switch self {
        case .calendar, .reminders: "Native macOS permission"
        case .notes, .mail, .music: "Automation permission on first use"
        case .shortcuts: "Shortcuts command access"
        }
    }

    /// Short capability line shown under the title (macuse-style).
    var tagline: String {
        switch self {
        case .calendar: "Add events and check availability."
        case .reminders: "Capture tasks, set due dates, mark done."
        case .notes: "Create, search, and read notes."
        case .mail: "Search, read, draft, and send mail."
        case .shortcuts: "Browse and run your shortcuts."
        case .music: "Search the library and control playback."
        }
    }

    var tools: [ToolInfo] {
        toolNames.map(ToolInfo.catalog)
    }
}

struct ToolInfo: Identifiable {
    let raw: String
    let title: String
    let summary: String
    let symbol: String
    let risky: Bool

    var id: String { raw }

    static let riskyTools: Set<String> = ["reminders_complete", "mail_send_draft", "shortcuts_run"]

    static func catalog(_ raw: String) -> ToolInfo {
        let risky = riskyTools.contains(raw)
        switch raw {
        case "calendar_list_events": return ToolInfo(raw: raw, title: "List events", summary: "See what's coming up", symbol: "calendar", risky: risky)
        case "calendar_create_event": return ToolInfo(raw: raw, title: "Create event", summary: "Schedule a new event", symbol: "calendar.badge.plus", risky: risky)
        case "reminders_list": return ToolInfo(raw: raw, title: "List reminders", summary: "Review open tasks", symbol: "list.bullet", risky: risky)
        case "reminders_create": return ToolInfo(raw: raw, title: "Create reminder", summary: "Add a new task", symbol: "plus.circle", risky: risky)
        case "reminders_complete": return ToolInfo(raw: raw, title: "Complete reminder", summary: "Mark a task as done", symbol: "checkmark.circle", risky: risky)
        case "notes_search": return ToolInfo(raw: raw, title: "Search notes", summary: "Find notes by keyword", symbol: "magnifyingglass", risky: risky)
        case "notes_read": return ToolInfo(raw: raw, title: "Read note", summary: "Open a note's contents", symbol: "doc.text", risky: risky)
        case "notes_create": return ToolInfo(raw: raw, title: "Create note", summary: "Capture a new note", symbol: "square.and.pencil", risky: risky)
        case "mail_search": return ToolInfo(raw: raw, title: "Search mail", summary: "Find messages", symbol: "magnifyingglass", risky: risky)
        case "mail_read": return ToolInfo(raw: raw, title: "Read mail", summary: "Open a message", symbol: "envelope.open", risky: risky)
        case "mail_create_draft": return ToolInfo(raw: raw, title: "Draft mail", summary: "Compose a draft", symbol: "square.and.pencil", risky: risky)
        case "mail_send_draft": return ToolInfo(raw: raw, title: "Send mail", summary: "Send a drafted message", symbol: "paperplane", risky: risky)
        case "shortcuts_list": return ToolInfo(raw: raw, title: "List shortcuts", summary: "Browse your shortcuts", symbol: "square.stack.3d.up", risky: risky)
        case "shortcuts_run": return ToolInfo(raw: raw, title: "Run shortcut", summary: "Execute a shortcut", symbol: "play.circle", risky: risky)
        case "music_search": return ToolInfo(raw: raw, title: "Search music", summary: "Find songs and albums", symbol: "magnifyingglass", risky: risky)
        case "music_play": return ToolInfo(raw: raw, title: "Play", summary: "Start playback", symbol: "play.fill", risky: risky)
        case "music_pause": return ToolInfo(raw: raw, title: "Pause", summary: "Pause playback", symbol: "pause.fill", risky: risky)
        default: return ToolInfo(raw: raw, title: raw, summary: "Tool", symbol: "wrench.and.screwdriver", risky: risky)
        }
    }
}

enum PreferredClient: String, CaseIterable, Identifiable, Codable {
    case codexApp
    case codexCLI
    case claudeApp
    case claudeCLI
    case raycast
    case manual

    var id: String { rawValue }

    /// Brand family — drives logo, accent, and installed-icon lookup.
    enum Brand { case codex, claude, raycast, generic }

    var brand: Brand {
        switch self {
        case .codexApp, .codexCLI: .codex
        case .claudeApp, .claudeCLI: .claude
        case .raycast: .raycast
        case .manual: .generic
        }
    }

    var title: String {
        switch self {
        case .codexApp: "Codex"
        case .codexCLI: "Codex CLI"
        case .claudeApp: "Claude"
        case .claudeCLI: "Claude Code"
        case .raycast: "Raycast"
        case .manual: "Manual"
        }
    }

    var symbol: String { "curlybraces" }

    var accent: Color {
        switch brand {
        case .codex: Color(red: 0.06, green: 0.64, blue: 0.50)
        case .claude: Color(red: 0.85, green: 0.47, blue: 0.34)
        case .raycast: Color(red: 1.0, green: 0.39, blue: 0.39)
        case .generic: .secondary
        }
    }

    /// One-line description for the connection grid.
    var tagline: String {
        switch self {
        case .codexApp: "Adds the server to the Codex desktop app."
        case .codexCLI: "Registers a local stdio server via codex mcp."
        case .claudeApp: "Adds the server to Claude Desktop's config."
        case .claudeCLI: "Registers a local stdio server via claude mcp."
        case .raycast: "Copy a ready-to-paste config for Raycast."
        case .manual: "Use the raw stdio command in any client."
        }
    }

    var kind: String {
        switch self {
        case .codexApp, .claudeApp: "Desktop app"
        case .codexCLI, .claudeCLI: "CLI"
        case .raycast: "App"
        case .manual: "Any MCP client"
        }
    }

    var canInstall: Bool {
        switch self {
        case .codexApp, .codexCLI, .claudeApp, .claudeCLI: true
        case .raycast, .manual: false
        }
    }
}

enum SidebarSelection: Hashable {
    case connect
    case integration(IntegrationID)
}

struct AppConfig: Codable {
    var preferredClient: PreferredClient = .codexApp
    var onboardingComplete = false
    var integrations: [IntegrationID: Bool] = Dictionary(uniqueKeysWithValues: IntegrationID.allCases.map { ($0, true) })

    enum CodingKeys: String, CodingKey {
        case preferredClient
        case onboardingComplete
        case integrations
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawClient = try container.decodeIfPresent(String.self, forKey: .preferredClient)
        preferredClient = rawClient.flatMap(PreferredClient.init(rawValue:)) ?? .codexApp
        onboardingComplete = try container.decodeIfPresent(Bool.self, forKey: .onboardingComplete) ?? false
        let rawIntegrations = try container.decodeIfPresent([String: Bool].self, forKey: .integrations) ?? [:]
        integrations = Dictionary(uniqueKeysWithValues: IntegrationID.allCases.map { integration in
            (integration, rawIntegrations[integration.rawValue] ?? true)
        })
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(preferredClient, forKey: .preferredClient)
        try container.encode(onboardingComplete, forKey: .onboardingComplete)
        try container.encode(Dictionary(uniqueKeysWithValues: integrations.map { ($0.key.rawValue, $0.value) }), forKey: .integrations)
    }
}

/// Structured result of a setup action, so the UI can show a typed banner
/// (with the right color + icon) and an optional copyable code block, instead
/// of cramming success text, errors, and raw JSON into one gray string.
struct SetupFeedback: Equatable {
    enum Kind: Equatable {
        case success, error, info, progress

        var symbol: String {
            switch self {
            case .success: "checkmark.circle.fill"
            case .error: "exclamationmark.triangle.fill"
            case .info: "info.circle.fill"
            case .progress: "arrow.triangle.2.circlepath"
            }
        }

        var tint: Color {
            switch self {
            case .success: .green
            case .error: .red
            case .info: .accentColor
            case .progress: .orange
            }
        }
    }

    var kind: Kind
    var message: String
    /// Optional monospace payload (e.g. JSON config or shell output) shown in a copyable block.
    var code: String? = nil
}

@Observable
@MainActor
final class AppStore {
    var config = AppConfig()
    var selection: SidebarSelection? = .integration(.calendar)
    var calendarPermission = "unknown"
    var remindersPermission = "unknown"
    var feedback: SetupFeedback?
    /// True while the loopback EventKit bridge is listening for MCP requests.
    var bridgeRunning = false
    private var trustedCalendarGrant = UserDefaults.standard.bool(forKey: "AppleAppsMCP.trustedCalendarGrant")
    private var trustedRemindersGrant = UserDefaults.standard.bool(forKey: "AppleAppsMCP.trustedRemindersGrant")

    let configURL: URL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".apple-apps-mcp", isDirectory: true)
        .appendingPathComponent("config.json")

    var totalEnabledTools: Int {
        IntegrationID.allCases.reduce(0) { total, integration in
            total + ((config.integrations[integration] ?? true) ? integration.toolNames.count : 0)
        }
    }

    /// Status line shown in the header / menu bar — reflects whether the MCP
    /// bridge is actually listening, not a hardcoded "online" state.
    var serverStatusText: String {
        bridgeRunning ? "\(totalEnabledTools) tools active" : "Server not running"
    }

    var serverStatusColor: Color {
        bridgeRunning ? .green : .orange
    }

    func load() {
        do {
            let data = try Data(contentsOf: configURL)
            config = try JSONDecoder().decode(AppConfig.self, from: data)
        } catch {
            save()
        }
        refreshPermissions()
        EventKitBridge.shared.onStateChange = { [weak self] running in
            self?.bridgeRunning = running
        }
        EventKitBridge.shared.start()
        if let icon = AppBranding.icon {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    func save() {
        do {
            try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(config).write(to: configURL, options: .atomic)
        } catch {
            feedback = SetupFeedback(kind: .error, message: "Could not save config: \(error.localizedDescription)")
        }
    }

    func setEnabled(_ integration: IntegrationID, enabled: Bool) {
        config.integrations[integration] = enabled
        save()
    }

    func completeOnboarding() {
        config.onboardingComplete = true
        save()
    }

    func restartOnboarding() {
        feedback = nil
        config.onboardingComplete = false
        save()
    }

    func refreshPermissions() {
        let calendarStatus = permissionText(EKEventStore.authorizationStatus(for: .event))
        let remindersStatus = permissionText(EKEventStore.authorizationStatus(for: .reminder))
        calendarPermission = reconcilePermission(polled: calendarStatus, trusted: &trustedCalendarGrant, defaultsKey: "AppleAppsMCP.trustedCalendarGrant")
        remindersPermission = reconcilePermission(polled: remindersStatus, trusted: &trustedRemindersGrant, defaultsKey: "AppleAppsMCP.trustedRemindersGrant")
    }

    func permissionStatus(for integration: IntegrationID) -> String {
        switch integration {
        case .calendar: calendarPermission
        case .reminders: remindersPermission
        case .notes, .mail, .music: "Granted on first use"
        case .shortcuts: "Ready"
        }
    }

    func permissionIsAllowed(for integration: IntegrationID) -> Bool {
        permissionStatus(for: integration) == "Allowed"
    }

    func permissionIsDenied(for integration: IntegrationID) -> Bool {
        let status = permissionStatus(for: integration)
        return status == "Denied" || status == "Restricted"
    }

    /// Opens the relevant System Settings privacy pane. Used when access was
    /// already denied — macOS will not re-show the permission prompt, so the
    /// only path forward is for the user to flip it in System Settings.
    func openPrivacySettings(for integration: IntegrationID) {
        let anchor: String
        switch integration {
        case .calendar: anchor = "Privacy_Calendars"
        case .reminders: anchor = "Privacy_Reminders"
        default: anchor = "Privacy"
        }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") {
            NSWorkspace.shared.open(url)
        }
        feedback = SetupFeedback(kind: .info, message: "Enable \(integration.title) for Apple Apps MCP in System Settings → Privacy & Security, then return here.")
    }

    func requestPermission(for integration: IntegrationID) {
        // After a denial macOS won't prompt again — send the user to Settings instead.
        if permissionIsDenied(for: integration) {
            openPrivacySettings(for: integration)
            return
        }
        let eventStore = EKEventStore()
        Task {
            do {
                var granted: Bool?
                switch integration {
                case .calendar:
                    granted = try await eventStore.requestFullAccessToEvents()
                case .reminders:
                    granted = try await eventStore.requestFullAccessToReminders()
                default:
                    feedback = SetupFeedback(kind: .info, message: "\(integration.title) asks macOS for Automation permission the first time a tool runs.")
                }
                if let granted {
                    setPermissionStatus(integration, granted: granted)
                }
                schedulePermissionRefreshes()
            } catch {
                feedback = SetupFeedback(kind: .error, message: error.localizedDescription)
            }
        }
    }

    func revokePermission(for integration: IntegrationID) {
        guard integration == .calendar || integration == .reminders else { return }
        let service = integration == .calendar ? "Calendar" : "Reminders"
        let appBundleID = Bundle.main.bundleIdentifier ?? "com.callummatthews.apple-apps-mcp"
        let helperBundleID = "\(appBundleID).helper"

        let command = """
        /usr/bin/tccutil reset \(service.shellEscaped) \(appBundleID.shellEscaped) >/dev/null 2>&1 || true
        /usr/bin/tccutil reset \(service.shellEscaped) \(helperBundleID.shellEscaped) >/dev/null 2>&1 || true
        """
        runShell("/bin/zsh", ["-lc", command], marksOnboardingComplete: false)
        setTrustedGrant(integration, trusted: false)
        setPermissionStatus(integration, granted: false)
        feedback = SetupFeedback(kind: .info, message: "\(integration.title) permission was revoked. macOS may take a moment to update System Settings.")
        schedulePermissionRefreshes()
    }

    private func setPermissionStatus(_ integration: IntegrationID, granted: Bool) {
        setTrustedGrant(integration, trusted: granted)
        switch integration {
        case .calendar:
            calendarPermission = granted ? "Allowed" : "Not requested"
        case .reminders:
            remindersPermission = granted ? "Allowed" : "Not requested"
        default:
            break
        }
    }

    private func setTrustedGrant(_ integration: IntegrationID, trusted: Bool) {
        switch integration {
        case .calendar:
            trustedCalendarGrant = trusted
            UserDefaults.standard.set(trusted, forKey: "AppleAppsMCP.trustedCalendarGrant")
        case .reminders:
            trustedRemindersGrant = trusted
            UserDefaults.standard.set(trusted, forKey: "AppleAppsMCP.trustedRemindersGrant")
        default:
            break
        }
    }

    private func reconcilePermission(polled: String, trusted: inout Bool, defaultsKey: String) -> String {
        switch polled {
        case "Allowed":
            trusted = true
            UserDefaults.standard.set(true, forKey: defaultsKey)
            return "Allowed"
        default:
            // Never claim "Allowed" when the OS reports anything else. A stale
            // trusted-grant cache previously masked a revoked/notDetermined
            // state, so the UI said Allowed while every actual call was denied.
            // Clear the cache and surface the real status.
            if trusted {
                trusted = false
                UserDefaults.standard.set(false, forKey: defaultsKey)
            }
            return polled
        }
    }

    private func schedulePermissionRefreshes() {
        refreshPermissions()
        for delay in [0.4, 1.0, 2.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.refreshPermissions()
            }
        }
    }

    private var serverPath: String {
        if let bundledServer = Bundle.main.resourceURL?
            .appendingPathComponent("dist/mcp/index.js"),
           FileManager.default.fileExists(atPath: bundledServer.path) {
            return bundledServer.path
        }

        return Bundle.main.bundleURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("dist/mcp/index.js").path
    }

    func installPreferredClient() {
        save()
        let server = serverPath
        switch config.preferredClient {
        case .codexCLI:
            runShell("/bin/zsh", ["-lc", "codex mcp remove apple-apps >/dev/null 2>&1 || true; codex mcp add apple-apps -- node \(server.shellEscaped)"],
                     successMessage: "Registered apple-apps with Codex CLI.")
        case .claudeCLI:
            runShell("/bin/zsh", ["-lc", "claude mcp remove apple-apps >/dev/null 2>&1 || true; claude mcp add apple-apps -- node \(server.shellEscaped)"],
                     successMessage: "Registered apple-apps with Claude Code.")
        case .codexApp:
            writeCodexAppConfig(server: server)
        case .claudeApp:
            writeClaudeDesktopConfig(server: server)
        case .raycast, .manual:
            let json = """
            {
              "mcpServers": {
                "apple-apps": {
                  "command": "node",
                  "args": ["\(server)"]
                }
              }
            }
            """
            feedback = SetupFeedback(kind: .info, message: "Add this MCP server to \(config.preferredClient.title):", code: json)
        }
    }

    /// Codex desktop app and CLI share ~/.codex/config.toml.
    private func writeCodexAppConfig(server: String) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let configURL = home.appendingPathComponent(".codex/config.toml")
        let block = """
        [mcp_servers.apple-apps]
        command = "node"
        args = ["\(server)"]
        """
        do {
            try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            var contents = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
            if contents.contains("[mcp_servers.apple-apps]") {
                feedback = SetupFeedback(kind: .info, message: "Codex already has the apple-apps server in ~/.codex/config.toml. Restart Codex if it isn't showing up.")
            } else {
                if !contents.isEmpty, !contents.hasSuffix("\n\n") {
                    contents += contents.hasSuffix("\n") ? "\n" : "\n\n"
                }
                contents += block + "\n"
                try contents.write(to: configURL, atomically: true, encoding: .utf8)
                feedback = SetupFeedback(kind: .success, message: "Added apple-apps to ~/.codex/config.toml. Restart the Codex app to load it.")
            }
            config.onboardingComplete = true
            save()
        } catch {
            feedback = SetupFeedback(kind: .error, message: "Could not update Codex config: \(error.localizedDescription)")
        }
    }

    /// Claude Desktop reads ~/Library/Application Support/Claude/claude_desktop_config.json.
    private func writeClaudeDesktopConfig(server: String) {
        let configURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Claude/claude_desktop_config.json")
        do {
            try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            var root: [String: Any] = [:]
            if let data = try? Data(contentsOf: configURL),
               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                root = parsed
            }
            var servers = root["mcpServers"] as? [String: Any] ?? [:]
            servers["apple-apps"] = ["command": "node", "args": [server]]
            root["mcpServers"] = servers
            let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: configURL, options: .atomic)
            feedback = SetupFeedback(kind: .success, message: "Added apple-apps to Claude Desktop. Quit and reopen Claude to load it.")
            config.onboardingComplete = true
            save()
        } catch {
            feedback = SetupFeedback(kind: .error, message: "Could not update Claude Desktop config: \(error.localizedDescription)")
        }
    }

    /// Hand off to Sparkle, which downloads, installs, and relaunches in place.
    func checkForUpdates() {
        UpdaterManager.shared.checkForUpdates()
    }

    private func runShell(_ executable: String, _ arguments: [String], successMessage: String? = nil, marksOnboardingComplete: Bool = true) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if process.terminationStatus == 0 {
                if let successMessage {
                    feedback = SetupFeedback(kind: .success, message: successMessage, code: output.isEmpty ? nil : output)
                }
                if marksOnboardingComplete {
                    config.onboardingComplete = true
                    save()
                }
            } else if !output.isEmpty {
                feedback = SetupFeedback(kind: .error, message: output)
            }
        } catch {
            feedback = SetupFeedback(kind: .error, message: error.localizedDescription)
        }
    }

    private func permissionText(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized, .fullAccess: "Allowed"
        case .denied: "Denied"
        case .notDetermined: "Not requested"
        case .restricted: "Restricted"
        case .writeOnly: "Write only"
        @unknown default: "Unknown"
        }
    }
}

struct BridgeEmptyInput: Codable {}
struct BridgeDateRangeInput: Codable { let start: Date?; let end: Date? }
struct BridgeCalendarCreateInput: Codable {
    let title: String
    let start: Date
    let end: Date
    let notes: String?
    let calendarId: String?
}
struct BridgeReminderListInput: Codable { let completed: Bool? }
struct BridgeReminderCreateInput: Codable {
    let title: String
    let notes: String?
    let dueDate: Date?
    let calendarId: String?
}
struct BridgeReminderCompleteInput: Codable { let id: String }

struct BridgePermissionStatus: Codable {
    let calendar: String
    let reminders: String
    let automation: String
}

struct BridgeEventRecord: Codable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let calendar: String
    let notes: String?
}

struct BridgeReminderRecord: Codable {
    let id: String
    let title: String
    let calendar: String
    let notes: String?
    let dueDate: Date?
    let completed: Bool
}

@MainActor
final class EventKitBridge {
    static let shared = EventKitBridge()

    private let store = EKEventStore()
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 17373
    /// Reports whether the loopback listener is ready (true) or stopped/failed (false).
    var onStateChange: ((Bool) -> Void)?
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    func start() {
        guard listener == nil else { return }
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            // Bind to loopback only. Without this the listener accepts connections
            // from any interface, exposing EventKit access to the local network.
            parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: port)
            let listener = try NWListener(using: parameters)
            listener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.onStateChange?(true)
                    case .failed, .cancelled:
                        self?.onStateChange?(false)
                    default:
                        break
                    }
                }
            }
            listener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor in
                    self?.handle(connection)
                }
            }
            listener.start(queue: .main)
            self.listener = listener
        } catch {
            print("EventKit bridge failed to start: \(error.localizedDescription)")
            onStateChange?(false)
        }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(queue: .main)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1_048_576) { [weak self] data, _, _, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.send(error: error.localizedDescription, status: 500, on: connection)
                    return
                }
                guard let data, let request = String(data: data, encoding: .utf8) else {
                    self.send(error: "Invalid request", status: 400, on: connection)
                    return
                }
                do {
                    let (command, body) = try self.parse(request: request)
                    let response = try await self.perform(command: command, body: body)
                    self.send(json: response, on: connection)
                } catch {
                    self.send(error: error.localizedDescription, status: 500, on: connection)
                }
            }
        }
    }

    private func parse(request: String) throws -> (String, Data) {
        let parts = request.components(separatedBy: "\r\n\r\n")
        guard let header = parts.first, let firstLine = header.split(separator: "\r\n").first else {
            throw BridgeError.invalidRequest
        }
        let tokens = firstLine.split(separator: " ")
        guard tokens.count >= 2 else { throw BridgeError.invalidRequest }
        let command = String(tokens[1]).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let body = parts.dropFirst().joined(separator: "\r\n\r\n")
        return (command, Data(body.utf8))
    }

    private func perform(command: String, body: Data) async throws -> Data {
        switch command {
        case "permissions-status":
            return try encode(BridgePermissionStatus(
                calendar: permissionText(EKEventStore.authorizationStatus(for: .event)),
                reminders: permissionText(EKEventStore.authorizationStatus(for: .reminder)),
                automation: "requested-per-app"
            ))
        case "request-permission":
            let input = try decoder.decode(PermissionTargetInput.self, from: body)
            return try await encode(requestPermission(target: input.target))
        case "calendar-list-events":
            return try encode(listEvents(try decoder.decode(BridgeDateRangeInput.self, from: body)))
        case "calendar-create-event":
            return try encode(createEvent(try decoder.decode(BridgeCalendarCreateInput.self, from: body)))
        case "reminders-list":
            return try await encode(listReminders(try decoder.decode(BridgeReminderListInput.self, from: body)))
        case "reminders-create":
            return try encode(createReminder(try decoder.decode(BridgeReminderCreateInput.self, from: body)))
        case "reminders-complete":
            return try encode(completeReminder(try decoder.decode(BridgeReminderCompleteInput.self, from: body)))
        default:
            throw BridgeError.unknownCommand(command)
        }
    }

    private func requestPermission(target: String) async throws -> [String: String] {
        switch target {
        case "calendar":
            let granted = try await store.requestFullAccessToEvents()
            return ["target": target, "status": granted ? "authorized" : "denied"]
        case "reminders":
            let granted = try await store.requestFullAccessToReminders()
            return ["target": target, "status": granted ? "authorized" : "denied"]
        default:
            throw BridgeError.unknownCommand(target)
        }
    }

    private func listEvents(_ input: BridgeDateRangeInput) throws -> [BridgeEventRecord] {
        try ensureAccess(.event)
        let start = input.start ?? Date()
        let end = input.end ?? Calendar.current.date(byAdding: .day, value: 7, to: start)!
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        return store.events(matching: predicate).map {
            BridgeEventRecord(
                id: $0.eventIdentifier ?? "",
                title: $0.title ?? "",
                start: $0.startDate,
                end: $0.endDate,
                calendar: $0.calendar.title,
                notes: $0.notes
            )
        }
    }

    private func createEvent(_ input: BridgeCalendarCreateInput) throws -> BridgeEventRecord {
        try ensureAccess(.event)
        let event = EKEvent(eventStore: store)
        event.title = input.title
        event.startDate = input.start
        event.endDate = input.end
        event.notes = input.notes
        event.calendar = input.calendarId.flatMap { store.calendar(withIdentifier: $0) } ?? store.defaultCalendarForNewEvents
        try store.save(event, span: .thisEvent, commit: true)
        return BridgeEventRecord(id: event.eventIdentifier ?? "", title: event.title ?? "", start: event.startDate, end: event.endDate, calendar: event.calendar.title, notes: event.notes)
    }

    private func listReminders(_ input: BridgeReminderListInput) async throws -> [BridgeReminderRecord] {
        try ensureAccess(.reminder)
        let calendars = store.calendars(for: .reminder)
        let predicate = input.completed == true
            ? store.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: calendars)
            : store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
        return await withCheckedContinuation { continuation in
            // EventKit invokes this completion on its own background queue
            // (com.apple.eventkit.reminders.search). Marking it @Sendable keeps it
            // off the @MainActor isolation it would otherwise inherit, avoiding a
            // Swift 6 executor-assertion crash when the callback fires off-main.
            store.fetchReminders(matching: predicate) { @Sendable reminders in
                let records = (reminders ?? []).map { reminder in
                    BridgeReminderRecord(
                        id: reminder.calendarItemIdentifier,
                        title: reminder.title ?? "",
                        calendar: reminder.calendar.title,
                        notes: reminder.notes,
                        dueDate: reminder.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
                        completed: reminder.isCompleted
                    )
                }
                continuation.resume(returning: records)
            }
        }
    }

    private func createReminder(_ input: BridgeReminderCreateInput) throws -> BridgeReminderRecord {
        try ensureAccess(.reminder)
        let reminder = EKReminder(eventStore: store)
        reminder.title = input.title
        reminder.notes = input.notes
        reminder.calendar = input.calendarId.flatMap { store.calendar(withIdentifier: $0) } ?? store.defaultCalendarForNewReminders()
        if let dueDate = input.dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        try store.save(reminder, commit: true)
        return BridgeReminderRecord(id: reminder.calendarItemIdentifier, title: reminder.title ?? "", calendar: reminder.calendar.title, notes: reminder.notes, dueDate: input.dueDate, completed: reminder.isCompleted)
    }

    private func completeReminder(_ input: BridgeReminderCompleteInput) throws -> [String: String] {
        try ensureAccess(.reminder)
        guard let reminder = store.calendarItem(withIdentifier: input.id) as? EKReminder else {
            throw BridgeError.notFound("Reminder")
        }
        reminder.isCompleted = true
        reminder.completionDate = Date()
        try store.save(reminder, commit: true)
        return ["id": input.id, "completed": "true"]
    }

    private func ensureAccess(_ entity: EKEntityType) throws {
        if EKEventStore.authorizationStatus(for: entity) != .fullAccess {
            throw BridgeError.notAuthorized(entity == .event ? "Calendar" : "Reminders")
        }
    }

    private func permissionText(_ status: EKAuthorizationStatus) -> String {
        switch status {
        case .authorized, .fullAccess: "Allowed"
        case .denied: "Denied"
        case .notDetermined: "Not requested"
        case .restricted: "Restricted"
        case .writeOnly: "Write only"
        @unknown default: "Unknown"
        }
    }

    private func encode<T: Encodable>(_ value: T) throws -> Data {
        try encoder.encode(value)
    }

    private func send(json: Data, on connection: NWConnection) {
        let header = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: \(json.count)\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(header.utf8) + json, completion: .contentProcessed { _ in connection.cancel() })
    }

    private func send(error: String, status: Int, on connection: NWConnection) {
        let body = (try? encoder.encode(["error": error])) ?? Data("{\"error\":\"Unknown error\"}".utf8)
        let header = "HTTP/1.1 \(status) Error\r\nContent-Type: application/json\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
        connection.send(content: Data(header.utf8) + body, completion: .contentProcessed { _ in connection.cancel() })
    }
}

struct PermissionTargetInput: Codable { let target: String }

enum BridgeError: LocalizedError {
    case invalidRequest
    case unknownCommand(String)
    case notAuthorized(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest: "Invalid bridge request"
        case .unknownCommand(let command): "Unknown bridge command: \(command)"
        case .notAuthorized(let target): "\(target) access is not authorized. Open the Apple MCP app, go to \(target), and grant access — then try again."
        case .notFound(let item): "\(item) was not found"
        }
    }
}

extension String {
    var shellEscaped: String {
        "'" + replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

// MARK: - Settings window

/// Hosts the settings UI in a programmatically-created `NSWindow` with
/// `.fullSizeContentView`, which is what lets macOS 26 render the Liquid Glass
/// window chrome (rounded corners, translucent title bar). A SwiftUI `Settings`
/// scene cannot expose the style mask, so we own the window directly.
@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    private static var shared: SettingsWindowController?

    static func show(store: AppStore) {
        AppDelegate.activateForWindow()
        if let existing = shared {
            existing.showWindow(nil)
            existing.window?.makeKeyAndOrderFront(nil)
            return
        }
        let controller = SettingsWindowController(store: store)
        shared = controller
        controller.showWindow(nil)
    }

    init(store: AppStore) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.titlebarAppearsTransparent = true
        window.toolbarStyle = .unified
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 540, height: 500))
        window.center()
        window.setFrameAutosaveName("AppleAppsMCPSettingsWindow")

        let host = NSHostingController(rootView: SettingsView().environment(store))
        window.contentViewController = host

        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func windowWillClose(_ notification: Notification) {
        Self.shared = nil
    }
}

/// Drives the app's Dock presence. The app is really a menu bar agent: closing
/// the main window should leave it running in the menu bar, not sitting in the
/// Dock. We start as a regular app (so the window and Dock icon appear on
/// launch), then drop to `.accessory` once no ordinary window is visible, and
/// pop back to `.regular` whenever a window is reopened.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Holding the shared updater here ensures its SPUStandardUpdaterController is
    // created before launch finishes, as Sparkle requires.
    private let updater = UpdaterManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
        updater.start()
    }

    /// Keep the process alive when the user closes the last window — it stays
    /// active in the menu bar.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func windowWillClose(_ notification: Notification) {
        // Re-evaluate after the window has actually gone away.
        DispatchQueue.main.async { Self.updateDockVisibility() }
    }

    /// Show the Dock icon and bring the app forward — call before opening a window.
    static func activateForWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Drop the Dock icon when only the menu bar remains; keep it while any
    /// ordinary (titled) window is still on screen.
    static func updateDockVisibility() {
        let hasVisibleWindow = NSApp.windows.contains { window in
            window.isVisible && window.styleMask.contains(.titled)
        }
        NSApp.setActivationPolicy(hasVisibleWindow ? .regular : .accessory)
    }
}

@main
struct AppleAppsControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = AppStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup("Apple Apps MCP", id: "main") {
            RootView()
                .environment(store)
                .task { store.load() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        store.refreshPermissions()
                    }
                }
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    SettingsWindowController.show(store: store)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    store.checkForUpdates()
                }
            }
        }

        MenuBarExtra("Apple Apps MCP", systemImage: "bolt.horizontal.circle") {
            MenuBarPanel()
                .environment(store)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - Root switch (onboarding vs main)

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            if store.config.onboardingComplete {
                ContentView()
                    .frame(minWidth: 880, minHeight: 620)
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .frame(width: 760, height: 560)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.03))
                    ))
            }
        }
        .animation(.smooth(duration: 0.5), value: store.config.onboardingComplete)
        .background(WindowFrameConfigurator(isOnboarding: !store.config.onboardingComplete))
    }
}

struct WindowFrameConfigurator: NSViewRepresentable {
    let isOnboarding: Bool

    func makeNSView(context: Context) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }
            if isOnboarding {
                let target = NSSize(width: 760, height: 560)
                window.minSize = target
                window.maxSize = target
                if abs(window.frame.size.width - target.width) > 2 || abs(window.frame.size.height - target.height) > 2 {
                    var frame = window.frame
                    let center = NSPoint(x: frame.midX, y: frame.midY)
                    frame.size = target
                    frame.origin = NSPoint(x: center.x - target.width / 2, y: center.y - target.height / 2)
                    window.setFrame(frame, display: true, animate: true)
                }
            } else {
                window.minSize = NSSize(width: 880, height: 620)
                window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
            }
        }
    }
}

// MARK: - Reusable surface styling

extension View {
    /// Card surface used throughout the app for a clean, layered look.
    func surfaceCard(cornerRadius: CGFloat = 12) -> some View {
        self
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 1)
            )
    }
}

// MARK: - Status pill (the recurring identity anchor)

/// A small Liquid Glass capsule with a glowing status dot. Used identically in
/// the sidebar header, the menu bar, and Settings so the app reads as one
/// coherent "control room" surface — this is the element you'd recognize with
/// the logo cropped out.
struct StatusPill: View {
    let text: String
    let color: Color
    var help: String?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .shadow(color: color.opacity(0.7), radius: 3)
                .shadow(color: color.opacity(0.35), radius: 6)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .glassEffect(.regular, in: .capsule)
        .help(help ?? text)
    }
}

// MARK: - Setup feedback

/// Typed banner for setup results: colored icon + message, with an optional
/// copyable monospace code block (used for JSON config and shell output).
struct SetupFeedbackView: View {
    let feedback: SetupFeedback
    var compact = false
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: feedback.kind.symbol)
                    .font(.system(size: compact ? 12 : 14, weight: .semibold))
                    .foregroundStyle(feedback.kind.tint)
                    .symbolEffect(.pulse, isActive: feedback.kind == .progress)
                Text(feedback.message)
                    .font(compact ? .caption2 : .callout)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                if feedback.code == nil, !compact {
                    copyButton(text: feedback.message)
                }
            }

            if let code = feedback.code {
                ScrollView {
                    Text(code)
                        .font(.system(compact ? .caption2 : .caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: compact ? 90 : 150)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    copyButton(text: code).padding(6)
                }
            }
        }
        .padding(compact ? 10 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(feedback.kind.tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(feedback.kind.tint.opacity(0.25), lineWidth: 1)
        )
    }

    private func copyButton(text: String) -> some View {
        Button {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            withAnimation { copied = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { withAnimation { copied = false } }
        } label: {
            Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                .font(.caption2.weight(.semibold))
                .labelStyle(.titleAndIcon)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help("Copy to clipboard")
    }
}

// MARK: - App branding

enum AppBranding {
    /// The bundled app icon, loaded once. Built into Contents/Resources by the build script.
    static let icon: NSImage? = {
        guard let url = Bundle.main.url(forResource: "AppIcon", withExtension: "png") else { return nil }
        return NSImage(contentsOf: url)
    }()
}

/// Shows the real app icon when bundled, with a gradient bolt glyph fallback.
struct AppBrandIcon: View {
    var size: CGFloat = 38

    var body: some View {
        Group {
            if let icon = AppBranding.icon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                        .fill(LinearGradient(colors: [.accentColor, .accentColor.opacity(0.7)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                    Image(systemName: "bolt.horizontal.fill")
                        .font(.system(size: size * 0.45, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: size * 0.1, y: size * 0.04)
    }
}

// MARK: - Root

struct ContentView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 290, ideal: 320, max: 360)
        } detail: {
            switch store.selection {
            case .integration(let integration):
                IntegrationDetailView(integration: integration)
            case .connect:
                ConnectView()
            case nil:
                ContentUnavailableView("Choose a section", systemImage: "square.grid.2x2")
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.installPreferredClient()
                    store.selection = .connect
                } label: {
                    Label("Install MCP Config", systemImage: "bolt.badge.checkmark")
                }
            }
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        @Bindable var store = store
        VStack(spacing: 0) {
            BrandHeader()
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            List(selection: $store.selection) {
                Section("Setup") {
                    ConnectSidebarRow()
                        .tag(SidebarSelection.connect)
                }

                Section("Apple Apps") {
                    ForEach(IntegrationID.allCases) { integration in
                        IntegrationSidebarRow(integration: integration)
                            .tag(SidebarSelection.integration(integration))
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

struct BrandHeader: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 12) {
            AppBrandIcon(size: 38)

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Apps MCP")
                    .font(.headline)
                StatusPill(
                    text: store.serverStatusText,
                    color: store.serverStatusColor,
                    help: store.bridgeRunning ? "MCP bridge is listening on 127.0.0.1:17373" : "MCP bridge is not running"
                )
            }
            Spacer(minLength: 0)
        }
    }
}

struct ConnectSidebarRow: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 11) {
            ProviderBrandIcon(client: store.config.preferredClient, size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("Connect AI App")
                    .font(.headline)
                Text(store.config.preferredClient.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
    }
}

struct IntegrationSidebarRow: View {
    @Environment(AppStore.self) private var store
    let integration: IntegrationID

    var body: some View {
        let enabled = store.config.integrations[integration] ?? true
        HStack(spacing: 11) {
            MacAppIconView(bundleIdentifier: integration.bundleIdentifier, fallbackSymbol: integration.symbol)
                .frame(width: 30, height: 30)
                .opacity(enabled ? 1 : 0.4)
            VStack(alignment: .leading, spacing: 1) {
                Text(integration.title)
                    .font(.headline)
                Text("\(integration.toolNames.count) tools")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Text(enabled ? "Tools on" : "Tools off")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Toggle("", isOn: Binding(
                get: { store.config.integrations[integration] ?? true },
                set: { store.setEnabled(integration, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
            .accessibilityLabel("\(integration.title) tools")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Integration detail

struct IntegrationDetailView: View {
    @Environment(AppStore.self) private var store
    let integration: IntegrationID

    private var enabled: Bool { store.config.integrations[integration] ?? true }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                hero
                capabilitiesSection
                permissionSection
            }
            .padding(32)
            .frame(maxWidth: 720, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(integration.title)
    }

    private var hero: some View {
        HStack(alignment: .center, spacing: 18) {
            MacAppIconView(bundleIdentifier: integration.bundleIdentifier, fallbackSymbol: integration.symbol)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(integration.title)
                    .font(.system(size: 30, weight: .bold))
                Text(integration.tagline)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Toggle(isOn: Binding(
                get: { enabled },
                set: { store.setEnabled(integration, enabled: $0) }
            )) {
                Text(enabled ? "Tools enabled" : "Tools disabled")
                    .font(.subheadline.weight(.medium))
            }
            .toggleStyle(.switch)
        }
    }

    private var capabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Capabilities", subtitle: "\(integration.toolNames.count) tools your AI app can call")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 12)], spacing: 12) {
                ForEach(integration.tools) { tool in
                    CapabilityCard(tool: tool, tint: integration.tint)
                }
            }
        }
        .opacity(enabled ? 1 : 0.55)
    }

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Permission", subtitle: integration.permissionSummary)
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(permissionColor.opacity(0.15))
                    Image(systemName: permissionIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(permissionColor)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(permissionText)
                        .font(.headline)
                    Text(permissionDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if integration == .calendar || integration == .reminders {
                    Button(permissionActionTitle) {
                        if store.permissionIsAllowed(for: integration) {
                            store.revokePermission(for: integration)
                        } else if store.permissionIsDenied(for: integration) {
                            store.openPrivacySettings(for: integration)
                        } else {
                            store.requestPermission(for: integration)
                        }
                    }
                    .buttonStyle(.glassProminent)
                    .tint(store.permissionIsAllowed(for: integration) ? .red : .accentColor)
                }
            }
            .padding(16)
            .surfaceCard()
        }
    }

    private var permissionText: String {
        store.permissionStatus(for: integration)
    }

    private var permissionActionTitle: String {
        if store.permissionIsAllowed(for: integration) { return "Revoke Access" }
        if store.permissionIsDenied(for: integration) { return "Open System Settings" }
        return "Request Access"
    }

    private var permissionDetail: String {
        switch integration {
        case .calendar, .reminders: "Native macOS permission, managed in System Settings → Privacy."
        case .notes, .mail, .music: "macOS prompts for Automation access the first time a tool runs."
        case .shortcuts: "Runs through /usr/bin/shortcuts — no extra prompt."
        }
    }

    private var permissionColor: Color {
        switch permissionText {
        case "Allowed", "Ready": .green
        case "Denied", "Restricted": .red
        default: .orange
        }
    }

    private var permissionIcon: String {
        switch permissionText {
        case "Allowed", "Ready": "checkmark.shield.fill"
        case "Denied", "Restricted": "xmark.shield.fill"
        default: "lock.shield"
        }
    }
}

struct SectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.title3.weight(.semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct CapabilityCard: View {
    let tool: ToolInfo
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(tint.opacity(0.16))
                    Image(systemName: tool.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                .frame(width: 34, height: 34)
                Spacer(minLength: 0)
                if tool.risky {
                    Label("Confirm", systemImage: "exclamationmark.triangle.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.orange.opacity(0.14), in: Capsule())
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(tool.title)
                    .font(.headline)
                Text(tool.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(tool.raw)
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .surfaceCard()
    }
}

// MARK: - Connect screen

struct ConnectView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connect your AI app")
                        .font(.system(size: 30, weight: .bold))
                    Text("Register the local MCP server with your client. Everything runs locally — you approve every connection.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ClientGrid()

                PrivacyFooter()
            }
            .padding(32)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Connect")
    }
}

struct ClientGrid: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Works with your tools", subtitle: "Choose where the MCP server should be registered.")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), spacing: 12)], spacing: 12) {
                ForEach(PreferredClient.allCases) { client in
                    ProviderCard(
                        client: client,
                        selected: store.config.preferredClient == client
                    ) {
                        store.config.preferredClient = client
                        store.save()
                    }
                }
            }

            HStack(spacing: 14) {
                Button {
                    store.installPreferredClient()
                } label: {
                    Label(store.config.preferredClient.canInstall ? "Install MCP Config" : "Show Config",
                          systemImage: "bolt.badge.checkmark")
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)

                Text(store.config.preferredClient.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let feedback = store.feedback {
                SetupFeedbackView(feedback: feedback)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.smooth(duration: 0.25), value: store.feedback)
    }
}

struct ProviderCard: View {
    let client: PreferredClient
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ProviderBrandIcon(client: client, size: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(client.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(client.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundStyle(selected ? AnyShapeStyle(client.accent) : AnyShapeStyle(.tertiary))
                    Text(client.kind)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(selected ? client.accent.opacity(0.10) : Color(nsColor: .controlBackgroundColor).opacity(0.72),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(selected ? client.accent.opacity(0.75) : Color(nsColor: .separatorColor).opacity(0.45),
                                  lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PrivacyFooter: View {
    private let items: [(String, String)] = [
        ("lock.fill", "Runs locally — data never leaves your Mac"),
        ("hand.raised.fill", "You approve every connection"),
        ("slider.horizontal.3", "Enable or disable any app, anytime")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Private by design")
            HStack(spacing: 12) {
                ForEach(items, id: \.1) { item in
                    HStack(spacing: 9) {
                        Image(systemName: item.0)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                        Text(item.1)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .surfaceCard()
                }
            }
        }
    }
}

// MARK: - Icons

struct MacAppIconView: View {
    let bundleIdentifier: String
    let fallbackSymbol: String

    var body: some View {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
        } else {
            Image(systemName: fallbackSymbol)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
    }
}

/// Renders the real provider mark: the installed app icon when available,
/// otherwise a hand-built brand glyph in the provider's colors.
struct ProviderBrandIcon: View {
    let client: PreferredClient
    var size: CGFloat = 40

    private var installedIcon: NSImage? {
        let ids: [String]
        switch client.brand {
        case .codex: ids = ["com.openai.codex"]
        case .raycast: ids = ["com.raycast.macos"]
        case .claude: ids = ["com.anthropic.claudefordesktop", "com.anthropic.claude"]
        case .generic: ids = []
        }
        for id in ids {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
        }
        return nil
    }

    var body: some View {
        Group {
            if let icon = installedIcon {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
            } else {
                brandTile
            }
        }
        .frame(width: size, height: size)
    }

    private var brandTile: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(tileColor)
            .overlay { glyph.padding(size * 0.22) }
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.18), radius: size * 0.07, y: size * 0.03)
    }

    private var tileColor: Color {
        switch client.brand {
        case .codex: Color(red: 0.07, green: 0.07, blue: 0.08)
        case .claude: Color(red: 0.95, green: 0.93, blue: 0.88)
        case .raycast: Color(red: 1.0, green: 0.39, blue: 0.39)
        case .generic: Color(nsColor: .controlBackgroundColor)
        }
    }

    @ViewBuilder private var glyph: some View {
        switch client.brand {
        case .codex: OpenAIGlyph(color: .white)
        case .claude: ClaudeGlyph(color: Color(red: 0.85, green: 0.45, blue: 0.32))
        case .raycast: RaycastGlyph(color: .white)
        case .generic:
            Image(systemName: "curlybraces")
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }
}

/// Approximation of the OpenAI mark: three interlocking stadium loops.
struct OpenAIGlyph: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Capsule()
                        .stroke(color, lineWidth: s * 0.17)
                        .frame(width: s, height: s * 0.6)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// Anthropic-style radial sunburst.
struct ClaudeGlyph: View {
    var color: Color

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let s = min(size.width, size.height)
            let inner = s * 0.05
            let outer = s * 0.48
            let count = 12
            for i in 0..<count {
                let angle = (Double(i) / Double(count)) * 2 * .pi
                let dx = cos(angle), dy = sin(angle)
                var path = Path()
                path.move(to: CGPoint(x: center.x + dx * inner, y: center.y + dy * inner))
                path.addLine(to: CGPoint(x: center.x + dx * outer, y: center.y + dy * outer))
                ctx.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: s * 0.085, lineCap: .round))
            }
        }
    }
}

/// Geometric Raycast-style ray mark.
struct RaycastGlyph: View {
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: s * 0.12, style: .continuous)
                    .strokeBorder(color, lineWidth: s * 0.13)
                    .frame(width: s * 0.6, height: s * 0.6)
                    .rotationEffect(.degrees(45))
                RoundedRectangle(cornerRadius: s * 0.07, style: .continuous)
                    .fill(color)
                    .frame(width: s * 0.22, height: s * 0.22)
                    .rotationEffect(.degrees(45))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Settings scene

struct SettingsView: View {
    @Environment(AppStore.self) private var store

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        @Bindable var store = store
        Form {
            Section("Connection") {
                Picker("AI app", selection: $store.config.preferredClient) {
                    ForEach(PreferredClient.allCases) { client in
                        Text(client.title).tag(client)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: store.config.preferredClient) { store.save() }

                LabeledContent("Registration") {
                    Button(store.config.preferredClient.canInstall ? "Install MCP Config" : "Show Config") {
                        store.installPreferredClient()
                    }
                    .controlSize(.small)
                }

                Text(store.config.preferredClient.tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("MCP server") {
                LabeledContent("Status") {
                    StatusPill(text: store.bridgeRunning ? "Running" : "Not running",
                               color: store.serverStatusColor)
                }
                LabeledContent("Address", value: "127.0.0.1:17373")
                LabeledContent("Tools enabled", value: "\(store.totalEnabledTools)")
            }

            if let feedback = store.feedback {
                Section {
                    SetupFeedbackView(feedback: feedback)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section("About") {
                LabeledContent("Version", value: appVersion)
                Button("Check for Updates…") { store.checkForUpdates() }
                    .controlSize(.small)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 12, for: .scrollContent)
        .animation(.smooth(duration: 0.25), value: store.feedback)
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @Environment(AppStore.self) private var store

    @State private var step = 0
    @State private var forward = true
    private let stepCount = 5

    var body: some View {
        VStack(spacing: 0) {
            onboardingToolbar
            Divider()
            stepContent
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                    removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)
                ))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            Divider()
            footer
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var onboardingToolbar: some View {
        HStack(spacing: 12) {
            AppBrandIcon(size: 32)
            VStack(alignment: .leading, spacing: 1) {
                Text("Apple MCP")
                    .font(.headline)
                Text("On-device control for Apple apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            OnboardingDots(count: stepCount, current: step)
            Spacer()
            if step < stepCount - 1 {
                Button("Skip") { finish() }
                    .buttonStyle(.plain)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 58, alignment: .trailing)
            } else {
                Color.clear.frame(width: 58)
            }
        }
        .padding(.horizontal, 24)
        .frame(height: 72)
        .background(.bar)
    }

    private var footer: some View {
        HStack {
            if step > 0 {
                Button(action: back) {
                    Label("Back", systemImage: "chevron.left")
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
            Spacer()
            Text(step == 0 ? "Everything stays local on this Mac." : "\(store.totalEnabledTools) MCP tools enabled")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(action: primaryAction) {
                Text(primaryTitle).frame(minWidth: 112)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 24)
        .frame(height: 76)
        .background(.bar)
    }

    @ViewBuilder private var stepContent: some View {
        switch step {
        case 0: WelcomeStep()
        case 1: CapabilitiesStep()
        case 2: PermissionsStep()
        case 3: ConnectStep()
        default: FinishStep()
        }
    }

    private var primaryTitle: String {
        switch step {
        case 0: "Get Started"
        case stepCount - 1: "Open Apple Apps MCP"
        default: "Continue"
        }
    }

    private func primaryAction() {
        if step == stepCount - 1 { finish(); return }
        forward = true
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step += 1 }
    }

    private func back() {
        forward = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { step -= 1 }
    }

    private func finish() {
        store.completeOnboarding()
    }
}

struct OnboardingDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == current ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.secondary.opacity(0.3)))
                    .frame(width: i == current ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: current)
    }
}

struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 7) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
            Text(subtitle)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 24)
    }
}

struct WelcomeStep: View {
    @State private var appear = false

    var body: some View {
        HStack(spacing: 34) {
            VStack(alignment: .leading, spacing: 22) {
                AppBrandIcon(size: 80)
                    .scaleEffect(appear ? 1 : 0.8)
                    .opacity(appear ? 1 : 0)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Apple app control")
                        .font(.system(size: 38, weight: .bold))
                        .lineLimit(2)
                    Text("Give Codex, Claude, Raycast, and other MCP clients local access to Calendar, Reminders, Notes, Mail, Shortcuts, and Music.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    TrustLine(icon: "lock.fill", text: "Runs locally on your Mac")
                    TrustLine(icon: "checkmark.shield.fill", text: "Native permissions stay under your control")
                    TrustLine(icon: "bolt.horizontal.fill", text: "19 MCP tools ready to connect")
                }
            }

            AppPreviewPanel()
                .frame(width: 280)
        }
        .padding(42)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05)) { appear = true }
        }
    }
}

struct TrustLine: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 18)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct AppPreviewPanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Native integrations")
                .font(.headline)
            ForEach([IntegrationID.calendar, .mail, .notes, .reminders], id: \.self) { integration in
                HStack(spacing: 10) {
                    MacAppIconView(bundleIdentifier: integration.bundleIdentifier, fallbackSymbol: integration.symbol)
                        .frame(width: 30, height: 30)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(integration.title)
                            .font(.subheadline.weight(.medium))
                        Text("\(integration.toolNames.count) tools")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .padding(10)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .surfaceCard(cornerRadius: 16)
    }
}

struct CapabilitiesStep: View {
    var body: some View {
        VStack(spacing: 18) {
            StepHeader(title: "Enable Capabilities",
                       subtitle: "Pick the Apple apps your AI clients are allowed to use.")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 12)], spacing: 12) {
                ForEach(IntegrationID.allCases) { integration in
                    OnboardingCapabilityRow(integration: integration)
                }
            }
            .padding(.horizontal, 44)
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 26)
    }
}

struct OnboardingCapabilityRow: View {
    @Environment(AppStore.self) private var store
    let integration: IntegrationID

    var body: some View {
        let enabled = store.config.integrations[integration] ?? true
        HStack(spacing: 12) {
            MacAppIconView(bundleIdentifier: integration.bundleIdentifier, fallbackSymbol: integration.symbol)
                .frame(width: 34, height: 34)
                .opacity(enabled ? 1 : 0.45)
            VStack(alignment: .leading, spacing: 2) {
                Text(integration.title).font(.headline)
                Text("\(integration.toolNames.count) tools")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: Binding(
                get: { enabled },
                set: { store.setEnabled(integration, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .accessibilityLabel("\(integration.title) tools")
        }
        .padding(14)
        .background(enabled ? Color(nsColor: .controlBackgroundColor).opacity(0.72) : Color(nsColor: .controlBackgroundColor).opacity(0.36),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.45), lineWidth: 1)
        )
    }
}

struct PermissionsStep: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 18) {
            StepHeader(title: "Grant Permissions",
                       subtitle: "Calendar and Reminders use native macOS access. Other apps ask on first use.")
            VStack(spacing: 10) {
                OnboardingPermissionRow(title: "Calendar", status: store.calendarPermission, icon: "calendar") {
                    store.requestPermission(for: .calendar)
                }
                OnboardingPermissionRow(title: "Reminders", status: store.remindersPermission, icon: "checklist") {
                    store.requestPermission(for: .reminders)
                }
                HStack(spacing: 10) {
                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                    Text("Notes, Mail, Music, and Shortcuts request Automation permission automatically the first time a tool runs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .frame(width: 520)
        }
        .padding(.top, 32)
        .task { store.refreshPermissions() }
    }
}

struct OnboardingPermissionRow: View {
    let title: String
    let status: String
    let icon: String
    let request: () -> Void

    private var granted: Bool { status == "Allowed" }
    private var denied: Bool { status == "Denied" || status == "Restricted" }
    private var accent: Color { granted ? .green : (denied ? .red : .orange) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(accent.opacity(0.15))
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accent)
            }
            .frame(width: 38, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(granted ? "Allowed" : status).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if granted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title3)
            } else {
                Button(denied ? "Settings" : "Allow", action: request)
                    .buttonStyle(.glassProminent)
                    .controlSize(.small)
            }
        }
        .padding(12)
        .surfaceCard()
    }
}

struct ConnectStep: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 18) {
            StepHeader(title: "Connect your AI app",
                       subtitle: "Pick where to register the local MCP server.")
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ForEach(PreferredClient.allCases) { client in
                    ProviderCard(client: client, selected: store.config.preferredClient == client) {
                        store.config.preferredClient = client
                        store.save()
                    }
                }
            }
            .padding(.horizontal, 44)

            VStack(spacing: 8) {
                Button {
                    store.installPreferredClient()
                } label: {
                    Label(store.config.preferredClient.canInstall ? "Install MCP Config" : "Show Config",
                          systemImage: "bolt.badge.checkmark")
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)

                if let feedback = store.feedback {
                    SetupFeedbackView(feedback: feedback)
                        .padding(.horizontal, 44)
                        .transition(.opacity)
                }
            }
            .animation(.smooth(duration: 0.25), value: store.feedback)
        }
        .padding(.top, 26)
    }
}

struct FinishStep: View {
    @Environment(AppStore.self) private var store
    @State private var appear = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)
            ZStack {
                Circle().fill(Color.green.opacity(0.15)).frame(width: 88, height: 88)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.green)
                    .scaleEffect(appear ? 1 : 0.4)
                    .opacity(appear ? 1 : 0)
            }
            VStack(spacing: 10) {
                Text("You're all set")
                    .font(.system(size: 27, weight: .bold))
                Text("\(store.totalEnabledTools) tools active · Connected to \(store.config.preferredClient.title).")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 30)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) { appear = true }
        }
    }
}

// MARK: - Menu bar panel

struct MenuBarPanel: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                AppBrandIcon(size: 34)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Apps MCP").font(.headline)
                    StatusPill(
                        text: store.serverStatusText,
                        color: store.serverStatusColor,
                        help: store.bridgeRunning ? "MCP bridge is listening on 127.0.0.1:17373" : "MCP bridge is not running"
                    )
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider().padding(.horizontal, 12)

            MenuSectionLabel("Apple Apps")
            VStack(spacing: 1) {
                ForEach(IntegrationID.allCases) { integration in
                    MenuToggleRow(integration: integration)
                }
            }
            .padding(.bottom, 6)

            Divider().padding(.horizontal, 12)

            MenuSectionLabel("Connection")
            MenuConnectionRow {
                store.selection = .connect
                openMain()
            }
            .padding(.bottom, 6)

            Divider().padding(.horizontal, 12)

            VStack(spacing: 1) {
                MenuActionButton(title: "Open Apple Apps MCP", icon: "macwindow") { openMain() }
                MenuActionButton(title: "Settings…", icon: "gearshape") {
                    SettingsWindowController.show(store: store)
                }
                MenuActionButton(title: "Install MCP Config", icon: "bolt.badge.checkmark") { store.installPreferredClient() }
                MenuActionButton(title: "Refresh Permissions", icon: "arrow.clockwise") { store.refreshPermissions() }
                MenuActionButton(title: "Check for Updates", icon: "arrow.down.circle") { store.checkForUpdates() }
                MenuActionButton(title: "Run Setup Again", icon: "sparkles") {
                    store.restartOnboarding()
                    openMain()
                }
                if let feedback = store.feedback {
                    SetupFeedbackView(feedback: feedback, compact: true)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                }
                Divider().padding(.vertical, 3).padding(.horizontal, 6)
                MenuActionButton(title: "Quit", icon: "power", role: .destructive) { NSApp.terminate(nil) }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
        }
        .frame(width: 320)
    }

    private func openMain() {
        AppDelegate.activateForWindow()
        openWindow(id: "main")
    }
}

struct MenuSectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.6)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MenuToggleRow: View {
    @Environment(AppStore.self) private var store
    let integration: IntegrationID
    @State private var hover = false

    var body: some View {
        let enabled = store.config.integrations[integration] ?? true
        HStack(spacing: 10) {
            MacAppIconView(bundleIdentifier: integration.bundleIdentifier, fallbackSymbol: integration.symbol)
                .frame(width: 20, height: 20)
            Text(integration.title).font(.subheadline)
            Spacer(minLength: 0)
            Toggle("", isOn: Binding(
                get: { enabled },
                set: { store.setEnabled(integration, enabled: $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .controlSize(.mini)
            .accessibilityLabel("\(integration.title) tools")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(hover ? Color.primary.opacity(0.06) : Color.clear,
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .padding(.horizontal, 6)
        .onHover { hover = $0 }
    }
}

struct MenuConnectionRow: View {
    @Environment(AppStore.self) private var store
    let action: () -> Void
    @State private var hover = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ProviderBrandIcon(client: store.config.preferredClient, size: 26)
                VStack(alignment: .leading, spacing: 1) {
                    Text(store.config.preferredClient.title)
                        .font(.subheadline.weight(.medium))
                    Text("Connected · \(store.config.preferredClient.kind)")
                        .font(.caption2).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .contentShape(Rectangle())
            .background(hover ? Color.primary.opacity(0.06) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .padding(.horizontal, 6)
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}

struct MenuActionButton: View {
    let title: String
    let icon: String
    var role: ButtonRole? = nil
    let action: () -> Void
    @State private var hover = false

    private var tint: Color { role == .destructive ? .red : .accentColor }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .frame(width: 18)
                    .foregroundStyle(hover ? AnyShapeStyle(tint) : AnyShapeStyle(.secondary))
                Text(title).font(.subheadline)
                    .foregroundStyle(role == .destructive && hover ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(hover ? tint.opacity(0.12) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hover = $0 }
    }
}
