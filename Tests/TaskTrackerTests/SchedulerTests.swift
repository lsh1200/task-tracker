import XCTest
@testable import TaskTracker

final class SchedulerTests: XCTestCase {

    private var settings: DailySettings!

    override func setUp() {
        super.setUp()
        settings = .default
    }

    // MARK: - Test Cases

    func testSingleTaskWithinDeadline() {
        // Task: 4 hours, deadline 3 days away, 8h/day normal → 24h available
        let tasks = [Task(
            title: "Write Docs",
            estimatedHours: 4,
            deadline: daysFromNow(3),
            normalHoursPerDay: 8
        )]

        let result = Scheduler.generateSchedule(tasks: tasks, settings: settings)

        XCTAssertTrue(result.impossibleTasks.isEmpty, "Task should be possible")
        XCTAssertFalse(result.daySchedules.isEmpty, "Should have schedule days")
    }

    func testOvertimeRequired() {
        // Task: 20 hours, deadline 2 days away, 8h/day → 16h normal, needs 4h overtime
        let tasks = [Task(
            title: "Big Project",
            estimatedHours: 20,
            deadline: daysFromNow(2),
            normalHoursPerDay: 8
        )]

        let result = Scheduler.generateSchedule(tasks: tasks, settings: settings)

        XCTAssertTrue(result.impossibleTasks.isEmpty, "Task should be possible with overtime")
        XCTAssertTrue(result.daySchedules.contains { $0.isOvertime }, "Should use overtime")
    }

    func testImpossibleDeadline() {
        // Task: 20 hours, deadline 1 day away, 8h/day normal + 2h OT = 10h max → impossible by 10h
        let tasks = [Task(
            title: "Impossible Task",
            estimatedHours: 20,
            deadline: daysFromNow(1),
            normalHoursPerDay: 8
        )]

        let result = Scheduler.generateSchedule(tasks: tasks, settings: settings)

        XCTAssertEqual(result.impossibleTasks.count, 1, "Should be marked impossible")
        XCTAssertEqual(result.impossibleTasks[0].taskTitle, "Impossible Task")
        XCTAssertGreaterThan(result.impossibleTasks[0].hoursShort, 0)
    }

    func testMultipleTasksSameDay() {
        // Two tasks, same deadline, total 10h, 8h/day → task 2 uses OT
        let deadline = daysFromNow(1)
        let tasks = [
            Task(title: "Task A", estimatedHours: 5, deadline: deadline, normalHoursPerDay: 8),
            Task(title: "Task B", estimatedHours: 5, deadline: deadline, normalHoursPerDay: 8)
        ]

        let result = Scheduler.generateSchedule(tasks: tasks, settings: settings)

        XCTAssertTrue(result.impossibleTasks.isEmpty, "Both tasks should be possible")
        // The first task (earlier in sorted order) gets 5h on day 1, second gets 3h normal + 2h OT
        XCTAssertTrue(result.daySchedules.count >= 1)
    }

    func testEmptyTaskList() {
        let result = Scheduler.generateSchedule(tasks: [], settings: settings)

        XCTAssertTrue(result.impossibleTasks.isEmpty)
        XCTAssertTrue(result.daySchedules.isEmpty)
    }

    func testDeadlineInPast() {
        // Task with deadline yesterday — should not be scheduled (no days available)
        let tasks = [Task(
            title: "Past Task",
            estimatedHours: 4,
            deadline: daysFromNow(-1),
            normalHoursPerDay: 8
        )]

        let result = Scheduler.generateSchedule(tasks: tasks, settings: settings)

        XCTAssertEqual(result.impossibleTasks.count, 1, "Past deadline should be impossible")
    }

    // MARK: - Helpers

    private func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }
}
