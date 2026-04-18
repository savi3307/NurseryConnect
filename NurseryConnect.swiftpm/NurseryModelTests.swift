import XCTest
import SwiftData
@testable import NurseryConnect

// MARK: - Shared helpers

private func makeSchema() -> Schema {
    Schema([
        Child.self,
        DailyActivity.self,
        SleepLog.self,
        NappyLog.self,
        MoodLog.self,
        IncidentReport.self,
    ])
}

private func makeChild(
    firstName: String = "Test",
    lastName: String = "Child",
    dob: Date = Date(),
    allergies: String = "",
    emergency: String = "Parent: 07700900000"
) -> Child {
    Child(firstName: firstName, lastName: lastName,
          dateOfBirth: dob, allergies: allergies,
          emergencyContact: emergency)
}

// MARK: - ChildModelTests

final class ChildModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: makeSchema(), configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: fullName

    func testFullName_ConcatenatesFirstAndLast() {
        let child = makeChild(firstName: "Emma", lastName: "Jones")
        XCTAssertEqual(child.fullName, "Emma Jones")
    }

    func testFullName_WithSingleWordLastName() {
        let child = makeChild(firstName: "Leo", lastName: "Smith")
        XCTAssertEqual(child.fullName, "Leo Smith")
    }

    // MARK: Unique ID

    func testChild_HasUniqueIDByDefault() {
        let c1 = makeChild()
        let c2 = makeChild()
        XCTAssertNotEqual(c1.id, c2.id)
    }

    func testChild_AcceptsExplicitID() {
        let id = UUID()
        let child = Child(id: id, firstName: "A", lastName: "B", dateOfBirth: Date(),
                          emergencyContact: "X")
        XCTAssertEqual(child.id, id)
    }

    // MARK: Defaults

    func testChild_DefaultAllergiesIsEmpty() {
        let child = makeChild()
        XCTAssertTrue(child.allergies.isEmpty)
    }

    func testChild_AllergiesStoredCorrectly() {
        let child = makeChild(allergies: "Peanuts, Milk")
        XCTAssertEqual(child.allergies, "Peanuts, Milk")
    }

    func testChild_EmergencyContactStored() {
        let child = makeChild(emergency: "Mum: 07700900123")
        XCTAssertEqual(child.emergencyContact, "Mum: 07700900123")
    }

    // MARK: Relationships initialised empty

    func testChild_DailyActivitiesStartEmpty() {
        let child = makeChild()
        XCTAssertTrue(child.dailyActivities.isEmpty)
    }

    func testChild_SleepLogsStartEmpty() {
        let child = makeChild()
        XCTAssertTrue(child.sleepLogs.isEmpty)
    }

    func testChild_NappyLogsStartEmpty() {
        let child = makeChild()
        XCTAssertTrue(child.nappyLogs.isEmpty)
    }

    func testChild_MoodLogsStartEmpty() {
        let child = makeChild()
        XCTAssertTrue(child.moodLogs.isEmpty)
    }

    func testChild_IncidentsStartEmpty() {
        let child = makeChild()
        XCTAssertTrue(child.incidents.isEmpty)
    }

    // MARK: Persistence

    func testChild_CanBeSavedAndFetched() throws {
        let child = makeChild(firstName: "Sophie", lastName: "Brown")
        context.insert(child)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Child>())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.fullName, "Sophie Brown")
    }

    func testChild_MultipleChildrenStoredIndependently() throws {
        context.insert(makeChild(firstName: "Alice", lastName: "A"))
        context.insert(makeChild(firstName: "Bob", lastName: "B"))
        context.insert(makeChild(firstName: "Charlie", lastName: "C"))
        try context.save()

        let results = try context.fetch(FetchDescriptor<Child>())
        XCTAssertEqual(results.count, 3)
    }
}

// MARK: - DailyActivityTests

