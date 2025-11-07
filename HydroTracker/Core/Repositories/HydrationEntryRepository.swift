//
//  HydrationEntryRepository.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import Foundation
import CoreData

protocol HydrationEntryRepositoryProtocol {
    @MainActor func fetchHydrationEntriesForToday() async throws -> [HydrationEntry]
}

final class HydrationEntryRepository: HydrationEntryRepositoryProtocol {
    @Injected(\.persistenceController) private var persistenceController: PersistenceController

    @MainActor func fetchHydrationEntriesForToday() async throws -> [HydrationEntry] {
        let context = persistenceController.container.viewContext

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            // fallback to empty predicate if date calculation fails
            return []
        }

        let request: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        return try context.fetch(request)
    }
}

