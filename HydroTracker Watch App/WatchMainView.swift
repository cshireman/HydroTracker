//
//  WatchMainView.swift
//  HydroTracker Watch App
//
//  Created by Chris Shireman on 11/7/25.
//

#if os(watchOS)
import SwiftUI
import CoreData

struct WatchMainView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    @State private var viewModel: WatchViewModel?
    @State private var showingAddWater = false
    @State private var currentDay: Date = Calendar.current.startOfDay(for: Date())

    // MARK: - Fetch Request: Today's Entries
    @FetchRequest var todayEntries: FetchedResults<HydrationEntry>

    // MARK: - Fetch Request: User Preferences
    @FetchRequest(
        sortDescriptors: [],
        animation: .default
    ) private var userPrefs: FetchedResults<UserPrefs>

    init() {
        // Initialize with today's date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let predicate: NSPredicate
        if let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) {
            predicate = NSPredicate(
                format: "createdAt >= %@ AND createdAt < %@ AND isDeletedFlag == NO",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
        } else {
            predicate = NSPredicate(format: "isDeletedFlag == NO")
        }

        _todayEntries = FetchRequest<HydrationEntry>(
            sortDescriptors: [NSSortDescriptor(keyPath: \HydrationEntry.createdAt, ascending: false)],
            predicate: predicate
        )
    }

    // MARK: - Computed Properties
    private var progress: Double {
        guard let vm = viewModel else { return 0.0 }
        return vm.calculateProgress(for: Array(todayEntries))
    }

    private var totalOzToday: Double {
        guard let vm = viewModel else { return 0.0 }
        return vm.calculateTotalOz(for: Array(todayEntries))
    }

    private var goalOunces: Double {
        viewModel?.goalOunces ?? 80.0
    }

    var body: some View {
        VStack(spacing: 16) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .foregroundColor(Color.gray.opacity(0.2))
                Circle()
                    .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: progress)

                VStack(spacing: 4) {
                    Text("\(Int(totalOzToday))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("oz")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120, height: 120)
            .padding(.top, 8)

            // Goal
            Text("Goal: \(Int(goalOunces)) oz")
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Add Water Button
            Button {
                showingAddWater = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Water")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .padding(.horizontal)

            Spacer()
        }
        .onAppear {
            if viewModel == nil {
                viewModel = WatchViewModel(context: viewContext)
            }
            checkForDayChange()
            // Sync data on app startup to get latest from iPhone
            connectivityManager.syncData()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkForDayChange()
            }
        }
        .onChange(of: userPrefs.first?.dailyGoalMl) { _, _ in
            viewModel?.loadPreferences()
        }
        .onChange(of: userPrefs.first?.presetsMl) { _, _ in
            viewModel?.loadPreferences()
        }
        .onChange(of: userPrefs.first?.unit) { _, _ in
            viewModel?.loadPreferences()
        }
        .sheet(isPresented: $showingAddWater) {
            if let vm = viewModel {
                WatchPresetSelectionView(viewModel: vm)
            }
        }
    }

    private func checkForDayChange() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if today != currentDay {
            print("🗓️ Day changed! Updating fetch request...")
            currentDay = today
            updateFetchRequest()
        }
    }

    private func updateFetchRequest() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        let predicate: NSPredicate
        if let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) {
            predicate = NSPredicate(
                format: "createdAt >= %@ AND createdAt < %@ AND isDeletedFlag == NO",
                startOfDay as NSDate,
                endOfDay as NSDate
            )
        } else {
            predicate = NSPredicate(format: "isDeletedFlag == NO")
        }

        todayEntries.nsPredicate = predicate
    }
}

#Preview {
    WatchMainView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
#endif
