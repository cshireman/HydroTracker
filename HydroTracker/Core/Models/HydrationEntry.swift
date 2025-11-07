//
//  HydrationEntry.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import Foundation
import CoreData

@objcMembers
@objc(HydrationEntry)
final class HydrationEntry: NSManagedObject, Identifiable {
    @NSManaged var id: UUID
    @NSManaged var createdAt: Date
    @NSManaged var amountMl: Double
    @NSManaged private var sourceRaw: String
    @NSManaged var isDeletedFlag: Bool
    @NSManaged var lastModifiedAt: Date
    @NSManaged var note: String?
    
    var source: EntrySource {
        get {
            EntrySource(rawValue: sourceRaw) ?? .iphone
        }
        set {
            sourceRaw = newValue.rawValue
        }
    }
    
    convenience init(
        context: NSManagedObjectContext,
        id: UUID = UUID(),
        amountMl: Double,
        createdAt: Date = Date(),
        source: EntrySource = .iphone,
        note: String? = nil,
        isDeleted: Bool = false,
        lastModifiedAt: Date = Date()
    ) {
        self.init(entity: HydrationEntry.entity(), insertInto: context)
        self.id = id
        self.amountMl = amountMl
        self.createdAt = createdAt
        self.source = source
        self.note = note
        self.isDeletedFlag = isDeleted
        self.lastModifiedAt = lastModifiedAt
    }
}

extension HydrationEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HydrationEntry> {
        NSFetchRequest<HydrationEntry>(entityName: "HydrationEntry")
    }
}
