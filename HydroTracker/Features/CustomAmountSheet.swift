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
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    let viewModel: HomeViewModel
    let viewContext: NSManagedObjectContext

    @State private var amount: Double = 8.0
    @State private var selectedUnit: UnitPreference = .oz

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
                        Text(String(format: "%.1f", amount))
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .monospacedDigit()

                        Text(selectedUnit == .oz ? "oz" : "ml")
                            .font(.title)
                            .foregroundStyle(.secondary)
                    }
                }

                // Unit Picker
                Picker("Unit", selection: $selectedUnit) {
                    Text("oz").tag(UnitPreference.oz)
                    Text("ml").tag(UnitPreference.ml)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                // Increment/Decrement Buttons
                HStack(spacing: 20) {
                    Button {
                        decreaseAmount()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                    }
                    .disabled(amount <= 0.5)

                    Spacer()

                    Button {
                        increaseAmount()
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
        .onAppear {
            selectedUnit = viewModel.units
        }
    }

    private func increaseAmount() {
        if selectedUnit == .oz {
            amount += 0.5
        } else {
            amount += 50
        }
    }

    private func decreaseAmount() {
        if selectedUnit == .oz {
            amount = max(0.5, amount - 0.5)
        } else {
            amount = max(50, amount - 50)
        }
    }

    private func addWater() {
        let amountInMl: Double
        if selectedUnit == .oz {
            amountInMl = viewModel.ozToMl(amount)
        } else {
            amountInMl = amount
        }

        _ = HydrationEntry(
            context: viewContext,
            amountMl: amountInMl,
            createdAt: Date(),
            source: .iphone
        )

        do {
            try viewContext.save()
            connectivityManager.syncData() // Notify Watch of change
            dismiss()
        } catch {
            print("Failed to save custom amount: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CustomAmountSheet(
        viewModel: HomeViewModel(context: PersistenceController.shared.container.viewContext),
        viewContext: PersistenceController.shared.container.viewContext
    )
}
