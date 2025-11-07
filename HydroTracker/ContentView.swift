//
//  ContentView.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/3/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @State private var showingSettings = false
    @State private var showingCustomAmount = false

    var body: some View {
        NavigationStack {
            HomeView()
                .navigationTitle("Today")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 25)
                        }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    SettingsView()
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}

