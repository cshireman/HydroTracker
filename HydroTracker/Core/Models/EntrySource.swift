//
//  EntrySource.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import Foundation

enum EntrySource: String, Codable, CaseIterable {
    case iphone
    case watch
    case healthkit
}
