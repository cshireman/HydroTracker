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
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    let onAdd: () -> Void

    @State private var viewModel: WatchCustomAmountViewModel

    init(baseViewModel: WatchViewModel, onAdd: @escaping () -> Void) {
        self.onAdd = onAdd
        _viewModel = State(initialValue: WatchCustomAmountViewModel(baseViewModel: baseViewModel))
    }

    var body: some View {
        VStack(spacing: 16) {
            // Amount Display
            VStack(spacing: 4) {
                Text(String(format: "%.1f", viewModel.amount))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("oz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .focusable()
            .digitalCrownRotation(
                $viewModel.amount,
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
        viewModel.addWater(syncManager: connectivityManager) {
            onAdd()
        }
    }
}

#Preview {
    WatchCustomAmountView(
        baseViewModel: WatchViewModel(context: PersistenceController.shared.container.viewContext),
        onAdd: {}
    )
    .environmentObject(WatchConnectivityManager.shared)
}
#endif
