//
//  CustomAmountViewModelTests.swift
//  HydroTrackerTests
//
//  Created by Chris Shireman on 11/10/25.
//

import Testing
import CoreData
@testable import HydroTracker

@MainActor
struct CustomAmountViewModelTests {

    // MARK: - Helper Methods

    func createTestContext() -> NSManagedObjectContext {
        let controller = PersistenceController(inMemory: true)
        return controller.container.viewContext
    }

    func createTestPrefs(context: NSManagedObjectContext, unit: UnitPreference = .oz) throws {
        let prefs = UserPrefs(
            context: context,
            dailyGoalMl: 2898.0,
            unit: unit,
            presetsMl: [236.6, 473.2, 591.5]
        )
        try context.save()
    }

    func createBaseViewModel(context: NSManagedObjectContext) -> HomeViewModel {
        return HomeViewModel(context: context)
    }

    // MARK: - Initialization Tests

    @Test("CustomAmountViewModel initializes with default amount")
    func testInitialization() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        #expect(viewModel.amount == 8.0)
    }

    @Test("CustomAmountViewModel inherits unit from base view model")
    func testUnitInheritance() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context, unit: .oz)

        let baseViewModel = createBaseViewModel(context: context)
        baseViewModel.loadPreferences()

        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        #expect(viewModel.selectedUnit == .oz)
    }

    // MARK: - Amount Adjustment Tests (Ounces)

    @Test("increaseAmount adds 0.5 oz when unit is oz")
    func testIncreaseAmountOz() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        viewModel.selectedUnit = .oz
        viewModel.amount = 8.0

        viewModel.increaseAmount()

        #expect(viewModel.amount == 8.5)
    }

    @Test("decreaseAmount subtracts 0.5 oz when unit is oz")
    func testDecreaseAmountOz() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        viewModel.selectedUnit = .oz
        viewModel.amount = 8.0

        viewModel.decreaseAmount()

        #expect(viewModel.amount == 7.5)
    }

    @Test("decreaseAmount does not go below 0.5 oz")
    func testDecreaseAmountMinimumOz() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        viewModel.selectedUnit = .oz
        viewModel.amount = 0.5

        viewModel.decreaseAmount()

        #expect(viewModel.amount == 0.5)
    }

    @Test("Multiple increases work correctly for oz")
    func testMultipleIncreasesOz() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        viewModel.selectedUnit = .oz
        viewModel.amount = 8.0

        for _ in 1...4 {
            viewModel.increaseAmount()
        }

        #expect(viewModel.amount == 10.0) // 8.0 + (0.5 * 4)
    }

    // MARK: - Amount Adjustment Tests (Milliliters)

    @Test("increaseAmount adds 50 ml when unit is ml")
    func testIncreaseAmountMl() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        viewModel.selectedUnit = .ml
        viewModel.amount = 100.0

        viewModel.increaseAmount()

        #expect(viewModel.amount == 150.0)
    }

    @Test("decreaseAmount subtracts 50 ml when unit is ml")
    func testDecreaseAmountMl() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        viewModel.selectedUnit = .ml
        viewModel.amount = 100.0

        viewModel.decreaseAmount()

        #expect(viewModel.amount == 50.0)
    }

    @Test("decreaseAmount does not go below 50 ml")
    func testDecreaseAmountMinimumMl() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        viewModel.selectedUnit = .ml
        viewModel.amount = 50.0

        viewModel.decreaseAmount()

        #expect(viewModel.amount == 50.0)
    }

    // MARK: - Add Water Tests

    @Test("addWater creates entry with oz amount converted to ml")
    func testAddWaterOz() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)
        let mockConnectivity = WatchConnectivityManager.shared

        viewModel.selectedUnit = .oz
        viewModel.amount = 16.0

        try viewModel.addWater(syncManager: mockConnectivity)

        // Verify entry was created
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)

        // 16 oz = ~473.176 ml
        let expectedMl = 16.0 * 29.5735
        #expect(abs(results.first!.amountMl - expectedMl) < 1.0)
    }

    @Test("addWater creates entry with ml amount")
    func testAddWaterMl() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)
        let mockConnectivity = WatchConnectivityManager.shared

        viewModel.selectedUnit = .ml
        viewModel.amount = 500.0

        try viewModel.addWater(syncManager: mockConnectivity)

        // Verify entry was created
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first!.amountMl == 500.0)
    }

    @Test("addWater sets correct source")
    func testAddWaterSource() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)
        let mockConnectivity = WatchConnectivityManager.shared

        try viewModel.addWater(syncManager: mockConnectivity)

        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.first?.source == .iphone)
    }

    @Test("addWater sets creation date")
    func testAddWaterCreationDate() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)
        let mockConnectivity = WatchConnectivityManager.shared

        let beforeDate = Date()
        try viewModel.addWater(syncManager: mockConnectivity)
        let afterDate = Date()

        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        let createdAt = results.first!.createdAt
        #expect(createdAt >= beforeDate && createdAt <= afterDate)
    }

    // MARK: - Unit Switching Tests

    @Test("Switching units maintains independent values")
    func testUnitSwitching() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)

        // Set amount in oz
        viewModel.selectedUnit = .oz
        viewModel.amount = 16.0

        // Switch to ml
        viewModel.selectedUnit = .ml

        // Amount should remain at 16.0 (UI would handle this)
        #expect(viewModel.amount == 16.0)
    }

    // MARK: - Integration Tests

    @Test("Complete workflow from adjustment to save")
    func testCompleteWorkflow() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)
        let mockConnectivity = WatchConnectivityManager.shared

        // Start with default
        #expect(viewModel.amount == 8.0)

        // Increase amount
        viewModel.increaseAmount()
        viewModel.increaseAmount()

        #expect(viewModel.amount == 9.0)

        // Save
        try viewModel.addWater(syncManager: mockConnectivity)

        // Verify saved
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        let expectedMl = 9.0 * 29.5735
        #expect(abs(results.first!.amountMl - expectedMl) < 1.0)
    }

    @Test("Multiple custom amounts can be added")
    func testMultipleCustomAmounts() async throws {
        let context = createTestContext()
        let baseViewModel = createBaseViewModel(context: context)
        let viewModel = CustomAmountViewModel(context: context, baseViewModel: baseViewModel)
        let mockConnectivity = WatchConnectivityManager.shared

        // Add multiple amounts
        viewModel.amount = 8.0
        try viewModel.addWater(syncManager: mockConnectivity)

        viewModel.amount = 12.0
        try viewModel.addWater(syncManager: mockConnectivity)

        viewModel.amount = 16.0
        try viewModel.addWater(syncManager: mockConnectivity)

        // Verify all entries
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 3)
    }
}
