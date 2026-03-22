import Foundation

/// Persistence layer using UserDefaults with Codable JSON encoding.
enum Persistence {
    private static let tasksKey = "tasks"
    private static let settingsKey = "dailySettings"

    // MARK: - Tasks

    static func loadTasks() -> [Task] {
        guard let data = UserDefaults.standard.data(forKey: tasksKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([Task].self, from: data)
        } catch {
            print("Failed to decode tasks: \(error)")
            return []
        }
    }

    static func saveTasks(_ tasks: [Task]) {
        do {
            let data = try JSONEncoder().encode(tasks)
            UserDefaults.standard.set(data, forKey: tasksKey)
        } catch {
            print("Failed to encode tasks: \(error)")
        }
    }

    // MARK: - Settings

    static func loadSettings() -> DailySettings {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else {
            return .default
        }
        do {
            return try JSONDecoder().decode(DailySettings.self, from: data)
        } catch {
            print("Failed to decode settings: \(error)")
            return .default
        }
    }

    static func saveSettings(_ settings: DailySettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            print("Failed to encode settings: \(error)")
        }
    }
}
