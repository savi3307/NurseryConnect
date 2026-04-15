import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var children: [Child]

    var body: some View {
        NavigationStack {
            ChildrenListView()
        }
        .onAppear {
            seedInitialDataIfNeeded()
        }
    }

    private func seedInitialDataIfNeeded() {
        if children.isEmpty {
            let sampleChild1 = Child(
                firstName: "Leo", lastName: "Smith",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -3, to: Date())!,
                allergies: "Peanuts", emergencyContact: "07712345678")
            let sampleChild2 = Child(
                firstName: "Mia", lastName: "Johnson",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -4, to: Date())!,
                allergies: "None", emergencyContact: "07898765432")
            let sampleChild3 = Child(
                firstName: "Oliver", lastName: "Williams",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -2, to: Date())!,
                allergies: "Dairy", emergencyContact: "07911223344")

            modelContext.insert(sampleChild1)
            modelContext.insert(sampleChild2)
            modelContext.insert(sampleChild3)

            // Sample daily activity for Leo
            let sampleActivity = DailyActivity(activityType: "Outdoor Play",
                                               details: "Played in the garden with sand and water table.")
            sampleActivity.child = sampleChild1
            modelContext.insert(sampleActivity)

            // Sample mood log for Leo
            let sampleMood = MoodLog(checkInPeriod: "Arrival", mood: "Happy", notes: "Arrived smiling, ready to play.")
            sampleMood.child = sampleChild1
            modelContext.insert(sampleMood)

            do {
                try modelContext.save()
            } catch {
                print("Failed to seed initial data.")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Child.self, inMemory: true)
}
