import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var store: TaskStore
    @State private var showingAddSheet = false
    @State private var taskToEdit: Task?
    @State private var showingSchedule = false

    var body: some View {
        NavigationStack {
            List {
                if store.tasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks",
                        systemImage: "checklist",
                        description: Text("Tap + to add your first task")
                    )
                } else {
                    ForEach(sortedTasks) { task in
                        TaskRow(task: task, scheduleResult: store.scheduleResult)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                taskToEdit = task
                            }
                    }
                    .onDelete(perform: store.deleteTasks)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        taskToEdit = nil
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                if !store.tasks.isEmpty {
                    ToolbarItem(placement: .bottomBar) {
                        Button("Generate Schedule") {
                            store.regenerateSchedule()
                            showingSchedule = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddEditTaskView(task: taskToEdit)
            }
            .sheet(item: $taskToEdit) { task in
                AddEditTaskView(task: task)
            }
            .sheet(isPresented: $showingSchedule) {
                ScheduleView()
            }
        }
    }

    private var sortedTasks: [Task] {
        store.tasks.sorted { $0.deadline < $1.deadline }
    }
}

// MARK: - TaskRow

struct TaskRow: View {
    let task: Task
    let scheduleResult: ScheduleResult

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("\(task.estimatedHours, specifier: "%.1f")h", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(deadlineText)
                        .font(.caption)
                        .foregroundStyle(deadlineColor)
                }
            }

            Spacer()

            if isImpossible {
                OvertimeWarningView()
            } else if usesOvertime {
                Image(systemName: "clock.badge.exclamationmark")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var isImpossible: Bool {
        scheduleResult.impossibleTasks.contains { $0.id == task.id }
    }

    private var usesOvertime: Bool {
        scheduleResult.daySchedules.contains { day in
            day.blocks.contains { $0.taskId == task.id && $0.isOvertime }
        }
    }

    private var deadlineText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: task.deadline)
    }

    private var deadlineColor: Color {
        if isImpossible { return .red }
        if task.deadline < Date() { return .orange }
        return .secondary
    }
}

#Preview {
    TaskListView()
        .environmentObject(TaskStore())
}
