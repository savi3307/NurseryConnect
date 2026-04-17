import SwiftUI
import SwiftData
import PhotosUI

struct ReportIncidentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var child: Child
    let keyworkerName: String
    var incidentToEdit: IncidentReport? = nil
    var onSaved: (() -> Void)? = nil   // called only when Save/Update is confirmed

    @State private var category = "Accident (Minor)"
    @State private var location = ""
    @State private var descriptionOfIncident = ""
    @State private var actionTaken = ""
    @State private var witnesses = ""

    // Photo picker
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    // Confirmation
    @State private var showUpdateConfirmation = false

    let categories = [
        "Accident (Minor)",
        "Accident (First Aid Required)",
        "Safeguarding Concern",
        "Near Miss",
        "Allergic Reaction",
        "Medical Incident"
    ]

    private var isEditing: Bool { incidentToEdit != nil }
    private var isSaveDisabled: Bool {
        location.isEmpty || descriptionOfIncident.isEmpty || actionTaken.isEmpty
    }

    var categoryColor: Color {
        switch category {
        case "Safeguarding Concern":          return .purple
        case "Accident (First Aid Required)": return .orange
        case "Allergic Reaction":             return .red
        case "Medical Incident":              return .red
        case "Near Miss":                     return Color(red: 0.8, green: 0.6, blue: 0)
        default:                             return .blue
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Category
                Section(header: Text("Incident Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)

                    HStack(spacing: 6) {
                        Circle().fill(categoryColor).frame(width: 10, height: 10)
                        Text(category).font(.caption).foregroundColor(.secondary)
                    }
                }

                // Date
                Section(header: Text("Date & Time")) {
                    HStack {
                        Text("Recorded").foregroundColor(.secondary)
                        Spacer()
                        Text((incidentToEdit?.timestamp ?? Date())
                            .formatted(date: .abbreviated, time: .shortened))
                    }
                }

                Section(header: Text("Location")) {
                    TextField("Where did this occur? (e.g. Garden)", text: $location)
                }

                Section(header: Text("Description of Incident")) {
                    TextEditor(text: $descriptionOfIncident).frame(minHeight: 100)
                }

                Section(header: Text("Immediate Action Taken")) {
                    TextEditor(text: $actionTaken).frame(minHeight: 80)
                }

                Section(header: Text("Witnesses (optional)")) {
                    TextField("Names of any witnesses", text: $witnesses)
                }

                // Photo Evidence
                Section(header: Text("Photo Evidence (optional)")) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(
                            selectedImageData == nil ? "Attach a Photo" : "Change Photo",
                            systemImage: "photo.badge.plus"
                        )
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }

                    if let data = selectedImageData, let uiImage = UIImage(data: data) {
                        VStack(alignment: .leading, spacing: 8) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 180)
                                .cornerRadius(10)
                            Button(role: .destructive) {
                                selectedImageData = nil
                                selectedPhoto = nil
                            } label: {
                                Label("Remove Photo", systemImage: "trash")
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    HStack {
                        Text("Logged by:").foregroundColor(.secondary)
                        Spacer()
                        Text(incidentToEdit?.keyworkerName ?? keyworkerName).fontWeight(.medium)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Incident" : "Report Incident")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Update" : "Save") {
                        if isEditing {
                            showUpdateConfirmation = true
                        } else {
                            save()
                        }
                    }
                    .disabled(isSaveDisabled)
                }
            }
            .alert("Save Changes?", isPresented: $showUpdateConfirmation) {
                Button("Save Changes") { save() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to update this incident report?")
            }
            .onAppear {
                if let i = incidentToEdit {
                    category = i.category
                    location = i.location
                    descriptionOfIncident = i.descriptionOfIncident
                    actionTaken = i.actionTaken
                    witnesses = i.witnesses
                    selectedImageData = i.imageData
                }
            }
        }
    }

    private func save() {
        if let i = incidentToEdit {
            i.category = category
            i.location = location
            i.descriptionOfIncident = descriptionOfIncident
            i.actionTaken = actionTaken
            i.witnesses = witnesses
            i.imageData = selectedImageData
        } else {
            let entry = IncidentReport(
                category: category,
                location: location,
                descriptionOfIncident: descriptionOfIncident,
                actionTaken: actionTaken,
                witnesses: witnesses,
                keyworkerName: keyworkerName,
                imageData: selectedImageData
            )
            entry.child = child
            modelContext.insert(entry)
        }
        try? modelContext.save()
        onSaved?()
        dismiss()
    }
}
