//
//  ContentView.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        TabView {
            Tab("Today", systemImage: "drop.fill") {
                NavigationStack {
                    HomeView()
                        .navigationTitle("Today")
                }
            }

            Tab("History", systemImage: "chart.bar.fill") {
                HistoryView()
            }

            Tab("Settings", systemImage: "gear") {
                SettingsView(viewContext: viewContext)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

