//
//  HydroTrackerApp.swift
//  HydroTracker Watch App
//
//  Created by Chris Shireman on 11/7/25.
//

#if os(watchOS)
import SwiftUI
import CoreData

@main
struct HydroTracker_Watch_App: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(connectivityManager)
        }
    }
}
#endif
