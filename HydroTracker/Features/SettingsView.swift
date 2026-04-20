//
//  SettingsView.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/7/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager

    @State private var viewModel: SettingsViewModel
    @State private var hasUnsavedChanges = false

    init(viewContext: NSManagedObjectContext) {
        _viewModel = State(initialValue: SettingsViewModel(context: viewContext))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Units Section
                Section("Units") {
                    Picker("Preferred Unit", selection: $viewModel.selectedUnit) {
                        Text("Ounces (oz)").tag(UnitPreference.oz)
                        Text("Milliliters (ml)").tag(UnitPreference.ml)
                    }
                }

                // Daily Goal Section
                Section {
                    HStack {
                        Text("Daily Goal")
                        Spacer()
                        TextField("Goal", value: $viewModel.dailyGoalOz, formatter: viewModel.oneDecimalFormatter)
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
                    PresetRow(title: "Preset 1", value: $viewModel.preset1, unit: viewModel.selectedUnit)
                    PresetRow(title: "Preset 2", value: $viewModel.preset2, unit: viewModel.selectedUnit)
                    PresetRow(title: "Preset 3", value: $viewModel.preset3, unit: viewModel.selectedUnit)
                } header: {
                    Text("Quick Add Presets")
                } footer: {
                    Text("Configure your quick-add buttons")
                }

                // Save Section
                Section {
                    Button("Save Changes") {
                        viewModel.saveSettings(syncManager: connectivityManager) {
                            hasUnsavedChanges = false
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(!hasUnsavedChanges)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.loadSettings()
            }
            .onChange(of: viewModel.selectedUnit) { _, _ in hasUnsavedChanges = true }
            .onChange(of: viewModel.dailyGoalOz) { _, _ in hasUnsavedChanges = true }
            .onChange(of: viewModel.preset1) { _, _ in hasUnsavedChanges = true }
            .onChange(of: viewModel.preset2) { _, _ in hasUnsavedChanges = true }
            .onChange(of: viewModel.preset3) { _, _ in hasUnsavedChanges = true }
        }
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
    SettingsView(viewContext: PersistenceController.shared.container.viewContext)
        .environmentObject(WatchConnectivityManager.shared)
}
