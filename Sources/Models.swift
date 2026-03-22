import Foundation

// MARK: - Task

struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var estimatedHours: Double
    var deadline: Date
    var normalHoursPerDay: Double
    var createdAt: Date

    init(id: UUID = UUID(), title: String, estimatedHours: Double, deadline: Date, normalHoursPerDay: Double = 8.0, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.estimatedHours = estimatedHours
        self.deadline = deadline
        self.normalHoursPerDay = normalHoursPerDay
        self.createdAt = createdAt
    }
}

// MARK: - DailySettings

struct DailySettings: Codable {
    var normalWorkHoursPerDay: Double
    var overtimeMaxHoursPerDay: Double

    static let `default` = DailySettings(normalWorkHoursPerDay: 8.0, overtimeMaxHoursPerDay: 2.0)
}

// MARK: - ScheduledBlock

struct ScheduledBlock: Identifiable, Equatable {
    let id = UUID()
    let taskTitle: String
    let taskId: UUID
    let hours: Double
    let isOvertime: Bool
}

// MARK: - DaySchedule

struct DaySchedule: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    var blocks: [ScheduledBlock]

    var isOvertime: Bool {
        blocks.contains { $0.isOvertime }
    }
}

// MARK: - ImpossibleTask

struct ImpossibleTask: Identifiable, Equatable {
    let id: UUID
    let taskTitle: String
    let hoursShort: Double
}

// MARK: - ScheduleResult

struct ScheduleResult: Equatable {
    let daySchedules: [DaySchedule]
    let impossibleTasks: [ImpossibleTask]

    static let empty = ScheduleResult(daySchedules: [], impossibleTasks: [])
}
