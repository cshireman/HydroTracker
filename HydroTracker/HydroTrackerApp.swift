//
//  HydroTrackerApp.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import SwiftUI
import CoreData

@main
struct HydroTrackerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(connectivityManager)
        }
    }
}
