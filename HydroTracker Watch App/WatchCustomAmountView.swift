//
//  WatchCustomAmountView.swift
//  HydroTracker Watch App
//
//  Created by Chris Shireman on 11/7/25.
//

#if os(watchOS)
import SwiftUI
import CoreData

struct WatchCustomAmountView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    let viewModel: WatchViewModel
    let onAdd: () -> Void

    @State private var amount: Double = 8.0

    var body: some View {
        VStack(spacing: 16) {
            // Amount Display
            VStack(spacing: 4) {
                Text(String(format: "%.1f", amount))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("oz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .focusable()
            .digitalCrownRotation(
                $amount,
                from: 1.0,
                through: 64.0,
                by: 0.5,
                sensitivity: .medium,
                isContinuous: false,
                isHapticFeedbackEnabled: true
            )

            // Add Button
            Button {
                addWater()
            } label: {
                Text("Add")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)

            // Cancel Button
            Button("Cancel") {
                dismiss()
            }
            .font(.footnote)
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func addWater() {
        viewModel.addWater(ounces: amount, context: viewContext, syncManager: connectivityManager)
        onAdd()
    }
}

#Preview {
    WatchCustomAmountView(
        viewModel: WatchViewModel(context: PersistenceController.shared.container.viewContext),
        onAdd: {}
    )
    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
#endif
