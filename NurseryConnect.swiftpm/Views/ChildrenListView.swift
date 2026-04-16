import SwiftUI
import SwiftData

struct ChildrenListView: View {
    @Query(sort: \Child.firstName) private var children: [Child]

    let keyworkerName = "Sarah Smith"

    var body: some View {
        List {
            Section(header: Text("Assigned Children").font(.headline)) {
                ForEach(children) { child in
                    NavigationLink(destination: ChildDetailView(child: child, keyworkerName: keyworkerName)) {
                        childRow(child)
                    }
                }
            }
        }
        .navigationTitle("Welcome, \(keyworkerName)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(.indigo)
                    .font(.title2)
            }
        }
    }

    // Extracted to help the Swift type-checker
    private func childRow(_ child: Child) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.indigo.opacity(0.2))
                    .frame(width: 50, height: 50)
                Text(String(child.firstName.prefix(1) + child.lastName.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.indigo)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName)
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("\(child.dailyActivities.count) activities logged today")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ChildrenListView()
            .modelContainer(for: Child.self, inMemory: true)
    }
}
