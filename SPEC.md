# Task Tracker — Specification

## Overview
Task Tracker is an iPhone app that helps users schedule work across calendar days to meet task deadlines. It calculates whether deadlines are achievable given normal daily work hours, and highlights when overtime is required or impossible.

## Data Model

### Task
- `id`: UUID (auto-generated)
- `title`: String
- `estimatedHours`: Double
- `deadline`: Date
- `normalHoursPerDay`: Double (default from settings)
- `createdAt`: Date

### DailySettings
- `normalWorkHoursPerDay`: Double (default 8.0)
- `overtimeMaxHoursPerDay`: Double (default 2.0)

## Views

### ContentView
TabView with two tabs:
- "Tasks" → TaskListView
- "Settings" → SettingsView

### TaskListView
- List of all tasks sorted by deadline
- Each row shows: title, hours, deadline, overtime indicator
- Swipe left to delete
- Tap to edit → AddEditTaskView (sheet)
- "+" button → AddEditTaskView (sheet)
- "Generate Schedule" button → ScheduleView (sheet)

### AddEditTaskView
- Form fields:
  - Title (TextField)
  - Estimated Hours (TextField, number pad)
  - Deadline (DatePicker)
  - Daily Work Hours (TextField, pre-filled from settings)
- Save / Cancel buttons

### ScheduleView
- Header: date range
- For each day in range:
  - Date + day of week
  - List of scheduled blocks (task title + hours for that day)
  - Normal hours shown in default color
  - Overtime hours shown in orange
  - If no tasks: "No work scheduled"
- Impossible tasks shown at top with red warning card
- Each impossible card shows: task title, hours short

### SettingsView
- Normal Work Hours per Day (Stepper, range 1–24, default 8)
- Overtime Max per Day (Stepper, range 0–8, default 2)
- Saved automatically to UserDefaults

## Scheduling Algorithm

### Inputs
- Tasks: [(title, estimatedHours, deadline, normalHoursPerDay)]
- Settings: (normalWorkHoursPerDay, overtimeMaxHoursPerDay)

### Logic
1. Sort tasks by deadline ascending
2. For each task, work backwards from its deadline:
   - Collect all days from "today" to deadline (inclusive)
   - Each day provides: normalWorkHoursPerDay normal hours
   - If remaining hours > 0 after normal: try overtime (overtimeMaxHoursPerDay extra)
   - If total possible hours < estimatedHours → IMPOSSIBLE
   - If possible: assign hours to days greedily (fill later days first)
3. Build final day-by-day schedule across ALL tasks
4. Multiple tasks on same day: show all

### Output: [DaySchedule]
- date: Date
- blocks: [ScheduledBlock]
- isOvertime: Bool

### ScheduledBlock
- taskTitle: String
- hours: Double
- isOvertime: Bool

## Persistence
- Tasks and Settings stored in UserDefaults
- Key: "tasks" → JSON encoded [Task]
- Key: "dailySettings" → JSON encoded DailySettings

## Colors
- Normal hours: default (black/dark)
- Overtime: orange (#F97316)
- Impossible warning: red (#EF4444)
- Background: system grouped background

## Build & Test
- iOS 16.0+
- SwiftUI
- XcodeGen
- GitHub Actions CI (macOS-latest)
