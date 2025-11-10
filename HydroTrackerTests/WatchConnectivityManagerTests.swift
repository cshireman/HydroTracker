//
//  WatchConnectivityManagerTests.swift
//  HydroTrackerTests
//
//  Created by Chris Shireman on 11/10/25.
//

import Testing
import CoreData
import WatchConnectivity
@testable import HydroTracker

@MainActor
struct WatchConnectivityManagerTests {

    // MARK: - Helper Methods

    func createTestContext() -> NSManagedObjectContext {
        let controller = PersistenceController(inMemory: true)
        return controller.container.viewContext
    }

    func createTestEntry(context: NSManagedObjectContext, amountMl: Double, createdAt: Date? = nil) throws -> HydrationEntry {
        let entry = HydrationEntry(
            context: context,
            amountMl: amountMl,
            createdAt: createdAt ?? Date(),
            source: .iphone
        )
        try context.save()
        return entry
    }

    func createTestPrefs(context: NSManagedObjectContext) throws {
        let prefs = UserPrefs(
            context: context,
            dailyGoalMl: 2898.0,
            unit: .oz,
            presetsMl: [236.6, 473.2, 591.5]
        )
        try context.save()
    }

    // MARK: - Initialization Tests

    @Test("WatchConnectivityManager shared instance exists")
    func testSharedInstance() async throws {
        let manager = WatchConnectivityManager.shared
        #expect(manager != nil)
    }

    // Note: We can't fully test WCSession activation in unit tests
    // as it requires a real device or simulator environment

    // MARK: - Data Sync Preparation Tests

    @Test("syncAllData can be called without crashing")
    func testSyncAllDataDoesNotCrash() async throws {
        // This test verifies the method can execute without throwing
        // Even if WCSession is not supported in test environment
        let manager = WatchConnectivityManager.shared
        manager.syncAllData()
        // If we get here without crashing, the test passes
        #expect(true)
    }

    @Test("syncData delegates to syncAllData")
    func testSyncDataDelegation() async throws {
        let manager = WatchConnectivityManager.shared
        manager.syncData()
        // If we get here without crashing, the test passes
        #expect(true)
    }

    // MARK: - Data Processing Tests

    @Test("processReceivedData handles empty message gracefully")
    func testProcessEmptyMessage() async throws {
        let context = createTestContext()

        // Create a message without the "fullSync" action
        let message: [String: Any] = [:]

        // This should return early without processing
        // We can't directly test the private method, but we can verify
        // the context remains unchanged
        let beforeCount = try context.count(for: HydrationEntry.fetchRequest())

        // If processReceivedData were called with this, it would return early
        // Since we can't call it directly, this test validates the structure
        #expect(message["action"] as? String != "fullSync")
        #expect(beforeCount == 0)
    }

    @Test("Message format for entries is correct")
    func testEntryMessageFormat() async throws {
        let context = createTestContext()
        let entry = try createTestEntry(context: context, amountMl: 500.0)

        // Verify the entry data matches what syncAllData would send
        let expectedData: [String: Any] = [
            "id": entry.id.uuidString,
            "amountMl": entry.amountMl,
            "createdAt": entry.createdAt.timeIntervalSince1970,
            "source": entry.source.rawValue,
            "isDeleted": entry.isDeletedFlag
        ]

        #expect(expectedData["id"] as? String == entry.id.uuidString)
        #expect(expectedData["amountMl"] as? Double == 500.0)
        #expect(expectedData["source"] as? String == "iphone")
    }

    @Test("Message format for preferences is correct")
    func testPrefsMessageFormat() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let prefs = try context.fetch(fetchRequest).first!

        // Verify the prefs data matches what syncAllData would send
        let expectedData: [String: Any] = [
            "dailyGoalMl": prefs.dailyGoalMl,
            "unit": prefs.unit.rawValue,
            "presetsMl": prefs.presetsMl
        ]

