//
//  UseCase.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

protocol UseCase {
    func execute() async throws -> [Any]
}
