"""
Unit tests for Task Tracker scheduling algorithm.
Run with: python3 -m pytest test_scheduler.py -v
Or directly: python3 test_scheduler.py
"""
import unittest
from datetime import date, timedelta
from scheduler import Task, DailySettings, generate_schedule


class TestScheduler(unittest.TestCase):

    def _days_from_now(self, days: int) -> date:
        return date.today() + timedelta(days=days)

    def test_single_task_within_deadline(self):
        """Task fits easily within deadline using normal hours."""
        tasks = [
            Task(
                id="1",
                title="Write Docs",
                estimated_hours=4,
                deadline=self._days_from_now(3),
                normal_hours_per_day=8
            )
        ]
        settings = DailySettings(normal_work_hours_per_day=8, overtime_max_hours_per_day=2)
        result = generate_schedule(tasks, settings)

        self.assertEqual(len(result.impossible_tasks), 0, "Task should be possible")
        self.assertGreater(len(result.day_schedules), 0, "Should have schedule days")

    def test_overtime_required(self):
        """Task needs overtime to meet deadline."""
        tasks = [
            Task(
                id="2",
                title="Big Project",
                estimated_hours=20,
                deadline=self._days_from_now(2),
                normal_hours_per_day=8
            )
        ]
        settings = DailySettings(normal_work_hours_per_day=8, overtime_max_hours_per_day=2)
        result = generate_schedule(tasks, settings)

        self.assertEqual(len(result.impossible_tasks), 0, "Task should be possible with overtime")
        overtime_days = [d for d in result.day_schedules if d.is_overtime]
        self.assertGreater(len(overtime_days), 0, "Should use overtime")

    def test_impossible_deadline(self):
        """Even with overtime, deadline is impossible within available hours."""
        # Deadline TODAY = only today available = 8 normal + 2 OT = 10h max
        # Task needs 20h → 10h short
        tasks = [
            Task(
                id="3",
                title="Impossible Task",
                estimated_hours=20,
                deadline=self._days_from_now(0),  # today only = 10h max
                normal_hours_per_day=8
            )
        ]
        settings = DailySettings(normal_work_hours_per_day=8, overtime_max_hours_per_day=2)
        result = generate_schedule(tasks, settings)

        self.assertEqual(len(result.impossible_tasks), 1, "Should be impossible")
        self.assertEqual(result.impossible_tasks[0].task_title, "Impossible Task")
        self.assertGreater(result.impossible_tasks[0].hours_short, 0)
        # 20h needed, 10h available (8 normal + 2 OT) = 10h short
        self.assertAlmostEqual(result.impossible_tasks[0].hours_short, 10.0, places=1)

    def test_multiple_tasks_same_day(self):
        """Two tasks on same day: one normal, one uses overtime."""
        deadline = self._days_from_now(1)
        tasks = [
            Task(id="a", title="Task A", estimated_hours=5, deadline=deadline, normal_hours_per_day=8),
            Task(id="b", title="Task B", estimated_hours=5, deadline=deadline, normal_hours_per_day=8),
        ]
        settings = DailySettings(normal_work_hours_per_day=8, overtime_max_hours_per_day=2)
        result = generate_schedule(tasks, settings)

        self.assertEqual(len(result.impossible_tasks), 0, "Both tasks should be possible")
        # Day 1: Task A gets 5h normal, Task B gets 3h normal + 2h OT
        self.assertGreaterEqual(len(result.day_schedules), 1)

    def test_empty_task_list(self):
        """Empty input returns empty schedule."""
        result = generate_schedule([], DailySettings())
        self.assertEqual(len(result.impossible_tasks), 0)
        self.assertEqual(len(result.day_schedules), 0)

    def test_deadline_in_past(self):
        """Task with past deadline is marked impossible."""
        tasks = [
            Task(
                id="past",
                title="Past Task",
                estimated_hours=4,
                deadline=self._days_from_now(-1),
                normal_hours_per_day=8
            )
        ]
        settings = DailySettings()
        result = generate_schedule(tasks, settings)

        self.assertEqual(len(result.impossible_tasks), 1, "Past deadline should be impossible")

    def test_normal_hours_used_before_overtime(self):
        """System always uses normal hours before overtime."""
        tasks = [
            Task(
                id="n",
                title="Balanced",
                estimated_hours=8,
                deadline=self._days_from_now(1),
                normal_hours_per_day=8
            )
        ]
        settings = DailySettings(normal_work_hours_per_day=8, overtime_max_hours_per_day=2)
        result = generate_schedule(tasks, settings)

        self.assertEqual(len(result.impossible_tasks), 0)
        # Should be exactly 8h normal, 0h overtime
        day = result.day_schedules[0]
        normal_hours = sum(b.hours for b in day.blocks if not b.is_overtime)
        ot_hours = sum(b.hours for b in day.blocks if b.is_overtime)
        self.assertAlmostEqual(normal_hours, 8.0, places=1)
        self.assertAlmostEqual(ot_hours, 0.0, places=1)


if __name__ == "__main__":
    unittest.main(verbosity=2)
