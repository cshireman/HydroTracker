//
//  CustomAmountSheet.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/7/25.
//

import SwiftUI
import CoreData

struct CustomAmountSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager

    @State private var viewModel: CustomAmountViewModel

    init(baseViewModel: HomeViewModel, viewContext: NSManagedObjectContext) {
        _viewModel = State(initialValue: CustomAmountViewModel(context: viewContext, baseViewModel: baseViewModel))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Amount Display
                VStack(spacing: 8) {
                    Text("Amount")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        Text(String(format: "%.1f", viewModel.amount))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        Text(viewModel.selectedUnit == .oz ? "oz" : "ml")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }

                // Unit Picker
                Picker("Unit", selection: $viewModel.selectedUnit) {
                    Text("oz").tag(UnitPreference.oz)
                    Text("ml").tag(UnitPreference.ml)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                // Increment/Decrement Buttons
                HStack(spacing: 20) {
                    Button {
                        viewModel.decreaseAmount()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                    }
                    .disabled(viewModel.amount <= 0.5)

                    Spacer()

                    Button {
                        viewModel.increaseAmount()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal, 60)

                Spacer()

                // Add Button
                Button {
                    addWater()
                } label: {
                    Text("Add Water")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .padding()
            .navigationTitle("Add Custom Amount")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func addWater() {
        do {
            try viewModel.addWater(syncManager: connectivityManager)
            dismiss()
        } catch {
            print("Failed to save custom amount: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CustomAmountSheet(
        baseViewModel: HomeViewModel(context: PersistenceController.shared.container.viewContext),
        viewContext: PersistenceController.shared.container.viewContext
    )
    .environmentObject(WatchConnectivityManager.shared)
}
