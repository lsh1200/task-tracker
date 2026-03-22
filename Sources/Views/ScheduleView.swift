import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if store.tasks.isEmpty {
                        ContentUnavailableView(
                            "No Tasks",
                            systemImage: "calendar",
                            description: Text("Add tasks to generate a schedule")
                        )
                    } else {
                        // Impossible tasks first
                        if !store.scheduleResult.impossibleTasks.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(store.scheduleResult.impossibleTasks) { impossible in
                                    ImpossibleTaskCard(impossibleTask: impossible)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // Day schedules
                        if store.scheduleResult.daySchedules.isEmpty && store.scheduleResult.impossibleTasks.isEmpty {
                            ContentUnavailableView(
                                "No Schedule",
                                systemImage: "calendar",
                                description: Text("All deadlines are in the past")
                            )
                        } else {
                            LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {
                                ForEach(store.scheduleResult.daySchedules) { day in
                                    DayCard(schedule: day)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.regenerateSchedule()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - DayCard

struct DayCard: View {
    let schedule: DaySchedule

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text(dayOfWeek)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(dateString)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                if schedule.isOvertime {
                    Text("OVERTIME")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }

            Divider()

            // Blocks
            ForEach(schedule.blocks) { block in
                HStack {
                    Circle()
                        .fill(block.isOvertime ? Color.orange : Color.accentColor)
                        .frame(width: 8, height: 8)

                    Text(block.taskTitle)
                        .font(.subheadline)

                    Spacer()

                    Text("\(block.hours, specifier: "%.1f")h")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(block.isOvertime ? .orange : .primary)
                }
            }

            if schedule.blocks.isEmpty {
                Text("No work scheduled")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: schedule.date)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: schedule.date)
    }
}

// MARK: - ImpossibleTaskCard

struct ImpossibleTaskCard: View {
    let impossibleTask: ImpossibleTask

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(impossibleTask.taskTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("⚠️ Deadline impossible — short by \(impossibleTask.hoursShort, specifier: "%.1f") hours")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - OvertimeWarningView

struct OvertimeWarningView: View {
    var body: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(.red)
            .font(.caption)
    }
}

#Preview {
    ScheduleView()
        .environmentObject(TaskStore())
}
