import Foundation
import FirebaseFirestore

// MARK: - Firestore Service
@MainActor
class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()

    // MARK: - Events

    /// Fetch events for a user within a date range
    func fetchEvents(userId: String, from startDate: Date, to endDate: Date) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("userId", isEqualTo: userId)
            .whereField("startTime", isGreaterThanOrEqualTo: startDate)
            .whereField("startTime", isLessThanOrEqualTo: endDate)
            .order(by: "startTime")
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Event.self) }
    }

    /// Fetch events for a specific day
    func fetchEventsForDay(userId: String, date: Date) async throws -> [Event] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return try await fetchEvents(userId: userId, from: startOfDay, to: endOfDay)
    }

    /// Fetch all AI-generated events for a user
    func fetchAIGeneratedEvents(userId: String) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("userId", isEqualTo: userId)
            .whereField("isAIGenerated", isEqualTo: true)
            .order(by: "startTime")
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Event.self) }
    }

    /// Fetch all manual events for a user
    func fetchManualEvents(userId: String) async throws -> [Event] {
        let snapshot = try await db.collection("events")
            .whereField("userId", isEqualTo: userId)
            .whereField("isAIGenerated", isEqualTo: false)
            .order(by: "startTime")
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Event.self) }
    }

    /// Create a new event
    func createEvent(_ event: Event) async throws -> Event {
        var newEvent = event
        let docRef = db.collection("events").document()
        newEvent.id = docRef.documentID
        try docRef.setData(from: newEvent)
        return newEvent
    }

    /// Create multiple events at once
    func createEvents(_ events: [Event]) async throws -> [Event] {
        let batch = db.batch()
        var createdEvents: [Event] = []

        for var event in events {
            let docRef = db.collection("events").document()
            event.id = docRef.documentID
            try batch.setData(from: event, forDocument: docRef)
            createdEvents.append(event)
        }

        try await batch.commit()
        return createdEvents
    }

    /// Update an event (for time changes on AI events or full edits on manual events)
    func updateEvent(_ event: Event) async throws {
        guard let eventId = event.id else { return }
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        try db.collection("events").document(eventId).setData(from: updatedEvent)
    }

    /// Update only the time of an AI-generated event
    func updateEventTime(eventId: String, newStartTime: Date, newEndTime: Date) async throws {
        try await db.collection("events").document(eventId).updateData([
            "startTime": newStartTime,
            "endTime": newEndTime,
            "updatedAt": Date()
        ])
    }

    /// Mark event as completed
    func markEventCompleted(eventId: String, completed: Bool) async throws {
        try await db.collection("events").document(eventId).updateData([
            "isCompleted": completed,
            "updatedAt": Date()
        ])
    }

    /// Delete an event (only for manual events)
    func deleteEvent(eventId: String) async throws {
        try await db.collection("events").document(eventId).delete()
    }

    /// Delete all AI-generated events for a user (for goal reset)
    func deleteAIGeneratedEvents(userId: String) async throws {
        let snapshot = try await db.collection("events")
            .whereField("userId", isEqualTo: userId)
            .whereField("isAIGenerated", isEqualTo: true)
            .getDocuments()

        let batch = db.batch()
        for document in snapshot.documents {
            batch.deleteDocument(document.reference)
        }

        try await batch.commit()
    }

    // MARK: - Journal Entries

    /// Fetch journal entries for a user
    func fetchJournalEntries(userId: String, limit: Int = 30) async throws -> [JournalEntry] {
        let snapshot = try await db.collection("journalEntries")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: JournalEntry.self) }
    }

    /// Fetch journal entry for a specific date
    func fetchJournalEntry(userId: String, date: Date) async throws -> JournalEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let snapshot = try await db.collection("journalEntries")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: startOfDay)
            .whereField("date", isLessThan: endOfDay)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { try? $0.data(as: JournalEntry.self) }
    }

    /// Fetch journal entries for a week
    func fetchJournalEntriesForWeek(userId: String, weekStartDate: Date) async throws -> [JournalEntry] {
        let weekEndDate = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate)!

        let snapshot = try await db.collection("journalEntries")
            .whereField("userId", isEqualTo: userId)
            .whereField("date", isGreaterThanOrEqualTo: weekStartDate)
            .whereField("date", isLessThan: weekEndDate)
            .order(by: "date")
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: JournalEntry.self) }
    }

    /// Create or update journal entry
    func saveJournalEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        var savedEntry = entry

        if let entryId = entry.id {
            // Update existing
            savedEntry.updatedAt = Date()
            try db.collection("journalEntries").document(entryId).setData(from: savedEntry)
        } else {
            // Create new
            let docRef = db.collection("journalEntries").document()
            savedEntry.id = docRef.documentID
            try docRef.setData(from: savedEntry)
        }

        return savedEntry
    }

    /// Delete journal entry
    func deleteJournalEntry(entryId: String) async throws {
        try await db.collection("journalEntries").document(entryId).delete()
    }

    // MARK: - Weekly Reviews

    /// Create weekly review
    func saveWeeklyReview(_ review: WeeklyReview) async throws -> WeeklyReview {
        var savedReview = review

        if let reviewId = review.id {
            try db.collection("weeklyReviews").document(reviewId).setData(from: savedReview)
        } else {
            let docRef = db.collection("weeklyReviews").document()
            savedReview.id = docRef.documentID
            try docRef.setData(from: savedReview)
        }

        return savedReview
    }

    /// Fetch weekly reviews
    func fetchWeeklyReviews(userId: String, limit: Int = 12) async throws -> [WeeklyReview] {
        let snapshot = try await db.collection("weeklyReviews")
            .whereField("userId", isEqualTo: userId)
            .order(by: "weekStartDate", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: WeeklyReview.self) }
    }

    // MARK: - AI Generated Plans

    /// Save AI generated plan
    func saveAIPlan(_ plan: AIGeneratedPlan) async throws -> AIGeneratedPlan {
        var savedPlan = plan

        if let planId = plan.id {
            try db.collection("aiPlans").document(planId).setData(from: savedPlan)
        } else {
            let docRef = db.collection("aiPlans").document()
            savedPlan.id = docRef.documentID
            try docRef.setData(from: savedPlan)
        }

        return savedPlan
    }

    /// Fetch active AI plan for user
    func fetchActiveAIPlan(userId: String) async throws -> AIGeneratedPlan? {
        let snapshot = try await db.collection("aiPlans")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { try? $0.data(as: AIGeneratedPlan.self) }
    }

    /// Deactivate all AI plans for user
    func deactivateAllAIPlans(userId: String) async throws {
        let snapshot = try await db.collection("aiPlans")
            .whereField("userId", isEqualTo: userId)
            .whereField("isActive", isEqualTo: true)
            .getDocuments()

        let batch = db.batch()
        for document in snapshot.documents {
            batch.updateData(["isActive": false], forDocument: document.reference)
        }

        try await batch.commit()
    }

    // MARK: - User Stats

    /// Update user stats
    func updateUserStats(userId: String, stats: UserStats) async throws {
        try await db.collection("users").document(userId).updateData([
            "stats": [
                "totalJournalEntries": stats.totalJournalEntries,
                "currentJournalStreak": stats.currentJournalStreak,
                "longestJournalStreak": stats.longestJournalStreak,
                "totalManualEvents": stats.totalManualEvents,
                "totalAIEventsCompleted": stats.totalAIEventsCompleted,
                "achievementsUnlocked": stats.achievementsUnlocked
            ]
        ])
    }

    /// Increment manual events count
    func incrementManualEventsCount(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "stats.totalManualEvents": FieldValue.increment(Int64(1))
        ])
    }

    /// Increment AI events completed count
    func incrementAIEventsCompleted(userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "stats.totalAIEventsCompleted": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Real-time Listeners

    /// Listen to events for a date range
    func listenToEvents(
        userId: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping ([Event]) -> Void
    ) -> ListenerRegistration {
        return db.collection("events")
            .whereField("userId", isEqualTo: userId)
            .whereField("startTime", isGreaterThanOrEqualTo: startDate)
            .whereField("startTime", isLessThanOrEqualTo: endDate)
            .order(by: "startTime")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let events = documents.compactMap { try? $0.data(as: Event.self) }
                completion(events)
            }
    }

    /// Listen to journal entries
    func listenToJournalEntries(
        userId: String,
        completion: @escaping ([JournalEntry]) -> Void
    ) -> ListenerRegistration {
        return db.collection("journalEntries")
            .whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .limit(to: 30)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let entries = documents.compactMap { try? $0.data(as: JournalEntry.self) }
                completion(entries)
            }
    }
}
