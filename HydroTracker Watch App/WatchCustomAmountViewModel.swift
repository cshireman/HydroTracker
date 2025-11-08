//
//  WatchCustomAmountViewModel.swift
//  HydroTracker Watch App
//
//  Created by Chris Shireman on 11/8/25.
//

#if os(watchOS)
import Foundation

@Observable
class WatchCustomAmountViewModel {
    var amount: Double = 8.0

    private let baseViewModel: WatchViewModel

    init(baseViewModel: WatchViewModel) {
        self.baseViewModel = baseViewModel
    }

    func addWater(syncManager: WatchConnectivityManager, onSuccess: () -> Void) {
        do {
            try baseViewModel.addWater(ounces: amount, syncManager: syncManager)
            onSuccess()
        } catch {
            print("Failed to add custom amount: \(error.localizedDescription)")
        }
    }
}
#endif
