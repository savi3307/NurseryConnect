import Foundation
import SwiftData

// MARK: - Child

@Model
final class Child {
    var id: UUID
    var firstName: String
    var lastName: String
    var dateOfBirth: Date
    var allergies: String
    var emergencyContact: String

    @Relationship(deleteRule: .cascade, inverse: \DailyActivity.child)
    var dailyActivities: [DailyActivity] = []

    @Relationship(deleteRule: .cascade, inverse: \SleepLog.child)
    var sleepLogs: [SleepLog] = []

    @Relationship(deleteRule: .cascade, inverse: \NappyLog.child)
    var nappyLogs: [NappyLog] = []

    @Relationship(deleteRule: .cascade, inverse: \MoodLog.child)
    var moodLogs: [MoodLog] = []

    @Relationship(deleteRule: .cascade, inverse: \IncidentReport.child)
    var incidents: [IncidentReport] = []

    init(id: UUID = UUID(), firstName: String, lastName: String, dateOfBirth: Date,
         allergies: String = "", emergencyContact: String) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.allergies = allergies
        self.emergencyContact = emergencyContact
    }

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - Daily Activity

@Model
final class DailyActivity {
    var id: UUID
    var timestamp: Date
    var activityType: String   // Indoor Play, Outdoor Play, Reading, Arts & Crafts,
                                // Educational Session, Free Play, Rest Period
    var details: String
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), activityType: String, details: String) {
        self.id = id
        self.timestamp = timestamp
        self.activityType = activityType
        self.details = details
    }
}

// MARK: - Sleep Log

@Model
final class SleepLog {
    var id: UUID
    var startTime: Date
    var endTime: Date?          // nil = still sleeping
    var sleepPosition: String   // On Back, On Side, On Front
    var notes: String
    var child: Child?

    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil,
         sleepPosition: String, notes: String = "") {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.sleepPosition = sleepPosition
        self.notes = notes
    }

    /// Duration in minutes; nil while child is still sleeping.
    var durationMinutes: Int? {
        guard let end = endTime else { return nil }
        return Int(end.timeIntervalSince(startTime) / 60)
    }

    var durationText: String {
        guard let mins = durationMinutes else { return "Still sleeping" }
        let h = mins / 60
        let m = mins % 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m) min"
    }
}

// MARK: - Nappy / Toilet Log

@Model
final class NappyLog {
    var id: UUID
    var timestamp: Date
    var type: String            // Wet, Dirty, Both, Dry, Dry Check
    var observations: String
    var isConcerning: Bool
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), type: String,
         observations: String = "", isConcerning: Bool = false) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.observations = observations
        self.isConcerning = isConcerning
    }
}

// MARK: - Mood / Wellbeing Log

@Model
final class MoodLog {
    var id: UUID
    var timestamp: Date
    var checkInPeriod: String   // Arrival, Midday, Departure
    var mood: String            // Happy, Settled, Unsettled, Poorly
    var notes: String
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), checkInPeriod: String,
         mood: String, notes: String = "") {
        self.id = id
        self.timestamp = timestamp
        self.checkInPeriod = checkInPeriod
        self.mood = mood
        self.notes = notes
    }

    var moodEmoji: String {
        switch mood {
        case "Happy":    return "😊"
        case "Settled":  return "🙂"
        case "Unsettled": return "😟"
        case "Poorly":   return "🤒"
        default:         return "❓"
        }
    }
}

// MARK: - Incident Report

@Model
final class IncidentReport {
    var id: UUID
    var timestamp: Date
    var category: String        // Accident (Minor), Accident (First Aid Required),
                                // Safeguarding Concern, Near Miss,
                                // Allergic Reaction, Medical Incident
    var location: String
    var descriptionOfIncident: String
    var actionTaken: String
    var witnesses: String
    var keyworkerName: String
    var imageData: Data?        // optional photo evidence
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), category: String,
         location: String, descriptionOfIncident: String, actionTaken: String,
         witnesses: String = "", keyworkerName: String, imageData: Data? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.location = location
        self.descriptionOfIncident = descriptionOfIncident
        self.actionTaken = actionTaken
        self.witnesses = witnesses
        self.keyworkerName = keyworkerName
        self.imageData = imageData
    }

    var categoryColor: String {
        switch category {
        case "Safeguarding Concern": return "purple"
        case "Accident (First Aid Required)": return "orange"
        case "Allergic Reaction": return "red"
        case "Medical Incident": return "red"
        default: return "yellow"
        }
    }
}
