import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: TaskStore
    @State private var normalHours: Double = 8.0
    @State private var overtimeHours: Double = 2.0

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Normal Work Hours")
                        Spacer()
                        TextField("", value: $normalHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("h/day")
                            .foregroundStyle(.secondary)
                    }
                    .onChange(of: normalHours) { _, newValue in
                        saveIfValid(normalHours: newValue, overtimeHours: overtimeHours)
                    }

                    HStack {
                        Text("Max Overtime")
                        Spacer()
                        TextField("", value: $overtimeHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("h/day")
                            .foregroundStyle(.secondary)
                    }
                    .onChange(of: overtimeHours) { _, newValue in
                        saveIfValid(normalHours: normalHours, overtimeHours: newValue)
                    }
                } header: {
                    Text("Daily Hours")
                } footer: {
                    Text("Normal hours are used first when scheduling. Overtime is only used when normal hours aren't enough to meet a deadline.")
                }

                Section {
                    HStack {
                        Text("Total Tasks")
                        Spacer()
                        Text("\(store.tasks.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Impossible Deadlines")
                        Spacer()
                        Text("\(store.scheduleResult.impossibleTasks.count)")
                            .foregroundStyle(store.scheduleResult.impossibleTasks.isEmpty ? .secondary : .red)
                    }
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                normalHours = store.settings.normalWorkHoursPerDay
                overtimeHours = store.settings.overtimeMaxHoursPerDay
            }
        }
    }

    private func saveIfValid(normalHours: Double, overtimeHours: Double) {
        guard normalHours > 0, overtimeHours >= 0 else { return }
        store.updateSettings(DailySettings(
            normalWorkHoursPerDay: normalHours,
            overtimeMaxHoursPerDay: overtimeHours
        ))
    }
}

#Preview {
    SettingsView()
        .environmentObject(TaskStore())
}
