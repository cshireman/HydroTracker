//
//  InjectedValues+Repositories.swift
//  Longevity
//
//  Created by Chris Shireman on 10/31/25.
//

import Foundation
import SwiftData

extension InjectedValues {
    var hydrationEntryRepository: HydrationEntryRepositoryProtocol {
        get { Self[HydrationEntryRepositoryKey.self] }
        set { Self[HydrationEntryRepositoryKey.self] = newValue }
    }
//    
//    var goalRepository: GoalRepositoryProtocol {
//        get { Self[GoalRepositoryKey.self] }
//        set { Self[GoalRepositoryKey.self] = newValue }
//    }
//    
//    var workoutRepository: WorkoutRepositoryProtocol {
//        get { Self[WorkoutRepositoryKey.self] }
//        set { Self[WorkoutRepositoryKey.self] = newValue }
//    }
//    
//    var exerciseRepository: ExerciseRepositoryProtocol {
//        get { Self[ExerciseRepositoryKey.self] }
//        set { Self[ExerciseRepositoryKey.self] = newValue }
//    }
//    
//    var workoutSessionRepository: WorkoutSessionRepositoryProtocol {
//        get { Self[WorkoutSessionRepositoryKey.self] }
//        set { Self[WorkoutSessionRepositoryKey.self] = newValue }
//    }
//    
//    var exerciseRecordRepository: ExerciseRecordRepositoryProtocol {
//        get { Self[ExerciseRecordRepositoryKey.self] }
//        set { Self[ExerciseRecordRepositoryKey.self] = newValue }
//    }
//    
//    var dailyTaskRepository: DailyTaskRepositoryProtocol {
//        get { Self[DailyTaskRepositoryKey.self] }
//        set { Self[DailyTaskRepositoryKey.self] = newValue }
//    }
//    
//    var scheduledWorkoutRepository: ScheduledWorkoutRepositoryProtocol {
//        get { Self[ScheduledWorkoutRepositoryKey.self] }
//        set { Self[ScheduledWorkoutRepositoryKey.self] = newValue }
//    }
//    
//    var progressMetricsRepository: ProgressMetricsRepositoryProtocol {
//        get { Self[ProgressMetricsRepositoryKey.self] }
//        set { Self[ProgressMetricsRepositoryKey.self] = newValue }
//    }
}
