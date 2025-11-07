//
//  RepositoryKeys.swift
//  Longevity
//
//  Created by Chris Shireman on 10/31/25.
//

import Foundation
import SwiftData

//// MARK: - HydrationEntry Repository Key
@MainActor
struct HydrationEntryRepositoryKey: InjectionKey {
    static var currentValue: HydrationEntryRepositoryProtocol = HydrationEntryRepository()
}
//
//// MARK: - Goal Repository Key
//@MainActor
//struct GoalRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: GoalRepositoryProtocol = GoalRepository(container: ModelContainerHelper.shared.container)
//}
//
//// MARK: - Workout Repository Key
//@MainActor
//struct WorkoutRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: WorkoutRepositoryProtocol = WorkoutRepository(container: ModelContainerHelper.shared.container)
//}
//
//// MARK: - Exercise Repository Key
//@MainActor
//struct ExerciseRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: ExerciseRepositoryProtocol = ExerciseRepository(container: ModelContainerHelper.shared.container)
//}
//
//// MARK: - Workout Session Repository Key
//@MainActor
//struct WorkoutSessionRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: WorkoutSessionRepositoryProtocol = WorkoutSessionRepository(container: ModelContainerHelper.shared.container)
//}
//
//// MARK: - Exercise Record Repository Key
//@MainActor
//struct ExerciseRecordRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: ExerciseRecordRepositoryProtocol = ExerciseRecordRepository(container: ModelContainerHelper.shared.container)
//}
//
//// MARK: - Daily Task Repository Key
//@MainActor
//struct DailyTaskRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: DailyTaskRepositoryProtocol = DailyTaskRepository(container: ModelContainerHelper.shared.container)
//}
//
//// MARK: - Scheduled Workout Repository Key
//@MainActor
//struct ScheduledWorkoutRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: ScheduledWorkoutRepositoryProtocol = ScheduledWorkoutRepository(container: ModelContainerHelper.shared.container)
//}
//
//// MARK: - Progress Metrics Repository Key
//@MainActor
//struct ProgressMetricsRepositoryKey: @preconcurrency InjectionKey {
//    static var currentValue: ProgressMetricsRepositoryProtocol = ProgressMetricsRepository(container: ModelContainerHelper.shared.container)
//}
