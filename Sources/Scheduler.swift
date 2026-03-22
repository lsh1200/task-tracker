import Foundation

/// Core scheduling algorithm for Task Tracker.
/// Works backwards from each task's deadline to determine if it's achievable,
/// then builds a day-by-day schedule across all tasks.
struct Scheduler {

    // MARK: - Public API

    /// Generates a schedule for all given tasks.
    /// - Parameters:
    ///   - tasks: List of tasks to schedule
    ///   - settings: Daily work hour settings
    /// - Returns: ScheduleResult with day-by-day blocks and any impossible tasks
    static func generateSchedule(tasks: [Task], settings: DailySettings) -> ScheduleResult {
        guard !tasks.isEmpty else { return .empty }

        // Sort tasks by deadline (earliest first)
        let sortedTasks = tasks.sorted { $0.deadline < $1.deadline }

        var impossibleTasks: [ImpossibleTask] = []
        // Maps (taskId, date) -> hours allocated
        var allocation: [String: Double] = [:]

        for task in sortedTasks {
            let result = scheduleTask(task, settings: settings, existingAllocations: allocation)
            if result.isPossible {
                for (key, hours) in result.allocations {
                    allocation[key] = hours
                }
            } else {
                impossibleTasks.append(ImpossibleTask(
                    id: task.id,
                    taskTitle: task.title,
                    hoursShort: result.hoursShort
                ))
            }
        }

        // Build day schedules from allocations
        let daySchedules = buildDaySchedules(from: allocation, tasks: sortedTasks, settings: settings)

        return ScheduleResult(daySchedules: daySchedules, impossibleTasks: impossibleTasks)
    }

    // MARK: - Private

    private struct AllocationResult {
        let isPossible: Bool
        let hoursShort: Double
        let allocations: [String: Double] // "\(taskId)_\(dateStr)" -> hours
    }

    private static func scheduleTask(_ task: Task, settings: DailySettings, existingAllocations: [String: Double]) -> AllocationResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let deadline = calendar.startOfDay(for: task.deadline)

        // Collect days from today to deadline (inclusive)
        var days: [Date] = []
        var cursor = deadline
        while cursor >= today {
            days.append(cursor)
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        if !days.contains(today) {
            days.append(today)
            days.sort()
        }

        let normalPerDay = settings.normalWorkHoursPerDay
        let overtimePerDay = settings.overtimeMaxHoursPerDay
        var remainingHours = task.estimatedHours
        var newAllocations: [String: Double] = [:]
        var usedOvertime = false

        for day in days {
            // Skip days in the past relative to today
            if day < today { continue }

            let dayKey = dayKey(day)
            let existingOnDay = existingAllocationsFor(day: day, taskId: task.id, existing: existingAllocations)

            // Normal hours available (reduced by what's already allocated to this task)
            let normalAvailable = max(0, normalPerDay - existingOnDay)
            var toAllocate = min(normalAvailable, remainingHours)

            if toAllocate > 0 {
                let key = allocationKey(task.id, day)
                newAllocations[key] = toAllocate
                remainingHours -= toAllocate
                if remainingHours <= 0 { break }
            }

            // Overtime hours
            if remainingHours > 0 && settings.overtimeMaxHoursPerDay > 0 {
                let overtimeKey = allocationKey(task.id, day) + "_ot"
                let existingOT = existingAllocations[overtimeKey] ?? 0
                let otAvailable = max(0, overtimePerDay - existingOT)
                var otAlloc = min(otAvailable, remainingHours)
                if otAlloc > 0 {
                    newAllocations[overtimeKey] = otAlloc
                    remainingHours -= otAlloc
                    usedOvertime = true
                    if remainingHours <= 0 { break }
                }
            }
        }

        if remainingHours > 0 {
            return AllocationResult(isPossible: false, hoursShort: remainingHours, allocations: [:])
        }

        return AllocationResult(isPossible: true, hoursShort: 0, allocations: newAllocations)
    }

    private static func buildDaySchedules(from allocation: [String: Double], tasks: [Task], settings: DailySettings) -> [DaySchedule] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find all unique dates in allocation
        var allDates: Set<String> = []
        for key in allocation.keys {
            let components = key.split(separator: "_")
            if components.count >= 2 {
                let dateStr = components[components.count - 1]
                if !dateStr.hasSuffix("_ot") {
                    allDates.insert(String(dateStr))
                }
            }
        }

        var schedules: [DaySchedule] = []

        for dateStr in allDates.sorted() {
            guard let date = parseDay(dateStr), date >= today else { continue }

            var blocks: [ScheduledBlock] = []
            for task in tasks {
                // Normal block
                let normalKey = allocationKey(task.id, date)
                if let hours = allocation[normalKey], hours > 0 {
                    blocks.append(ScheduledBlock(taskTitle: task.title, taskId: task.id, hours: hours, isOvertime: false))
                }
                // Overtime block
                let otKey = normalKey + "_ot"
                if let hours = allocation[otKey], hours > 0 {
                    blocks.append(ScheduledBlock(taskTitle: task.title, taskId: task.id, hours: hours, isOvertime: true))
                }
            }

            if !blocks.isEmpty {
                schedules.append(DaySchedule(date: date, blocks: blocks))
            }
        }

        return schedules.sorted { $0.date < $1.date }
    }

    private static func existingAllocationsFor(day: Date, taskId: UUID, existing: [String: Double]) -> Double {
        let dayKey = dayKey(day)
        let normalKey = allocationKey(taskId, day)
        let otKey = normalKey + "_ot"
        return (existing[normalKey] ?? 0) + (existing[otKey] ?? 0)
    }

    private static func dayKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func parseDay(_ str: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }

    private static func allocationKey(_ taskId: UUID, _ date: Date) -> String {
        "\(taskId.uuidString)_\(dayKey(date))"
    }
}
