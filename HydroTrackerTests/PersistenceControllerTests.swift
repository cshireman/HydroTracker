//
//  PersistenceControllerTests.swift
//  HydroTrackerTests
//
//  Created by Chris Shireman on 11/10/25.
//

import Testing
import CoreData
@testable import HydroTracker

@MainActor
struct PersistenceControllerTests {

    // MARK: - Test In-Memory Store

    @Test("In-memory persistence controller is created successfully")
    func testInMemoryInitialization() async throws {
        let controller = PersistenceController(inMemory: true)
        #expect(controller.container.persistentStoreDescriptions.first?.url?.absoluteString.contains("/dev/null") == true)
    }

    @Test("In-memory store can save and fetch HydrationEntry")
    func testInMemorySaveAndFetch() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create entry
        let entry = HydrationEntry(
            context: context,
            amountMl: 500.0,
            createdAt: Date(),
            source: .iphone
        )

        try context.save()

        // Fetch entry
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first?.amountMl == 500.0)
        #expect(results.first?.source == .iphone)
    }

    @Test("In-memory store can save and fetch UserPrefs")
    func testInMemoryUserPrefsSaveAndFetch() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create prefs
        let prefs = UserPrefs(
            context: context,
            dailyGoalMl: 2500.0,
            unit: .oz,
            presetsMl: [250.0, 500.0, 750.0]
        )

        try context.save()

        // Fetch prefs
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first?.dailyGoalMl == 2500.0)
        #expect(results.first?.unit == .oz)
        #expect(results.first?.presetsMl == [250.0, 500.0, 750.0])
    }

    // MARK: - Test Context Configuration

    @Test("View context has automatic merge enabled")
    func testViewContextConfiguration() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        #expect(context.automaticallyMergesChangesFromParent == true)
    }

    // MARK: - Test Multiple Entries

    @Test("Can create and fetch multiple entries")
    func testMultipleEntries() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create multiple entries
        for i in 1...5 {
            _ = HydrationEntry(
                context: context,
                amountMl: Double(i * 100),
                createdAt: Date().addingTimeInterval(TimeInterval(i * 60)),
                source: i % 2 == 0 ? .iphone : .watch
            )
        }

        try context.save()

        // Fetch all entries
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 5)
    }

    // MARK: - Test Entry Deletion

    @Test("Can mark entry as deleted")
    func testEntryDeletion() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create entry
        let entry = HydrationEntry(
            context: context,
            amountMl: 500.0,
            createdAt: Date(),
            source: .iphone
        )

        try context.save()

        // Mark as deleted
        entry.isDeletedFlag = true
        try context.save()

        // Verify deletion flag
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.first?.isDeletedFlag == true)
    }

    // MARK: - Test Predicate Filtering

    @Test("Can filter entries by date range")
    func testDateRangeFiltering() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Create entries for different days
        _ = HydrationEntry(
            context: context,
            amountMl: 500.0,
            createdAt: today.addingTimeInterval(3600), // Today
            source: .iphone
        )

        _ = HydrationEntry(
            context: context,
            amountMl: 600.0,
            createdAt: yesterday.addingTimeInterval(3600), // Yesterday
            source: .iphone
        )

        try context.save()

        // Fetch only today's entries
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: today) else {
            throw NSError(domain: "TestError", code: 1)
        }

        fetchRequest.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            today as NSDate,
            endOfDay as NSDate
        )

        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first?.amountMl == 500.0)
    }

    // MARK: - Test Delete Filter

    @Test("Can filter out deleted entries")
    func testDeletedFilter() async throws {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Create normal entry
        _ = HydrationEntry(
            context: context,
            amountMl: 500.0,
            createdAt: Date(),
            source: .iphone,
            isDeleted: false
        )

        // Create deleted entry
        _ = HydrationEntry(
            context: context,
            amountMl: 600.0,
            createdAt: Date(),
            source: .iphone,
            isDeleted: true
        )

        try context.save()

        // Fetch non-deleted entries
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDeletedFlag == NO")

        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first?.amountMl == 500.0)
    }
}
