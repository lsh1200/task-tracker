import SwiftUI

struct AddEditTaskView: View {
    @EnvironmentObject var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    let task: Task? // nil = add mode

    @State private var title: String = ""
    @State private var estimatedHoursText: String = ""
    @State private var deadline: Date = Date().addingTimeInterval(86400 * 3)
    @State private var normalHoursPerDay: Double = 8.0
    @State private var showingError = false
    @State private var errorMessage = ""

    var isEditing: Bool { task != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $title)

                    HStack {
                        TextField("Estimated Hours", text: $estimatedHoursText)
                            .keyboardType(.decimalPad)
                        Text("hours")
                            .foregroundStyle(.secondary)
                    }

                    DatePicker("Deadline", selection: $deadline, displayedComponents: .date)
                }

                Section("Daily Work Hours") {
                    HStack {
                        Text("Hours per Day")
                        Spacer()
                        TextField("", value: $normalHoursPerDay, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("h/day")
                            .foregroundStyle(.secondary)
                    }
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let task {
                    title = task.title
                    estimatedHoursText = String(format: "%.1f", task.estimatedHours)
                    deadline = task.deadline
                    normalHoursPerDay = task.normalHoursPerDay
                } else {
                    normalHoursPerDay = store.settings.normalWorkHoursPerDay
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(estimatedHoursText) ?? 0) > 0 &&
        normalHoursPerDay > 0
    }

    private func saveTask() {
        guard let hours = Double(estimatedHoursText), hours > 0 else {
            errorMessage = "Please enter valid estimated hours"
            showingError = true
            return
        }

        if normalHoursPerDay <= 0 {
            errorMessage = "Daily work hours must be greater than 0"
            showingError = true
            return
        }

        let newTask = Task(
            id: task?.id ?? UUID(),
            title: title.trimmingCharacters(in: .whitespaces),
            estimatedHours: hours,
            deadline: deadline,
            normalHoursPerDay: normalHoursPerDay,
            createdAt: task?.createdAt ?? Date()
        )

        if isEditing {
            store.updateTask(newTask)
        } else {
            store.addTask(newTask)
        }

        dismiss()
    }
}

#Preview {
    AddEditTaskView(task: nil)
        .environmentObject(TaskStore())
}
