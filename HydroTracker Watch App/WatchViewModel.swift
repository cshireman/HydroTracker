//
//  WatchViewModel.swift
//  HydroTracker Watch App
//
//  Created by Chris Shireman on 11/7/25.
//

#if os(watchOS)
import Foundation
import CoreData

@Observable
class WatchViewModel {
    var goalOunces: Double = 80.0
    var units: UnitPreference = .oz
    var presets: [Double] = [8.0, 12.0, 16.0] // in ounces

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadPreferences()
    }

    // MARK: - Preferences Loading
    func loadPreferences() {
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()

        do {
            let prefs = try viewContext.fetch(fetchRequest).first
            if let prefs = prefs {
                self.units = prefs.unit
                self.goalOunces = mlToOz(prefs.dailyGoalMl)
                self.presets = prefs.presetsMl.map { mlToOz($0) }
            } else {
                // Create default preferences if none exist
                let defaultPrefs = UserPrefs(
                    context: viewContext,
                    dailyGoalMl: 2898.0, // 98 oz
                    unit: .oz,
                    presetsMl: [59.1, 473.2, 591.5], // 2, 16, 20 oz
                    healthWriteEnabled: false,
                    healthReadEnabled: false
                )
                try viewContext.save()
                self.units = defaultPrefs.unit
                self.goalOunces = mlToOz(defaultPrefs.dailyGoalMl)
                self.presets = defaultPrefs.presetsMl.map { mlToOz($0) }
            }
        } catch {
            print("Failed to load preferences: \(error.localizedDescription)")
        }
    }

    // MARK: - Calculations
    func calculateProgress(for entries: [HydrationEntry]) -> Double {
        let totalMl = entries.reduce(0.0) { $0 + $1.amountMl }
        let totalOz = mlToOz(totalMl)
        return min(totalOz / goalOunces, 1.0)
    }

    func calculateTotalOz(for entries: [HydrationEntry]) -> Double {
        let totalMl = entries.reduce(0.0) { $0 + $1.amountMl }
        return mlToOz(totalMl)
    }

    // MARK: - Conversion Helpers
    func ozToMl(_ oz: Double) -> Double {
        return oz * 29.5735
    }

    func mlToOz(_ ml: Double) -> Double {
        return ml / 29.5735
    }

    // MARK: - Actions
    func addWater(ounces: Double, context: NSManagedObjectContext, syncManager: WatchConnectivityManager) {
        _ = HydrationEntry(
            context: context,
            amountMl: ozToMl(ounces),
            createdAt: Date(),
            source: .watch
        )

        do {
            try context.save()
            syncManager.syncData() // Notify iPhone of change
        } catch {
            print("Failed to save entry: \(error.localizedDescription)")
        }
    }
}
#endif
