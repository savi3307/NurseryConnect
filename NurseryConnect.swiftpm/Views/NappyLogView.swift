import SwiftUI
import SwiftData

struct NappyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var child: Child
    var nappyToEdit: NappyLog? = nil

    @State private var timestamp = Date()
    @State private var selectedType = "Wet"
    @State private var observations = ""
    @State private var isConcerning = false

    let nappyTypes = ["Wet", "Dirty", "Both", "Dry", "Dry Check"]
    private var isEditing: Bool { nappyToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Time of Check")) {
                    DatePicker("Time", selection: $timestamp, displayedComponents: [.hourAndMinute])
                }

                Section(header: Text("Type")) {
                    Picker("Nappy / Toilet Type", selection: $selectedType) {
                        ForEach(nappyTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Observations (optional)")) {
                    TextField("Any notes or concerns…", text: $observations, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle(isOn: $isConcerning) {
                        Label("Flag as Concerning", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(isConcerning ? .orange : .primary)
                    }
                    .tint(.orange)
                }
            }
            .navigationTitle(isEditing ? "Edit Nappy Log" : "Nappy / Toilet Log")
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
                if let n = nappyToEdit {
                    timestamp = n.timestamp
                    selectedType = n.type
                    observations = n.observations
                    isConcerning = n.isConcerning
                }
            }
        }
    }

    private func save() {
        if let n = nappyToEdit {
            n.timestamp = timestamp
            n.type = selectedType
            n.observations = observations
            n.isConcerning = isConcerning
        } else {
            let entry = NappyLog(
                timestamp: timestamp,
                type: selectedType,
                observations: observations,
                isConcerning: isConcerning
            )
            entry.child = child
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}
