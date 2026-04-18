import SwiftUI
import SwiftData

struct MoodCheckInView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var child: Child
    var moodToEdit: MoodLog? = nil

    @State private var checkInPeriod = "Arrival"
    @State private var mood = "Happy"
    @State private var notes = ""

    let periods = ["Arrival", "Midday", "Departure"]

    struct MoodOption: Identifiable {
        let id = UUID()
        let label: String
        let emoji: String
        let color: Color
    }

    let moodOptions: [MoodOption] = [
        MoodOption(label: "Happy",     emoji: "😊", color: .green),
        MoodOption(label: "Settled",   emoji: "🙂", color: .blue),
        MoodOption(label: "Unsettled", emoji: "😟", color: .orange),
        MoodOption(label: "Poorly",    emoji: "🤒", color: .red),
    ]

    private var isEditing: Bool { moodToEdit != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Check-In Period")) {
                    Picker("Period", selection: $checkInPeriod) {
                        ForEach(periods, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Child's Mood & Wellbeing")) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(moodOptions) { option in
                            Button(action: { mood = option.label }) {
                                VStack(spacing: 8) {
                                    Text(option.emoji)
                                        .font(.largeTitle)
                                    Text(option.label)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(mood == option.label
                                    ? option.color.opacity(0.2)
                                    : Color(.secondarySystemGroupedBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(mood == option.label ? option.color : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(12)
                                .foregroundColor(mood == option.label ? option.color : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section(header: Text("Notes (optional)")) {
                    TextField("Any additional observations…", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Mood Check-In" : "Mood Check-In")
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
                if let m = moodToEdit {
                    checkInPeriod = m.checkInPeriod
                    mood = m.mood
                    notes = m.notes
                }
            }
        }
    }

    private func save() {
        if let m = moodToEdit {
            m.checkInPeriod = checkInPeriod
            m.mood = mood
            m.notes = notes
        } else {
            let entry = MoodLog(checkInPeriod: checkInPeriod, mood: mood, notes: notes)
            entry.child = child
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}