final class DailyActivityTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: makeSchema(), configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testDailyActivity_DefaultTimestampIsNow() {
        let before = Date()
        let activity = DailyActivity(activityType: "Reading", details: "Storytime")
        XCTAssertGreaterThanOrEqual(activity.timestamp, before)
    }

    func testDailyActivity_StoresActivityType() {
        let activity = DailyActivity(activityType: "Outdoor Play", details: "Football")
        XCTAssertEqual(activity.activityType, "Outdoor Play")
    }

    func testDailyActivity_StoresDetails() {
        let activity = DailyActivity(activityType: "Arts & Crafts", details: "Painted a butterfly")
        XCTAssertEqual(activity.details, "Painted a butterfly")
    }

    func testDailyActivity_HasUniqueID() {
        let a1 = DailyActivity(activityType: "Reading", details: "")
        let a2 = DailyActivity(activityType: "Reading", details: "")
        XCTAssertNotEqual(a1.id, a2.id)
    }

    func testDailyActivity_LinksToChild() throws {
        let child = makeChild(firstName: "Mia", lastName: "White")
        context.insert(child)

        let activity = DailyActivity(activityType: "Free Play", details: "Block building")
        activity.child = child
        context.insert(activity)
        try context.save()

        let activities = try context.fetch(FetchDescriptor<DailyActivity>())
        XCTAssertEqual(activities.first?.child?.firstName, "Mia")
    }

    func testDailyActivity_CascadeDeletedWithChild() throws {
        let child = makeChild()
        context.insert(child)

        let activity = DailyActivity(activityType: "Indoor Play", details: "Lego")
        activity.child = child
        context.insert(activity)
        try context.save()

        context.delete(child)
        try context.save()

        let activities = try context.fetch(FetchDescriptor<DailyActivity>())
        XCTAssertTrue(activities.isEmpty, "Activities should be cascade-deleted with child")
    }
}

// MARK: - SleepLogTests

final class SleepLogTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: makeSchema(), configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testSleepLog_DurationNilWhileSleeping() {
        let log = SleepLog(sleepPosition: "On Back")
        XCTAssertNil(log.durationMinutes)
    }

    func testSleepLog_DurationTextWhileSleeping() {
        let log = SleepLog(sleepPosition: "On Back")
        XCTAssertEqual(log.durationText, "Still sleeping")
    }

    func testSleepLog_DurationMinutesCalculatedCorrectly() {
        let start = Date()
        let end = start.addingTimeInterval(90 * 60)    // 90 minutes
        let log = SleepLog(startTime: start, endTime: end, sleepPosition: "On Side")
        XCTAssertEqual(log.durationMinutes, 90)
    }

    func testSleepLog_DurationTextMinutesOnly() {
        let start = Date()
        let end = start.addingTimeInterval(45 * 60)    // 45 min
        let log = SleepLog(startTime: start, endTime: end, sleepPosition: "On Back")
        XCTAssertEqual(log.durationText, "45 min")
    }

    func testSleepLog_DurationTextHoursAndMinutes() {
        let start = Date()
        let end = start.addingTimeInterval((2 * 60 + 30) * 60)   // 2h 30m
        let log = SleepLog(startTime: start, endTime: end, sleepPosition: "On Back")
        XCTAssertEqual(log.durationText, "2h 30m")
    }

    func testSleepLog_DurationTextExactHour() {
        let start = Date()
        let end = start.addingTimeInterval(60 * 60)    // exactly 1h
        let log = SleepLog(startTime: start, endTime: end, sleepPosition: "On Side")
        XCTAssertEqual(log.durationText, "1h 0m")
    }

    func testSleepLog_StoresSleepPosition() {
        let log = SleepLog(sleepPosition: "On Front")
        XCTAssertEqual(log.sleepPosition, "On Front")
    }

    func testSleepLog_DefaultNotesEmpty() {
        let log = SleepLog(sleepPosition: "On Back")
        XCTAssertTrue(log.notes.isEmpty)
    }

    func testSleepLog_HasUniqueID() {
        let l1 = SleepLog(sleepPosition: "On Back")
        let l2 = SleepLog(sleepPosition: "On Back")
        XCTAssertNotEqual(l1.id, l2.id)
    }

    func testSleepLog_CascadeDeletedWithChild() throws {
        let child = makeChild()
        context.insert(child)

        let log = SleepLog(sleepPosition: "On Back")
        log.child = child
        context.insert(log)
        try context.save()

        context.delete(child)
        try context.save()

        let logs = try context.fetch(FetchDescriptor<SleepLog>())
        XCTAssertTrue(logs.isEmpty, "SleepLogs should be cascade-deleted with child")
    }
}

// MARK: - NappyLogTests

