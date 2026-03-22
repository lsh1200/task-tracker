"""
Task Tracker — Scheduling Algorithm (Python port for testing)
"""
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta
from typing import Optional


@dataclass
class Task:
    id: str
    title: str
    estimated_hours: float
    deadline: date
    normal_hours_per_day: float = 8.0


@dataclass
class DailySettings:
    normal_work_hours_per_day: float = 8.0
    overtime_max_hours_per_day: float = 2.0


@dataclass
class ScheduledBlock:
    task_title: str
    task_id: str
    hours: float
    is_overtime: bool


@dataclass
class DaySchedule:
    date: date
    blocks: list[ScheduledBlock] = field(default_factory=list)

    @property
    def is_overtime(self) -> bool:
        return any(b.is_overtime for b in self.blocks)


@dataclass
class ImpossibleTask:
    task_title: str
    hours_short: float


@dataclass
class ScheduleResult:
    day_schedules: list[DaySchedule]
    impossible_tasks: list[ImpossibleTask]

    @staticmethod
    def empty():
        return ScheduleResult(day_schedules=[], impossible_tasks=[])


def generate_schedule(tasks: list[Task], settings: DailySettings) -> ScheduleResult:
    """
    Core scheduling algorithm.
    Works backwards from each task's deadline to determine achievability,
    then builds a day-by-day schedule across all tasks.
    """
    if not tasks:
        return ScheduleResult.empty()

    today = datetime.now().date()
    sorted_tasks = sorted(tasks, key=lambda t: t.deadline)

    impossible_tasks: list[ImpossibleTask] = []
    # allocation: dict[str, float] — key: "taskId_YYYY-MM-DD[_ot]" → hours
    allocation: dict[str, float] = {}

    for task in sorted_tasks:
        result = _schedule_task(task, today, settings, allocation)
        if result["is_possible"]:
            for key, hours in result["allocations"].items():
                allocation[key] = hours
        else:
            impossible_tasks.append(ImpossibleTask(
                task_title=task.title,
                hours_short=result["hours_short"]
            ))

    day_schedules = _build_day_schedules(allocation, sorted_tasks, today)
    return ScheduleResult(day_schedules=day_schedules, impossible_tasks=impossible_tasks)


def _schedule_task(task: Task, today: date, settings: DailySettings, existing: dict[str, float]) -> dict:
    """Schedule a single task. Returns {is_possible, hours_short, allocations}."""
    deadline = task.deadline

    # Collect days from today to deadline (inclusive), but only future days
    days = []
    cursor = deadline
    while cursor >= today:
        if cursor >= today:
            days.append(cursor)
        cursor -= timedelta(days=1)

    if not days:
        # Deadline is in the past
        return {"is_possible": False, "hours_short": task.estimated_hours, "allocations": {}}

    days = sorted(days)  # chronological
    normal_per_day = settings.normal_work_hours_per_day
    overtime_per_day = settings.overtime_max_hours_per_day
    remaining = task.estimated_hours
    new_allocs: dict[str, float] = {}

    for day in days:
        if day < today:
            continue

        day_str = _day_key(day)
        existing_on_day = _existing_on_day(task.id, day, existing)

        # Normal hours
        normal_available = max(0, normal_per_day - existing_on_day)
        to_alloc = min(normal_available, remaining)
        if to_alloc > 0:
            key = f"{task.id}_{day_str}"
            new_allocs[key] = to_alloc
            remaining -= to_alloc
            if remaining <= 0:
                break

        # Overtime hours
        if remaining > 0 and overtime_per_day > 0:
            ot_key = f"{task.id}_{day_str}_ot"
            existing_ot = existing.get(ot_key, 0)
            ot_available = max(0, overtime_per_day - existing_ot)
            ot_alloc = min(ot_available, remaining)
            if ot_alloc > 0:
                new_allocs[ot_key] = ot_alloc
                remaining -= ot_alloc
                if remaining <= 0:
                    break

    if remaining > 0:
        return {"is_possible": False, "hours_short": remaining, "allocations": {}}

    return {"is_possible": True, "hours_short": 0, "allocations": new_allocs}


def _build_day_schedules(allocation: dict[str, float], tasks: list[Task], today: date) -> list[DaySchedule]:
    """Build day-by-day schedule cards from allocation dict."""
    # Find all unique dates
    date_keys: set[str] = set()
    for key in allocation:
        parts = key.split("_")
        if len(parts) >= 2 and not parts[-1] == "ot":
            date_keys.add(parts[-1])

    schedules: list[DaySchedule] = []
    task_map = {t.id: t for t in tasks}

    for dk in sorted(date_keys):
        d = _parse_day(dk)
        if d is None or d < today:
            continue

        blocks: list[ScheduledBlock] = []
        for task_id, task in task_map.items():
            normal_key = f"{task_id}_{dk}"
            normal_hours = allocation.get(normal_key, 0)
            if normal_hours > 0:
                blocks.append(ScheduledBlock(
                    task_title=task.title,
                    task_id=task_id,
                    hours=normal_hours,
                    is_overtime=False
                ))
            ot_hours = allocation.get(f"{normal_key}_ot", 0)
            if ot_hours > 0:
                blocks.append(ScheduledBlock(
                    task_title=task.title,
                    task_id=task_id,
                    hours=ot_hours,
                    is_overtime=True
                ))

        if blocks:
            schedules.append(DaySchedule(date=d, blocks=blocks))

    return sorted(schedules, key=lambda s: s.date)


def _existing_on_day(task_id: str, day: date, existing: dict[str, float]) -> float:
    day_str = _day_key(day)
    return existing.get(f"{task_id}_{day_str}", 0) + existing.get(f"{task_id}_{day_str}_ot", 0)


def _day_key(d: date) -> str:
    return d.isoformat()


def _parse_day(s: str) -> Optional[date]:
    return date.fromisoformat(s)
