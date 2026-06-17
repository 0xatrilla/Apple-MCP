@preconcurrency import EventKit
import Foundation

struct JSON {
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static func read<T: Decodable>(_ type: T.Type) throws -> T {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        if data.isEmpty {
            return try decoder.decode(T.self, from: Data("{}".utf8))
        }
        return try decoder.decode(T.self, from: data)
    }

    static func write<T: Encodable>(_ value: T) throws {
        FileHandle.standardOutput.write(try encoder.encode(value))
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
}

struct EmptyInput: Codable {}
struct PermissionInput: Codable { let target: String }
struct DateRangeInput: Codable { let start: Date?; let end: Date? }
struct CalendarCreateInput: Codable {
    let title: String
    let start: Date
    let end: Date
    let notes: String?
    let calendarId: String?
}
struct ReminderListInput: Codable { let completed: Bool? }
struct ReminderCreateInput: Codable {
    let title: String
    let notes: String?
    let dueDate: Date?
    let calendarId: String?
}
struct ReminderCompleteInput: Codable { let id: String }

struct PermissionStatus: Codable, Sendable {
    let calendar: String
    let reminders: String
    let automation: String
}

struct EventRecord: Codable, Sendable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let calendar: String
    let notes: String?
}

struct ReminderRecord: Codable, Sendable {
    let id: String
    let title: String
    let calendar: String
    let notes: String?
    let dueDate: Date?
    let completed: Bool
}

enum HelperError: Error, LocalizedError {
    case invalidCommand(String)
    case invalidTarget(String)
    case notAuthorized(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .invalidCommand(let command): "Unknown helper command: \(command)"
        case .invalidTarget(let target): "Unknown permission target: \(target)"
        case .notAuthorized(let target): "\(target) access is not authorized"
        case .notFound(let item): "\(item) was not found"
        }
    }
}

let store = EKEventStore()

func statusString(_ status: EKAuthorizationStatus) -> String {
    switch status {
    case .authorized: "authorized"
    case .denied: "denied"
    case .fullAccess: "fullAccess"
    case .notDetermined: "notDetermined"
    case .restricted: "restricted"
    case .writeOnly: "writeOnly"
    @unknown default: "unknown"
    }
}

@MainActor
func ensureAccess(_ entity: EKEntityType) async throws {
    let status = EKEventStore.authorizationStatus(for: entity)
    if status == .fullAccess {
        return
    }
    throw HelperError.notAuthorized(entity == .event ? "Calendar" : "Reminders")
}

@MainActor
func requestAccess(target: String) async throws -> [String: String] {
    switch target {
    case "calendar":
        let granted = try await store.requestFullAccessToEvents()
        return ["target": target, "status": granted ? "authorized" : "denied"]
    case "reminders":
        let granted = try await store.requestFullAccessToReminders()
        return ["target": target, "status": granted ? "authorized" : "denied"]
    default:
        throw HelperError.invalidTarget(target)
    }
}

@MainActor
func listEvents(_ input: DateRangeInput) async throws -> [EventRecord] {
    try await ensureAccess(.event)
    let start = input.start ?? Date()
    let end = input.end ?? Calendar.current.date(byAdding: .day, value: 7, to: start)!
    let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
    return store.events(matching: predicate).map {
        EventRecord(
            id: $0.eventIdentifier ?? "",
            title: $0.title ?? "",
            start: $0.startDate,
            end: $0.endDate,
            calendar: $0.calendar.title,
            notes: $0.notes
        )
    }
}

@MainActor
func createEvent(_ input: CalendarCreateInput) async throws -> EventRecord {
    try await ensureAccess(.event)
    let event = EKEvent(eventStore: store)
    event.title = input.title
    event.startDate = input.start
    event.endDate = input.end
    event.notes = input.notes
    event.calendar = input.calendarId.flatMap { store.calendar(withIdentifier: $0) } ?? store.defaultCalendarForNewEvents
    try store.save(event, span: .thisEvent, commit: true)
    return EventRecord(
        id: event.eventIdentifier ?? "",
        title: event.title ?? "",
        start: event.startDate,
        end: event.endDate,
        calendar: event.calendar.title,
        notes: event.notes
    )
}

@MainActor
func fetchReminderRecords(matching predicate: NSPredicate) async -> [ReminderRecord] {
    await withCheckedContinuation { continuation in
        // EventKit fires this completion on its own background queue; @Sendable
        // keeps it off the inherited @MainActor isolation to avoid a Swift 6
        // executor-assertion crash when the callback runs off-main.
        store.fetchReminders(matching: predicate) { @Sendable reminders in
            let records = (reminders ?? []).map { reminder in
                ReminderRecord(
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

@MainActor
func listReminders(_ input: ReminderListInput) async throws -> [ReminderRecord] {
    try await ensureAccess(.reminder)
    let calendars = store.calendars(for: .reminder)
    let predicate: NSPredicate
    if input.completed == true {
        predicate = store.predicateForCompletedReminders(withCompletionDateStarting: nil, ending: nil, calendars: calendars)
    } else {
        predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: calendars)
    }
    return await fetchReminderRecords(matching: predicate)
}

@MainActor
func createReminder(_ input: ReminderCreateInput) async throws -> ReminderRecord {
    try await ensureAccess(.reminder)
    let reminder = EKReminder(eventStore: store)
    reminder.title = input.title
    reminder.notes = input.notes
    reminder.calendar = input.calendarId.flatMap { store.calendar(withIdentifier: $0) } ?? store.defaultCalendarForNewReminders()
    if let dueDate = input.dueDate {
        reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
    }
    try store.save(reminder, commit: true)
    return ReminderRecord(
        id: reminder.calendarItemIdentifier,
        title: reminder.title ?? "",
        calendar: reminder.calendar.title,
        notes: reminder.notes,
        dueDate: input.dueDate,
        completed: reminder.isCompleted
    )
}

@MainActor
func completeReminder(_ input: ReminderCompleteInput) async throws -> [String: String] {
    try await ensureAccess(.reminder)
    guard let reminder = store.calendarItem(withIdentifier: input.id) as? EKReminder else {
        throw HelperError.notFound("Reminder")
    }
    reminder.isCompleted = true
    reminder.completionDate = Date()
    try store.save(reminder, commit: true)
    return ["id": input.id, "completed": "true"]
}

@MainActor
func main() async throws {
    let command = CommandLine.arguments.dropFirst().first ?? "permissions-status"
    switch command {
    case "permissions-status":
        try JSON.write(PermissionStatus(
            calendar: statusString(EKEventStore.authorizationStatus(for: .event)),
            reminders: statusString(EKEventStore.authorizationStatus(for: .reminder)),
            automation: "requested-per-app"
        ))
    case "request-permission":
        try await JSON.write(requestAccess(target: JSON.read(PermissionInput.self).target))
    case "calendar-list-events":
        try await JSON.write(listEvents(JSON.read(DateRangeInput.self)))
    case "calendar-create-event":
        try await JSON.write(createEvent(JSON.read(CalendarCreateInput.self)))
    case "reminders-list":
        try await JSON.write(listReminders(JSON.read(ReminderListInput.self)))
    case "reminders-create":
        try await JSON.write(createReminder(JSON.read(ReminderCreateInput.self)))
    case "reminders-complete":
        try await JSON.write(completeReminder(JSON.read(ReminderCompleteInput.self)))
    default:
        throw HelperError.invalidCommand(command)
    }
}

do {
    try await main()
} catch {
    let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(1)
}
