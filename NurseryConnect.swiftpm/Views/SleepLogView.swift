import SwiftUI
import SwiftData

struct SleepLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var child: Child
    var sleepToEdit: SleepLog? = nil

    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var stillSleeping = false
    @State private var sleepPosition = "On Back"
    @State private var notes = ""

    let positions = ["On Back", "On Side", "On Front"]
    private var isEditing: Bool { sleepToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Sleep Times")) {
                    DatePicker("Start Time", selection: $startTime, displayedComponents: [.hourAndMinute])
                    Toggle("Still Sleeping", isOn: $stillSleeping)
                    if !stillSleeping {
                        DatePicker("End Time", selection: $endTime, displayedComponents: [.hourAndMinute])
                    }
                }

                Section(header: Text("Sleep Position")) {
                    Picker("Position", selection: $sleepPosition) {
                        ForEach(positions, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Notes (optional)")) {
                    TextField("Any observations…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                if !stillSleeping && endTime > startTime {
                    Section {
                        let mins = Int(endTime.timeIntervalSince(startTime) / 60)
                        let h = mins / 60; let m = mins % 60
                        HStack {
                            Text("Duration")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(h > 0 ? "\(h)h \(m)m" : "\(m) min")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Sleep Log" : "Log Sleep / Nap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { save() }
                }
            }
            .onAppear {
                if let s = sleepToEdit {
                    startTime = s.startTime
                    stillSleeping = s.endTime == nil
                    endTime = s.endTime ?? Date()
                    sleepPosition = s.sleepPosition
                    notes = s.notes
                }
            }
        }
    }

    private func save() {
        if let s = sleepToEdit {
            s.startTime = startTime
            s.endTime = stillSleeping ? nil : endTime
            s.sleepPosition = sleepPosition
            s.notes = notes
        } else {
            let entry = SleepLog(
                startTime: startTime,
                endTime: stillSleeping ? nil : endTime,
                sleepPosition: sleepPosition,
                notes: notes
            )
            entry.child = child
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}