final class NappyLogTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: makeSchema(), configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    func testNappyLog_StoresType() {
        let log = NappyLog(type: "Wet")
        XCTAssertEqual(log.type, "Wet")
    }

    func testNappyLog_DefaultIsConcerningFalse() {
        let log = NappyLog(type: "Dry")
        XCTAssertFalse(log.isConcerning)
    }

    func testNappyLog_IsConcerningCanBeSetTrue() {
        let log = NappyLog(type: "Dirty", isConcerning: true)
        XCTAssertTrue(log.isConcerning)
    }

    func testNappyLog_DefaultObservationsEmpty() {
        let log = NappyLog(type: "Wet")
        XCTAssertTrue(log.observations.isEmpty)
    }

    func testNappyLog_ObservationsStored() {
        let log = NappyLog(type: "Both", observations: "Slight rash")
        XCTAssertEqual(log.observations, "Slight rash")
    }

    func testNappyLog_DefaultTimestampIsNow() {
        let before = Date()
        let log = NappyLog(type: "Dry Check")
        XCTAssertGreaterThanOrEqual(log.timestamp, before)
    }

    func testNappyLog_HasUniqueID() {
        let l1 = NappyLog(type: "Wet")
        let l2 = NappyLog(type: "Wet")
        XCTAssertNotEqual(l1.id, l2.id)
    }

    func testNappyLog_LinksToChild() throws {
        let child = makeChild(firstName: "Jack", lastName: "Green")
        context.insert(child)

        let log = NappyLog(type: "Dirty")
        log.child = child
        context.insert(log)
        try context.save()

        let logs = try context.fetch(FetchDescriptor<NappyLog>())
        XCTAssertEqual(logs.first?.child?.firstName, "Jack")
    }

    func testNappyLog_CascadeDeletedWithChild() throws {
        let child = makeChild()
        context.insert(child)

        let log = NappyLog(type: "Wet")
        log.child = child
        context.insert(log)
        try context.save()

        context.delete(child)
        try context.save()

        let logs = try context.fetch(FetchDescriptor<NappyLog>())
        XCTAssertTrue(logs.isEmpty, "NappyLogs should be cascade-deleted with child")
    }
}

// MARK: - MoodLogTests

final class MoodLogTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: makeSchema(), configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    // MARK: moodEmoji

    func testMoodEmoji_Happy() {
        let log = MoodLog(checkInPeriod: "Arrival", mood: "Happy")
        XCTAssertEqual(log.moodEmoji, "😊")
    }

    func testMoodEmoji_Settled() {
        let log = MoodLog(checkInPeriod: "Midday", mood: "Settled")
        XCTAssertEqual(log.moodEmoji, "🙂")
    }

    func testMoodEmoji_Unsettled() {
        let log = MoodLog(checkInPeriod: "Departure", mood: "Unsettled")
        XCTAssertEqual(log.moodEmoji, "😟")
    }

    func testMoodEmoji_Poorly() {
        let log = MoodLog(checkInPeriod: "Midday", mood: "Poorly")
        XCTAssertEqual(log.moodEmoji, "🤒")
    }

    func testMoodEmoji_UnknownMoodFallback() {
        let log = MoodLog(checkInPeriod: "Arrival", mood: "Excited")
        XCTAssertEqual(log.moodEmoji, "❓")
    }

    // MARK: Stored properties

    func testMoodLog_StoresCheckInPeriod() {
        let log = MoodLog(checkInPeriod: "Arrival", mood: "Happy")
        XCTAssertEqual(log.checkInPeriod, "Arrival")
    }

    func testMoodLog_StoresMood() {
        let log = MoodLog(checkInPeriod: "Midday", mood: "Settled")
        XCTAssertEqual(log.mood, "Settled")
    }

    func testMoodLog_DefaultNotesEmpty() {
        let log = MoodLog(checkInPeriod: "Arrival", mood: "Happy")
        XCTAssertTrue(log.notes.isEmpty)
    }

    func testMoodLog_NotesStored() {
        let log = MoodLog(checkInPeriod: "Departure", mood: "Unsettled", notes: "Cried at pickup")
        XCTAssertEqual(log.notes, "Cried at pickup")
    }

    func testMoodLog_HasUniqueID() {
        let l1 = MoodLog(checkInPeriod: "Arrival", mood: "Happy")
        let l2 = MoodLog(checkInPeriod: "Arrival", mood: "Happy")
        XCTAssertNotEqual(l1.id, l2.id)
    }

    func testMoodLog_CascadeDeletedWithChild() throws {
        let child = makeChild()
        context.insert(child)

        let log = MoodLog(checkInPeriod: "Midday", mood: "Settled")
        log.child = child
        context.insert(log)
        try context.save()

        context.delete(child)
        try context.save()

        let logs = try context.fetch(FetchDescriptor<MoodLog>())
        XCTAssertTrue(logs.isEmpty, "MoodLogs should be cascade-deleted with child")
    }

    func testMoodLog_DefaultTimestampIsNow() {
        let before = Date()
        let log = MoodLog(checkInPeriod: "Arrival", mood: "Happy")
        XCTAssertGreaterThanOrEqual(log.timestamp, before)
    }
}

// MARK: - IncidentReportTests

