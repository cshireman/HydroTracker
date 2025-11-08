//
//  WatchPresetSelectionView.swift
//  HydroTracker Watch App
//
//  Created by Chris Shireman on 11/7/25.
//

#if os(watchOS)
import SwiftUI
import CoreData

struct WatchPresetSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    let viewModel: WatchViewModel

    @State private var showingCustomAmount = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    Text("Add Water")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    // Preset Buttons
                    ForEach(viewModel.presets.prefix(3), id: \.self) { preset in
                        Button {
                            addWater(ounces: preset)
                        } label: {
                            Text("\(Int(preset)) oz")
                                .font(.body.weight(.medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                    
                    // Custom Amount Button
                    Button {
                        showingCustomAmount = true
                    } label: {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Custom")
                        }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(.gray)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingCustomAmount) {
            WatchCustomAmountView(baseViewModel: viewModel, onAdd: {
                dismiss()
            })
        }
    }

    private func addWater(ounces: Double) {
        do {
            try viewModel.addWater(ounces: ounces, syncManager: connectivityManager)
            dismiss()
        } catch {
            print("Failed to add water: \(error.localizedDescription)")
        }
    }
}

#Preview {
    WatchPresetSelectionView(
        viewModel: WatchViewModel(context: PersistenceController.shared.container.viewContext)
    )
    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
#endif