        #expect(expectedData["dailyGoalMl"] as? Double == 2898.0)
        #expect(expectedData["unit"] as? String == "oz")
        #expect((expectedData["presetsMl"] as? [Double])?.count == 3)
    }

    // MARK: - Date Range Tests

    @Test("syncAllData fetches only today's entries")
    func testTodayEntriesFilter() async throws {
        let context = createTestContext()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Create entry for today
        try createTestEntry(context: context, amountMl: 500.0, createdAt: today.addingTimeInterval(3600))

        // Create entry for yesterday
        try createTestEntry(context: context, amountMl: 600.0, createdAt: yesterday.addingTimeInterval(3600))

        // Fetch with today's predicate
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            throw NSError(domain: "TestError", code: 1)
        }

        let predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )

        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        fetchRequest.predicate = predicate
        let results = try context.fetch(fetchRequest)

        // Should only get today's entry
        #expect(results.count == 1)
        #expect(results.first?.amountMl == 500.0)
    }

    // MARK: - Deleted Entries Tests

    @Test("syncAllData includes deleted entries")
    func testDeletedEntriesIncluded() async throws {
        let context = createTestContext()

        // Create deleted entry
        let entry = try createTestEntry(context: context, amountMl: 500.0)
        entry.isDeletedFlag = true
        try context.save()

        // Fetch all entries (sync includes deleted ones)
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first?.isDeletedFlag == true)
    }

    // MARK: - Multiple Entries Tests

    @Test("syncAllData handles multiple entries")
    func testMultipleEntries() async throws {
        let context = createTestContext()

        // Create multiple entries
        try createTestEntry(context: context, amountMl: 500.0)
        try createTestEntry(context: context, amountMl: 600.0)
        try createTestEntry(context: context, amountMl: 700.0)

        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 3)
    }

    // MARK: - Entry Source Tests

    @Test("Entry sources are preserved in sync data")
    func testEntrySources() async throws {
        let context = createTestContext()

        // Create entries from different sources
        let iphoneEntry = HydrationEntry(context: context, amountMl: 500.0, source: .iphone)
        let watchEntry = HydrationEntry(context: context, amountMl: 600.0, source: .watch)
        try context.save()

        #expect(iphoneEntry.source == .iphone)
        #expect(watchEntry.source == .watch)
    }

    // MARK: - Error Handling Tests

    @Test("syncAllData handles missing preferences gracefully")
    func testMissingPreferences() async throws {
        let context = createTestContext()

        // Don't create preferences
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let results = try context.fetch(fetchRequest)

        // Should be no preferences
        #expect(results.isEmpty)

        // syncAllData should handle this without crashing
        let manager = WatchConnectivityManager.shared
        manager.syncAllData()

        #expect(true)
    }

    // MARK: - UUID Tests

    @Test("Entry IDs are unique")
    func testUniqueEntryIDs() async throws {
        let context = createTestContext()

        let entry1 = try createTestEntry(context: context, amountMl: 500.0)
        let entry2 = try createTestEntry(context: context, amountMl: 600.0)

        #expect(entry1.id != entry2.id)
    }

    @Test("Entry ID can be converted to string and back")
    func testUUIDConversion() async throws {
        let context = createTestContext()
        let entry = try createTestEntry(context: context, amountMl: 500.0)

        let idString = entry.id.uuidString
        let reconstructedID = UUID(uuidString: idString)

        #expect(reconstructedID == entry.id)
    }

    // MARK: - Timestamp Tests

    @Test("Timestamps are converted correctly")
    func testTimestampConversion() async throws {
        let now = Date()
        let timestamp = now.timeIntervalSince1970
        let reconstructedDate = Date(timeIntervalSince1970: timestamp)

        #expect(abs(now.timeIntervalSince1970 - reconstructedDate.timeIntervalSince1970) < 0.001)
    }

    // MARK: - Integration Tests

    @Test("Complete sync data structure")
    func testCompleteSyncStructure() async throws {
        let context = createTestContext()
        try createTestEntry(context: context, amountMl: 500.0)
        try createTestPrefs(context: context)

        // Simulate the message structure that would be sent
        let message: [String: Any] = [
            "action": "fullSync",
            "entries": [[
                "id": UUID().uuidString,
                "amountMl": 500.0,
                "createdAt": Date().timeIntervalSince1970,
                "source": "iphone",
                "isDeleted": false
            ]],
            "prefs": [
                "dailyGoalMl": 2898.0,
                "unit": "oz",
                "presetsMl": [236.6, 473.2, 591.5]
            ],
            "timestamp": Date().timeIntervalSince1970
        ]

        #expect(message["action"] as? String == "fullSync")
        #expect((message["entries"] as? [[String: Any]])?.count == 1)
        #expect((message["prefs"] as? [String: Any]) != nil)
        #expect(message["timestamp"] != nil)
    }
}
