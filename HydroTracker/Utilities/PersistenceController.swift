//
//  PersistenceController.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import Foundation
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // App Group identifier for sharing data between iPhone and Watch
    static let appGroupIdentifier = "group.com.christophershireman.HydroTracker"

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "HydroTracker")

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        } else {
            // Use App Group container for shared storage between iPhone and Watch
            let storeURL: URL
            if let sharedStoreURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) {
                storeURL = sharedStoreURL.appendingPathComponent("HydroTracker.sqlite")
                print("✅ Using shared App Group container: \(storeURL.path)")
            } else {
                // Fallback to default location if App Group is not configured
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                storeURL = documentsURL.appendingPathComponent("HydroTracker.sqlite")
                print("⚠️ App Group not available, using local storage: \(storeURL.path)")
                print("⚠️ Make sure '\(Self.appGroupIdentifier)' is added to App Groups capability in Xcode")
            }

            let description = NSPersistentStoreDescription(url: storeURL)
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            print("📦 Persistent store loaded: \(storeDescription.url?.path ?? "unknown")")
        }

        container.viewContext.name = "viewContext"
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Enable automatic UI updates when persistent store changes
        // This works with NSPersistentStoreRemoteChangeNotificationPostOptionKey
        // and automatically refreshes the context when data changes from another process
    }
}
