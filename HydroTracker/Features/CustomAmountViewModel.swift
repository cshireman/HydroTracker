//
//  CustomAmountViewModel.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/7/25.
//

import Foundation
import CoreData

@Observable
class CustomAmountViewModel {
    var amount: Double = 8.0
    var selectedUnit: UnitPreference = .oz

    private let viewContext: NSManagedObjectContext
    private let baseViewModel: HomeViewModel

    init(context: NSManagedObjectContext, baseViewModel: HomeViewModel) {
        self.viewContext = context
        self.baseViewModel = baseViewModel
        self.selectedUnit = baseViewModel.units
    }

    func increaseAmount() {
        if selectedUnit == .oz {
            amount += 0.5
        } else {
            amount += 50
        }
    }

    func decreaseAmount() {
        if selectedUnit == .oz {
            amount = max(0.5, amount - 0.5)
        } else {
            amount = max(50, amount - 50)
        }
    }

    func addWater(syncManager: WatchConnectivityManager) throws {
        let amountInMl: Double
        if selectedUnit == .oz {
            amountInMl = baseViewModel.ozToMl(amount)
        } else {
            amountInMl = amount
        }

        _ = HydrationEntry(
            context: viewContext,
            amountMl: amountInMl,
            createdAt: Date(),
            source: .iphone
        )

        try viewContext.save()
        syncManager.syncData()
    }
}
