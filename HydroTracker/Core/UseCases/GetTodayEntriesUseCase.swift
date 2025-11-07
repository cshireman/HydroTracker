//
//  GetTodayEntriesUseCase.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

actor GetTodayEntriesUseCase {
    @Injected(\.hydrationEntryRepository) private var repository: HydrationEntryRepositoryProtocol

    func execute() async throws -> [HydrationEntry] {
        return try await repository.fetchHydrationEntriesForToday()
    }
}