final class IncidentReportTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: makeSchema(), configurations: [config])
        context = ModelContext(container)
    }

    override func tearDownWithError() throws {
        container = nil
        context = nil
    }

    private func makeReport(
        category: String = "Accident (Minor)",
        location: String = "Garden",
        description: String = "Scraped knee",
        action: String = "First aid applied",
        keyworker: String = "Jane Doe"
    ) -> IncidentReport {
        IncidentReport(category: category, location: location,
                       descriptionOfIncident: description, actionTaken: action,
                       keyworkerName: keyworker)
    }

    // MARK: categoryColor

    func testCategoryColor_SafeguardingConcernIsPurple() {
        let report = makeReport(category: "Safeguarding Concern")
        XCTAssertEqual(report.categoryColor, "purple")
    }

    func testCategoryColor_FirstAidRequiredIsOrange() {
        let report = makeReport(category: "Accident (First Aid Required)")
        XCTAssertEqual(report.categoryColor, "orange")
    }

    func testCategoryColor_AllergicReactionIsRed() {
        let report = makeReport(category: "Allergic Reaction")
        XCTAssertEqual(report.categoryColor, "red")
    }

    func testCategoryColor_MedicalIncidentIsRed() {
        let report = makeReport(category: "Medical Incident")
        XCTAssertEqual(report.categoryColor, "red")
    }

    func testCategoryColor_DefaultIsYellow() {
        let report = makeReport(category: "Accident (Minor)")
        XCTAssertEqual(report.categoryColor, "yellow")
    }

    func testCategoryColor_NearMissIsYellow() {
        let report = makeReport(category: "Near Miss")
        XCTAssertEqual(report.categoryColor, "yellow")
    }

    // MARK: Stored properties

    func testReport_StoresCategory() {
        let report = makeReport(category: "Near Miss")
        XCTAssertEqual(report.category, "Near Miss")
    }

    func testReport_StoresLocation() {
        let report = makeReport(location: "Hallway")
        XCTAssertEqual(report.location, "Hallway")
    }

    func testReport_StoresDescription() {
        let report = makeReport(description: "Bumped head on table edge")
        XCTAssertEqual(report.descriptionOfIncident, "Bumped head on table edge")
    }

    func testReport_StoresActionTaken() {
        let report = makeReport(action: "Ice pack applied, parents notified")
        XCTAssertEqual(report.actionTaken, "Ice pack applied, parents notified")
    }

    func testReport_StoresKeyworkerName() {
        let report = makeReport(keyworker: "Sarah Mills")
        XCTAssertEqual(report.keyworkerName, "Sarah Mills")
    }

    func testReport_DefaultWitnessesEmpty() {
        let report = makeReport()
        XCTAssertTrue(report.witnesses.isEmpty)
    }

    func testReport_WitnessesStored() {
        let report = IncidentReport(category: "Accident (Minor)", location: "Room",
                                    descriptionOfIncident: "Trip", actionTaken: "Checked",
                                    witnesses: "K. Jones, P. Smith", keyworkerName: "A. Green")
        XCTAssertEqual(report.witnesses, "K. Jones, P. Smith")
    }

    func testReport_DefaultImageDataNil() {
        let report = makeReport()
        XCTAssertNil(report.imageData)
    }

    func testReport_ImageDataStored() {
        let data = Data([0x89, 0x50, 0x4E, 0x47])   // PNG header bytes
        let report = IncidentReport(category: "Accident (Minor)", location: "Room",
                                    descriptionOfIncident: "Fall", actionTaken: "Checked",
                                    keyworkerName: "T. Lee", imageData: data)
        XCTAssertEqual(report.imageData, data)
    }

    func testReport_HasUniqueID() {
        let r1 = makeReport()
        let r2 = makeReport()
        XCTAssertNotEqual(r1.id, r2.id)
    }

    func testReport_DefaultTimestampIsNow() {
        let before = Date()
        let report = makeReport()
        XCTAssertGreaterThanOrEqual(report.timestamp, before)
    }

    // MARK: Persistence & cascade

    func testReport_CanBeSavedAndFetched() throws {
        let report = makeReport(category: "Near Miss")
        context.insert(report)
        try context.save()

        let results = try context.fetch(FetchDescriptor<IncidentReport>())
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.category, "Near Miss")
    }

    func testReport_CascadeDeletedWithChild() throws {
        let child = makeChild()
        context.insert(child)

        let report = makeReport()
        report.child = child
        context.insert(report)
        try context.save()

        context.delete(child)
        try context.save()

        let reports = try context.fetch(FetchDescriptor<IncidentReport>())
        XCTAssertTrue(reports.isEmpty, "IncidentReports should be cascade-deleted with child")
    }
}
