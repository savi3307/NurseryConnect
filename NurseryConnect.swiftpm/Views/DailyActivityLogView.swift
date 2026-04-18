import SwiftUI
import SwiftData

struct DailyActivityLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var child: Child
    var activityToEdit: DailyActivity? = nil

    @State private var selectedType = "Outdoor Play"
    @State private var details = ""

    let activityTypes = [
        "Indoor Play", "Outdoor Play", "Reading",
        "Arts & Crafts", "Educational Session", "Free Play", "Rest Period"
    ]

    private var isEditing: Bool { activityToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Activity Type")) {
                    Picker("Activity", selection: $selectedType) {
                        ForEach(activityTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                Section(header: Text("Notes / Details")) {
                    TextField("e.g. Painted with watercolours", text: $details, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle(isEditing ? "Edit Activity" : "Log Activity for \(child.firstName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") { save() }
                        .disabled(details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                if let a = activityToEdit {
                    selectedType = a.activityType
                    details = a.details
                }
            }
        }
    }

    private func save() {
        if let a = activityToEdit {
            a.activityType = selectedType
            a.details = details
        } else {
            let entry = DailyActivity(activityType: selectedType, details: details)
            entry.child = child
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}
