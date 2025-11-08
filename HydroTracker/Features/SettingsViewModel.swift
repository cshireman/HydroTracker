//
//  SettingsViewModel.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/8/25.
//

import Foundation
import CoreData

@Observable
class SettingsViewModel {
    var userPrefs: UserPrefs?
    var dailyGoalOz: Double = 98.0
    var selectedUnit: UnitPreference = .oz
    var preset1: Double = 2.0
    var preset2: Double = 16.0
    var preset3: Double = 20.0
    var healthWriteEnabled: Bool = false

    private let viewContext: NSManagedObjectContext

    // Number formatter for one decimal place
    var oneDecimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }

    init(context: NSManagedObjectContext) {
        self.viewContext = context
    }

    func loadSettings() {
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()

        do {
            let prefs = try viewContext.fetch(fetchRequest).first
            if let prefs = prefs {
                self.userPrefs = prefs
                self.selectedUnit = prefs.unit
                self.dailyGoalOz = mlToOz(prefs.dailyGoalMl)
                self.healthWriteEnabled = prefs.healthWriteEnabled

                let presetsOz = prefs.presetsMl.map { mlToOz($0) }
                if presetsOz.count >= 1 { preset1 = presetsOz[0] }
                if presetsOz.count >= 2 { preset2 = presetsOz[1] }
                if presetsOz.count >= 3 { preset3 = presetsOz[2] }
            }
        } catch {
            print("Failed to load settings: \(error.localizedDescription)")
        }
    }

    func saveSettings(syncManager: WatchConnectivityManager, onSuccess: () -> Void) {
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()

        do {
            let prefs = try viewContext.fetch(fetchRequest).first ?? UserPrefs(context: viewContext)

            prefs.unit = selectedUnit
            prefs.dailyGoalMl = ozToMl(dailyGoalOz)
            prefs.presetsMl = [
                ozToMl(preset1),
                ozToMl(preset2),
                ozToMl(preset3)
            ]
            prefs.healthWriteEnabled = healthWriteEnabled

            try viewContext.save()
            syncManager.syncData() // Notify Watch of change
            onSuccess()
        } catch {
            print("Failed to save settings: \(error.localizedDescription)")
        }
    }

    private func ozToMl(_ oz: Double) -> Double {
        return oz * 29.5735
    }

    private func mlToOz(_ ml: Double) -> Double {
        return ml / 29.5735
    }
}
