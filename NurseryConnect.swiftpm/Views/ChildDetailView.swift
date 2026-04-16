import SwiftUI
import SwiftData

// Wraps a delete closure so it can be stored in @State
private struct DeleteAction {
    let message: String
    let perform: () -> Void
}

struct ChildDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var child: Child
    let keyworkerName: String

    // ── Sheet triggers ────────────────────────────────────────────────────
    @State private var showingLogActivity    = false
    @State private var showingSleepLog       = false
    @State private var showingNappyLog       = false
    @State private var showingMoodCheckIn    = false
    @State private var showingReportIncident = false

    // ── Edit item bindings ────────────────────────────────────────────────
    @State private var activityToEdit: DailyActivity?  = nil
    @State private var sleepToEdit:    SleepLog?       = nil
    @State private var nappyToEdit:    NappyLog?       = nil
    @State private var moodToEdit:     MoodLog?        = nil
    @State private var incidentToEdit: IncidentReport? = nil

    // ── Incident edit confirmation (before opening edit sheet) ────────────
    @State private var incidentPendingEdit: IncidentReport? = nil
    @State private var showIncidentEditConfirm  = false
    @State private var showIncidentEditSuccess  = false

    // ── Generic delete confirmation (shared across all types) ─────────────
    @State private var pendingDelete: DeleteAction? = nil
    @State private var showDeleteConfirm  = false
    @State private var showDeleteSuccess  = false

    // ── Sorted helpers ────────────────────────────────────────────────────
    var sortedActivities: [DailyActivity]  { child.dailyActivities.sorted { $0.timestamp > $1.timestamp } }
    var sortedSleepLogs:  [SleepLog]       { child.sleepLogs.sorted  { $0.startTime   > $1.startTime   } }
    var sortedNappyLogs:  [NappyLog]       { child.nappyLogs.sorted  { $0.timestamp   > $1.timestamp   } }
    var sortedMoodLogs:   [MoodLog]        { child.moodLogs.sorted   { $0.timestamp   > $1.timestamp   } }
    var sortedIncidents:  [IncidentReport] { child.incidents.sorted  { $0.timestamp   > $1.timestamp   } }

    // ═══════════════════════════════════════════════════════════════════════
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                profileCard

                actionButtons

                sectionHeader("Daily Activities",   icon: "figure.play",                   color: .indigo)
                if sortedActivities.isEmpty { emptyLabel("No activities logged yet.") }
                else { ForEach(sortedActivities)  { activityCard($0)  } }

                sectionHeader("Sleep / Nap Log",    icon: "moon.zzz.fill",                 color: .purple)
                if sortedSleepLogs.isEmpty  { emptyLabel("No sleep sessions recorded.") }
                else { ForEach(sortedSleepLogs)   { sleepCard($0)     } }

                sectionHeader("Nappy / Toilet Log", icon: "drop.fill",                      color: .blue)
                if sortedNappyLogs.isEmpty  { emptyLabel("No nappy checks recorded.") }
                else { ForEach(sortedNappyLogs)   { nappyCard($0)     } }

                sectionHeader("Mood & Wellbeing",   icon: "heart.fill",                    color: .pink)
                if sortedMoodLogs.isEmpty   { emptyLabel("No mood check-ins recorded.") }
                else { ForEach(sortedMoodLogs)    { moodCard($0)      } }

                sectionHeader("Incident Reports",   icon: "exclamationmark.triangle.fill", color: .red)
                if sortedIncidents.isEmpty  { emptyLabel("No incidents reported.") }
                else { ForEach(sortedIncidents)   { incidentCard($0)  } }

                Spacer(minLength: 30)
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(child.firstName)
        .navigationBarTitleDisplayMode(.inline)

        // ── Sheets ──────────────────────────────────────────────────────────
        .sheet(isPresented: $showingLogActivity)    { DailyActivityLogView(child: child) }
        .sheet(isPresented: $showingSleepLog)       { SleepLogView(child: child) }
        .sheet(isPresented: $showingNappyLog)       { NappyLogView(child: child) }
        .sheet(isPresented: $showingMoodCheckIn)    { MoodCheckInView(child: child) }
        .sheet(isPresented: $showingReportIncident) { ReportIncidentView(child: child, keyworkerName: keyworkerName) }

        .sheet(item: $activityToEdit) { DailyActivityLogView(child: child, activityToEdit: $0) }
        .sheet(item: $sleepToEdit)    { SleepLogView(child: child, sleepToEdit: $0) }
        .sheet(item: $nappyToEdit)    { NappyLogView(child: child, nappyToEdit: $0) }
        .sheet(item: $moodToEdit)     { MoodCheckInView(child: child, moodToEdit: $0) }

        // Incident edit sheet — onSaved fires success alert
        .sheet(item: $incidentToEdit) { incident in
            ReportIncidentView(
                child: child,
                keyworkerName: keyworkerName,
                incidentToEdit: incident,
                onSaved: { showIncidentEditSuccess = true }
            )
        }

        // ── Alerts ──────────────────────────────────────────────────────────

        // 1. Confirm before editing an incident
        .alert("Edit Incident Report", isPresented: $showIncidentEditConfirm) {
            Button("Edit") {
                incidentToEdit = incidentPendingEdit
                incidentPendingEdit = nil
            }
            Button("Cancel", role: .cancel) { incidentPendingEdit = nil }
        } message: {
            Text("Are you sure you want to edit this incident report?")
        }

        // 2. Success after edit saved
        .alert("Incident Updated", isPresented: $showIncidentEditSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The incident report has been successfully updated.")
        }

        // 3. Confirm before any delete
        .alert("Confirm Delete", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                pendingDelete?.perform()
                pendingDelete = nil
                showDeleteSuccess = true
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text(pendingDelete?.message ?? "Are you sure you want to delete this entry?")
        }

        // 4. Success after delete
        .alert("Entry Deleted", isPresented: $showDeleteSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The entry has been successfully deleted.")
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(alignment: .top) {
            ZStack {
                Circle().fill(Color.indigo.opacity(0.1)).frame(width: 80, height: 80)
                Text(String(child.firstName.prefix(1) + child.lastName.prefix(1)))
                    .font(.largeTitle).fontWeight(.bold).foregroundColor(.indigo)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(child.fullName).font(.title).fontWeight(.bold)
                Text("Allergies: \(child.allergies.isEmpty ? "None" : child.allergies)")
                    .foregroundColor(child.allergies.isEmpty ? .secondary : .red)
                    .fontWeight(child.allergies.isEmpty ? .regular : .semibold)
                Text("Emergency: \(child.emergencyContact)").font(.subheadline).foregroundColor(.secondary)
            }
            .padding(.leading, 10)
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
        .padding(.horizontal)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                actionButton("Log Activity",  icon: "figure.play",       color: .indigo) { showingLogActivity    = true }
                actionButton("Sleep Log",     icon: "moon.zzz.fill",     color: .purple) { showingSleepLog       = true }
                actionButton("Nappy Log",     icon: "drop.fill",         color: .blue)   { showingNappyLog       = true }
            }
            HStack(spacing: 10) {
                actionButton("Mood Check-In", icon: "heart.fill",        color: .pink)   { showingMoodCheckIn    = true }
                actionButton("Report Incident", icon: "exclamationmark.triangle.fill", color: .red) { showingReportIncident = true }
            }
        }
        .padding(.horizontal)
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption2).fontWeight(.medium).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Reusable Helpers

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(color)
            Text(title).font(.title2).fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.top, 4)
    }

    private func emptyLabel(_ text: String) -> some View {
        Text(text).foregroundColor(.secondary).padding().padding(.horizontal)
    }

    /// Generic Edit / Delete row — delete always goes through confirmation.
    private func editDeleteRow(
        onEdit: @escaping () -> Void,
        deleteMessage: String,
        onDelete: @escaping () -> Void
    ) -> some View {
        HStack {
            Spacer()
            Button(action: onEdit) {
                Label("Edit", systemImage: "pencil").font(.caption).foregroundColor(.indigo)
            }
            .padding(.trailing, 10)
            Button(role: .destructive) {
                pendingDelete = DeleteAction(message: deleteMessage, perform: onDelete)
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash").font(.caption)
            }
        }
    }

    // MARK: - Card Views

    @ViewBuilder
    private func activityCard(_ a: DailyActivity) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: activityIcon(for: a.activityType)).foregroundColor(.indigo)
                Text(a.activityType).font(.headline)
                Spacer()
                Text(a.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
            Text(a.details).font(.subheadline).foregroundColor(.secondary)
            editDeleteRow(
                onEdit:        { activityToEdit = a },
                deleteMessage: "Delete '\(a.activityType)' activity entry?",
                onDelete:      { modelContext.delete(a); try? modelContext.save() }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func sleepCard(_ s: SleepLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.zzz.fill").foregroundColor(.purple)
                Text(s.sleepPosition).font(.headline)
                Spacer()
                Text(s.durationText).font(.caption).fontWeight(.semibold).foregroundColor(.purple)
            }
            HStack(spacing: 4) {
                Text("Start: \(s.startTime.formatted(date: .omitted, time: .shortened))")
                    .font(.caption).foregroundColor(.secondary)
                if let end = s.endTime {
                    Text("→ End: \(end.formatted(date: .omitted, time: .shortened))")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            if !s.notes.isEmpty {
                Text(s.notes).font(.caption).foregroundColor(.secondary).italic()
            }
            editDeleteRow(
                onEdit:        { sleepToEdit = s },
                deleteMessage: "Delete this sleep / nap log entry?",
                onDelete:      { modelContext.delete(s); try? modelContext.save() }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func nappyCard(_ n: NappyLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "drop.fill").foregroundColor(n.isConcerning ? .orange : .blue)
                Text(n.type).font(.headline)
                if n.isConcerning {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange).font(.caption)
                    Text("Concerning").font(.caption).foregroundColor(.orange)
                }
                Spacer()
                Text(n.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
            if !n.observations.isEmpty {
                Text(n.observations).font(.subheadline).foregroundColor(.secondary)
            }
            editDeleteRow(
                onEdit:        { nappyToEdit = n },
                deleteMessage: "Delete '\(n.type)' nappy / toilet log entry?",
                onDelete:      { modelContext.delete(n); try? modelContext.save() }
            )
        }
        .padding()
        .background(n.isConcerning ? Color.orange.opacity(0.06) : Color(.systemBackground))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(n.isConcerning ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1))
        .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func moodCard(_ m: MoodLog) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(m.moodEmoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.mood).font(.headline)
                    Text(m.checkInPeriod).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(m.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }
            if !m.notes.isEmpty {
                Text(m.notes).font(.subheadline).foregroundColor(.secondary)
            }
            editDeleteRow(
                onEdit:        { moodToEdit = m },
                deleteMessage: "Delete '\(m.checkInPeriod)' mood check-in?",
                onDelete:      { modelContext.delete(m); try? modelContext.save() }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func incidentCard(_ i: IncidentReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(incidentColor(i.category))
                VStack(alignment: .leading, spacing: 2) {
                    Text(i.location).font(.headline)
                    Text(i.category).font(.caption).foregroundColor(incidentColor(i.category)).fontWeight(.semibold)
                }
                Spacer()
                Text(i.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundColor(.secondary)
            }

            Text(i.descriptionOfIncident).font(.subheadline).foregroundColor(.primary)
            Text("Action: \(i.actionTaken)").font(.caption).foregroundColor(.secondary).italic()

            if !i.witnesses.isEmpty {
                Text("Witnesses: \(i.witnesses)").font(.caption).foregroundColor(.secondary)
            }

            // Photo evidence
            if let data = i.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 180)
                    .cornerRadius(8)
                    .padding(.top, 4)
            }

            Text("By: \(i.keyworkerName)").font(.caption2).foregroundColor(.secondary)

            // Edit goes through confirmation alert; delete also goes through confirmation
            editDeleteRow(
                onEdit: {
                    incidentPendingEdit = i
                    showIncidentEditConfirm = true
                },
                deleteMessage: "Delete the incident at '\(i.location)'? This cannot be undone.",
                onDelete: { modelContext.delete(i); try? modelContext.save() }
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(incidentColor(i.category).opacity(0.3), lineWidth: 1))
        .shadow(color: .red.opacity(0.04), radius: 3, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private func incidentColor(_ category: String) -> Color {
        switch category {
        case "Safeguarding Concern":          return .purple
        case "Accident (First Aid Required)": return .orange
        case "Allergic Reaction":             return .red
        case "Medical Incident":              return .red
        case "Near Miss":                     return Color(red: 0.8, green: 0.6, blue: 0)
        default:                             return .blue
        }
    }

    private func activityIcon(for type: String) -> String {
        switch type {
        case "Indoor Play":         return "house.fill"
        case "Outdoor Play":        return "sun.max.fill"
        case "Reading":             return "book.fill"
        case "Arts & Crafts":       return "paintbrush.fill"
        case "Educational Session": return "graduationcap.fill"
        case "Free Play":           return "figure.play"
        case "Rest Period":         return "bed.double.fill"
        default:                    return "star.fill"
        }
    }
}
