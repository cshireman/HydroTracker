//
//  HomeViewModelTests.swift
//  HydroTrackerTests
//
//  Created by Chris Shireman on 11/10/25.
//

import Testing
import CoreData
@testable import HydroTracker

struct HomeViewModelTests {

    // MARK: - Helper Methods

    func createTestContext() -> NSManagedObjectContext {
        let controller = PersistenceController(inMemory: true)
        return controller.container.viewContext
    }

    func createTestPrefs(context: NSManagedObjectContext) throws {
        let prefs = UserPrefs(
            context: context,
            dailyGoalMl: 2898.0, // 98 oz
            unit: .oz,
            presetsMl: [236.6, 473.2, 591.5] // 8, 16, 20 oz
        )
        try context.save()
    }

    // MARK: - Initialization Tests

    @Test("HomeViewModel initializes with default values")
    func testInitialization() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)

        #expect(viewModel.goalOunces == 80.0)
        #expect(viewModel.progress == 0.0)
        #expect(viewModel.units == .oz)
    }

    @Test("HomeViewModel loads preferences from CoreData")
    func testLoadPreferences() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let viewModel = await HomeViewModel(context: context)
        await viewModel.loadPreferences()

        #expect(viewModel.units == .oz)
        #expect(Int(viewModel.goalOunces) == 98) // 2898ml = ~98oz
        #expect(viewModel.presets.count == 3)
    }

    // MARK: - Conversion Tests

    @Test("ozToMl conversion is accurate")
    func testOzToMlConversion() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)

        let result = await viewModel.ozToMl(1.0)
        #expect(abs(result - 29.5735) < 0.01)
    }

    @Test("mlToOz conversion is accurate")
    func testMlToOzConversion() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)

        let result = await viewModel.mlToOz(29.5735)
        #expect(abs(result - 1.0) < 0.01)
    }

    @Test("Conversion round trip maintains value")
    func testConversionRoundTrip() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)

        let originalOz = 16.0
        let ml = await viewModel.ozToMl(originalOz)
        let backToOz = await viewModel.mlToOz(ml)

        #expect(abs(backToOz - originalOz) < 0.01)
    }

    // MARK: - Progress Calculation Tests

    @Test("calculateProgress returns zero for no entries")
    func testCalculateProgressEmpty() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let viewModel = await HomeViewModel(context: context)
        await viewModel.loadPreferences()

        let progress = await viewModel.calculateProgress(for: [])
        #expect(progress == 0.0)
    }

    @Test("calculateProgress computes correct progress")
    func testCalculateProgressWithEntries() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let viewModel = await HomeViewModel(context: context)
        await viewModel.loadPreferences()

        // Create entries totaling 49oz (half of 98oz goal)
        let entries = [
            HydrationEntry(context: context, amountMl: await viewModel.ozToMl(25.0), source: .iphone),
            HydrationEntry(context: context, amountMl: await viewModel.ozToMl(24.0), source: .iphone)
        ]

        let progress = await viewModel.calculateProgress(for: entries)
        #expect(abs(progress - 0.5) < 0.01)
    }

    @Test("calculateProgress caps at 100 percent")
    func testCalculateProgressCaps() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let viewModel = await HomeViewModel(context: context)
        await viewModel.loadPreferences()

        // Create entries exceeding goal
        let entries = [
            HydrationEntry(context: context, amountMl: await viewModel.ozToMl(150.0), source: .iphone)
        ]

        let progress = await viewModel.calculateProgress(for: entries)
        #expect(progress == 1.0)
    }

    // MARK: - Total Calculation Tests

    @Test("calculateTotalOz returns zero for no entries")
    func testCalculateTotalEmpty() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)

        let total = await viewModel.calculateTotalOz(for: [])
        #expect(total == 0.0)
    }

    @Test("calculateTotalOz sums entries correctly")
    func testCalculateTotalWithEntries() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)

        let entries = await [
            HydrationEntry(context: context, amountMl: viewModel.ozToMl(8.0), source: .iphone),
            HydrationEntry(context: context, amountMl: viewModel.ozToMl(16.0), source: .iphone),
            HydrationEntry(context: context, amountMl: viewModel.ozToMl(12.0), source: .iphone)
        ]

        let total = await viewModel.calculateTotalOz(for: entries)
        #expect(abs(total - 36.0) < 0.1)
    }

    // MARK: - Add Entry Tests

    @Test("addAmount creates entry in CoreData")
    func testAddAmount() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)
        let mockConnectivity = await WatchConnectivityManager.shared

        try await viewModel.addAmount(ounces: 16.0, syncManager: mockConnectivity)

        // Verify entry was created
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(abs(results.first!.amountMl - viewModel.ozToMl(16.0)) < 0.1)
        #expect(results.first?.source == .iphone)
    }

    @Test("addAmount sets correct source")
    func testAddAmountSource() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)
        let mockConnectivity = await WatchConnectivityManager.shared

        try await viewModel.addAmount(ounces: 8.0, syncManager: mockConnectivity)

        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.first?.source == .iphone)
    }

    // MARK: - Delete Entry Tests

    @Test("deleteEntry marks entry as deleted")
    func testDeleteEntry() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)
        let mockConnectivity = await WatchConnectivityManager.shared

        // Create entry
        let entry = HydrationEntry(
            context: context,
            amountMl: 500.0,
            source: .iphone
        )
        try context.save()

        // Delete entry
        try await viewModel.deleteEntry(entry, syncManager: mockConnectivity)

        // Verify entry is marked deleted
        #expect(entry.isDeletedFlag == true)
    }

    @Test("deleteEntry does not remove entry from database")
    func testDeleteEntrySoftDelete() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)
        let mockConnectivity = await WatchConnectivityManager.shared

        // Create entry
        let entry = HydrationEntry(
            context: context,
            amountMl: 500.0,
            source: .iphone
        )
        try context.save()

        // Delete entry
        try await viewModel.deleteEntry(entry, syncManager: mockConnectivity)

        // Verify entry still exists in database
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first?.isDeletedFlag == true)
    }

    // MARK: - Integration Tests

    @Test("Multiple operations maintain data integrity")
    func testMultipleOperations() async throws {
        let context = createTestContext()
        let viewModel = await HomeViewModel(context: context)
        let mockConnectivity = await WatchConnectivityManager.shared

        // Add multiple entries
        try await viewModel.addAmount(ounces: 8.0, syncManager: mockConnectivity)
        try await viewModel.addAmount(ounces: 16.0, syncManager: mockConnectivity)
        try await viewModel.addAmount(ounces: 12.0, syncManager: mockConnectivity)

        // Fetch all entries
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isDeletedFlag == NO")
        let entries = try context.fetch(fetchRequest)

        #expect(entries.count == 3)

        // Calculate total
        let total = await viewModel.calculateTotalOz(for: entries)
        #expect(abs(total - 36.0) < 0.1)

        // Delete one entry
        try await viewModel.deleteEntry(entries[0], syncManager: mockConnectivity)

        // Fetch non-deleted entries
        let activeEntries = try context.fetch(fetchRequest)
        #expect(activeEntries.count == 2)
    }
}
