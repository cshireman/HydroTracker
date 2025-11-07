//
//  SettingsView.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/7/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager

    @State private var userPrefs: UserPrefs?
    @State private var dailyGoalOz: Double = 98.0
    @State private var selectedUnit: UnitPreference = .oz
    @State private var preset1: Double = 2.0
    @State private var preset2: Double = 16.0
    @State private var preset3: Double = 20.0
    @State private var healthWriteEnabled: Bool = false

    // Number formatter for one decimal place
    private var oneDecimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }

    var body: some View {
        NavigationStack {
            Form {
                // Units Section
                Section("Units") {
                    Picker("Preferred Unit", selection: $selectedUnit) {
                        Text("Ounces (oz)").tag(UnitPreference.oz)
                        Text("Milliliters (ml)").tag(UnitPreference.ml)
                    }
                }

                // Daily Goal Section
                Section {
                    HStack {
                        Text("Daily Goal")
                        Spacer()
                        TextField("Goal", value: $dailyGoalOz, formatter: oneDecimalFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("oz")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Daily Goal")
                } footer: {
                    Text("Your target daily water intake")
                }

                // Presets Section
                Section {
                    PresetRow(title: "Preset 1", value: $preset1, unit: selectedUnit)
                    PresetRow(title: "Preset 2", value: $preset2, unit: selectedUnit)
                    PresetRow(title: "Preset 3", value: $preset3, unit: selectedUnit)
                } header: {
                    Text("Quick Add Presets")
                } footer: {
                    Text("Configure your quick-add buttons")
                }

                // Health Integration Section
                Section {
                    Toggle("Write to Health App", isOn: $healthWriteEnabled)
                } header: {
                    Text("Health Integration")
                } footer: {
                    Text("Sync water intake to Apple Health")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSettings()
                    }
                }
            }
            .onAppear {
                loadSettings()
            }
        }
    }

    private func loadSettings() {
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

    private func saveSettings() {
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
            connectivityManager.syncData() // Notify Watch of change
            dismiss()
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

// MARK: - PresetRow Subview
private struct PresetRow: View {
    let title: String
    @Binding var value: Double
    let unit: UnitPreference

    // Number formatter for one decimal place
    private var oneDecimalFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField("Amount", value: $value, formatter: oneDecimalFormatter)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
            Text(unit == .oz ? "oz" : "ml")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
