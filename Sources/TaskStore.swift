import Foundation
import Combine

/// Main observable store for the app — holds tasks, settings, and schedule result.
final class TaskStore: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var settings: DailySettings = .default
    @Published var scheduleResult: ScheduleResult = .empty

    init() {
        tasks = Persistence.loadTasks()
        settings = Persistence.loadSettings()
        regenerateSchedule()
    }

    // MARK: - Task CRUD

    func addTask(_ task: Task) {
        tasks.append(task)
        Persistence.saveTasks(tasks)
        regenerateSchedule()
    }

    func updateTask(_ task: Task) {
        if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[idx] = task
            Persistence.saveTasks(tasks)
            regenerateSchedule()
        }
    }

    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        Persistence.saveTasks(tasks)
        regenerateSchedule()
    }

    func deleteTasks(at offsets: IndexSet) {
        tasks.remove(atOffsets: offsets)
        Persistence.saveTasks(tasks)
        regenerateSchedule()
    }

    // MARK: - Settings

    func updateSettings(_ newSettings: DailySettings) {
        settings = newSettings
        Persistence.saveSettings(settings)
        // Update tasks' normalHoursPerDay to match settings
        for i in tasks.indices {
            tasks[i].normalHoursPerDay = newSettings.normalWorkHoursPerDay
        }
        Persistence.saveTasks(tasks)
        regenerateSchedule()
    }

    // MARK: - Schedule

    func regenerateSchedule() {
        scheduleResult = Scheduler.generateSchedule(tasks: tasks, settings: settings)
    }
}
