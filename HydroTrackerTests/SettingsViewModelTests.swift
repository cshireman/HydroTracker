//
//  SettingsViewModelTests.swift
//  HydroTrackerTests
//
//  Created by Chris Shireman on 11/10/25.
//

import Testing
import CoreData
@testable import HydroTracker

@MainActor
struct SettingsViewModelTests {

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
            presetsMl: [59.1, 473.2, 591.5], // 2, 16, 20 oz
            healthWriteEnabled: true
        )
        try context.save()
    }

    // MARK: - Initialization Tests

    @Test("SettingsViewModel initializes with default values")
    func testInitialization() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)

        #expect(viewModel.dailyGoalOz == 98.0)
        #expect(viewModel.selectedUnit == .oz)
        #expect(viewModel.preset1 == 2.0)
        #expect(viewModel.preset2 == 16.0)
        #expect(viewModel.preset3 == 20.0)
    }

    // MARK: - Load Settings Tests

    @Test("loadSettings retrieves existing preferences")
    func testLoadSettings() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let viewModel = SettingsViewModel(context: context)
        viewModel.loadSettings()

        #expect(Int(viewModel.dailyGoalOz) == 98)
        #expect(viewModel.selectedUnit == .oz)
        #expect(viewModel.healthWriteEnabled == true)
    }

    @Test("loadSettings converts presets from ml to oz")
    func testLoadSettingsPresetsConversion() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let viewModel = SettingsViewModel(context: context)
        viewModel.loadSettings()

        // Check preset conversions (allowing for rounding)
        #expect(abs(viewModel.preset1 - 2.0) < 0.1)
        #expect(abs(viewModel.preset2 - 16.0) < 0.1)
        #expect(abs(viewModel.preset3 - 20.0) < 0.1)
    }

    @Test("loadSettings handles missing preferences")
    func testLoadSettingsNoPrefs() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)

        // Should not crash when no prefs exist
        viewModel.loadSettings()

        // Should maintain default values
        #expect(viewModel.dailyGoalOz > 0)
    }

    // MARK: - Save Settings Tests

    @Test("saveSettings creates new preferences if none exist")
    func testSaveSettingsCreatesNew() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)
        let mockConnectivity = WatchConnectivityManager.shared

        viewModel.dailyGoalOz = 100.0
        viewModel.selectedUnit = .oz
        viewModel.preset1 = 8.0
        viewModel.preset2 = 16.0
        viewModel.preset3 = 24.0

        var callbackCalled = false
        viewModel.saveSettings(syncManager: mockConnectivity) {
            callbackCalled = true
        }

        #expect(callbackCalled == true)

        // Verify prefs were saved
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(abs(results.first!.dailyGoalMl - (100.0 * 29.5735)) < 10.0)
    }

    @Test("saveSettings updates existing preferences")
    func testSaveSettingsUpdatesExisting() async throws {
        let context = createTestContext()
        try createTestPrefs(context: context)

        let viewModel = SettingsViewModel(context: context)
        viewModel.loadSettings()

        // Modify settings
        viewModel.dailyGoalOz = 120.0
        viewModel.selectedUnit = .ml
        viewModel.healthWriteEnabled = false

        let mockConnectivity = WatchConnectivityManager.shared
        var callbackCalled = false
        viewModel.saveSettings(syncManager: mockConnectivity) {
            callbackCalled = true
        }

        #expect(callbackCalled == true)

        // Verify updates
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first!.unit == .ml)
        #expect(results.first!.healthWriteEnabled == false)
    }

    @Test("saveSettings converts oz to ml correctly")
    func testSaveSettingsConversion() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)
        let mockConnectivity = WatchConnectivityManager.shared

        viewModel.dailyGoalOz = 100.0
        viewModel.preset1 = 8.0
        viewModel.preset2 = 16.0
        viewModel.preset3 = 24.0

        viewModel.saveSettings(syncManager: mockConnectivity) { }

        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let results = try context.fetch(fetchRequest)

        let prefs = results.first!

        // Verify ml conversions
        let expectedGoalMl = 100.0 * 29.5735
        #expect(abs(prefs.dailyGoalMl - expectedGoalMl) < 1.0)

        let expectedPreset1 = 8.0 * 29.5735
        #expect(abs(prefs.presetsMl[0] - expectedPreset1) < 1.0)
    }

    @Test("saveSettings persists all three presets")
    func testSaveSettingsAllPresets() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)
        let mockConnectivity = WatchConnectivityManager.shared

        viewModel.preset1 = 10.0
        viewModel.preset2 = 20.0
        viewModel.preset3 = 30.0

        viewModel.saveSettings(syncManager: mockConnectivity) { }

        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(results.first!.presetsMl.count == 3)
    }

    // MARK: - Conversion Tests

    @Test("ozToMl conversion is accurate")
    func testOzToMlConversion() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)

        // Access private method through saveSettings
        viewModel.dailyGoalOz = 1.0
        let mockConnectivity = WatchConnectivityManager.shared
        viewModel.saveSettings(syncManager: mockConnectivity) { }

        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        let results = try context.fetch(fetchRequest)

        #expect(abs(results.first!.dailyGoalMl - 29.5735) < 0.01)
    }

    @Test("mlToOz conversion is accurate")
    func testMlToOzConversion() async throws {
        let context = createTestContext()

        // Create prefs with known ml value
        let prefs = UserPrefs(
            context: context,
            dailyGoalMl: 29.5735,
            unit: .oz
        )
        try context.save()

        let viewModel = SettingsViewModel(context: context)
        viewModel.loadSettings()

        // Should convert to 1 oz
        #expect(abs(viewModel.dailyGoalOz - 1.0) < 0.01)
    }

    // MARK: - Number Formatter Tests

    @Test("Number formatter has correct decimal places")
    func testNumberFormatter() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)

        let formatter = viewModel.oneDecimalFormatter

        #expect(formatter.minimumFractionDigits == 0)
        #expect(formatter.maximumFractionDigits == 1)
    }

    // MARK: - Unit Preference Tests

    @Test("Unit preference persists across save and load")
    func testUnitPreferencePersistence() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)
        let mockConnectivity = WatchConnectivityManager.shared

        // Save with oz
        viewModel.selectedUnit = .oz
        viewModel.saveSettings(syncManager: mockConnectivity) { }

        // Create new view model and load
        let newViewModel = SettingsViewModel(context: context)
        newViewModel.loadSettings()

        #expect(newViewModel.selectedUnit == .oz)
    }

    @Test("Switching units maintains separate preferences")
    func testUnitSwitching() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)
        let mockConnectivity = WatchConnectivityManager.shared

        // Set oz preferences
        viewModel.selectedUnit = .oz
        viewModel.dailyGoalOz = 100.0
        viewModel.saveSettings(syncManager: mockConnectivity) { }

        // Switch to ml
        viewModel.selectedUnit = .ml

        // Unit should change but values remain
        #expect(viewModel.selectedUnit == .ml)
        #expect(viewModel.dailyGoalOz == 100.0) // Value doesn't auto-convert
    }

    // MARK: - Health Integration Tests

    @Test("Health write enabled flag persists")
    func testHealthWriteEnabledPersistence() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)
        let mockConnectivity = WatchConnectivityManager.shared

        viewModel.healthWriteEnabled = true
        viewModel.saveSettings(syncManager: mockConnectivity) { }

        let newViewModel = SettingsViewModel(context: context)
        newViewModel.loadSettings()

        #expect(newViewModel.healthWriteEnabled == true)
    }

    // MARK: - Integration Tests

    @Test("Complete settings workflow")
    func testCompleteWorkflow() async throws {
        let context = createTestContext()
        let mockConnectivity = WatchConnectivityManager.shared

        // Initial save
        let viewModel1 = SettingsViewModel(context: context)
        viewModel1.dailyGoalOz = 100.0
        viewModel1.selectedUnit = .oz
        viewModel1.preset1 = 8.0
        viewModel1.preset2 = 16.0
        viewModel1.preset3 = 24.0
        viewModel1.healthWriteEnabled = true
        viewModel1.saveSettings(syncManager: mockConnectivity) { }

        // Load in new view model
        let viewModel2 = SettingsViewModel(context: context)
        viewModel2.loadSettings()

        #expect(Int(viewModel2.dailyGoalOz) == 100)
        #expect(viewModel2.selectedUnit == .oz)
        #expect(Int(viewModel2.preset1) == 8)
        #expect(viewModel2.healthWriteEnabled == true)

        // Modify and save again
        viewModel2.dailyGoalOz = 120.0
        viewModel2.saveSettings(syncManager: mockConnectivity) { }

        // Verify final state
        let viewModel3 = SettingsViewModel(context: context)
        viewModel3.loadSettings()

        #expect(Int(viewModel3.dailyGoalOz) == 120)
    }

    @Test("Multiple preset changes maintain order")
    func testPresetOrder() async throws {
        let context = createTestContext()
        let viewModel = SettingsViewModel(context: context)
        let mockConnectivity = WatchConnectivityManager.shared

        viewModel.preset1 = 5.0
        viewModel.preset2 = 10.0
        viewModel.preset3 = 15.0
        viewModel.saveSettings(syncManager: mockConnectivity) { }

        let newViewModel = SettingsViewModel(context: context)
        newViewModel.loadSettings()

        #expect(Int(newViewModel.preset1) == 5)
        #expect(Int(newViewModel.preset2) == 10)
        #expect(Int(newViewModel.preset3) == 15)
    }
}
