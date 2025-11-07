//
//  UserPrefs.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import Foundation
import CoreData

@objcMembers
@objc(UserPrefs)
final class UserPrefs: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var dailyGoalMl: Double
    @NSManaged private var unitRaw: String
    @NSManaged var presetsMl: [Double]
    @NSManaged var healthWriteEnabled: Bool
    @NSManaged var healthReadEnabled: Bool
    
    var unit: UnitPreference {
        get {
            UnitPreference(rawValue: unitRaw) ?? .ml
        }
        set {
            unitRaw = newValue.rawValue
        }
    }
    
    convenience init(
        context: NSManagedObjectContext,
        id: UUID = UUID(),
        dailyGoalMl: Double = 2000,
        unit: UnitPreference = .ml,
        presetsMl: [Double] = [118, 237, 355],
        healthWriteEnabled: Bool = false,
        healthReadEnabled: Bool = false
    ) {
        self.init(entity: UserPrefs.entity(), insertInto: context)
        self.id = id
        self.dailyGoalMl = dailyGoalMl
        self.unit = unit
        self.presetsMl = presetsMl
        self.healthWriteEnabled = healthWriteEnabled
        self.healthReadEnabled = healthReadEnabled
    }
}

extension UserPrefs {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPrefs> {
        NSFetchRequest<UserPrefs>(entityName: "UserPrefs")
    }
}
