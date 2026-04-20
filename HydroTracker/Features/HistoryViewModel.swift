//
//  HistoryViewModel.swift
//  HydroTracker
//
//  Created by Chris Shireman on 3/9/26.
//

import Foundation
import CoreData

@Observable
class HistoryViewModel {
    var dailyTotals: [DailyTotal] = []
    var goalOunces: Double = 80.0

    private let viewContext: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        loadPreferences()
    }

    // MARK: - Preferences

    func loadPreferences() {
        let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
        do {
            if let prefs = try viewContext.fetch(fetchRequest).first {
                self.goalOunces = prefs.dailyGoalMl / 29.5735
            }
        } catch {
            print("Failed to load preferences: \(error.localizedDescription)")
        }
    }

    // MARK: - Data Loading

    func loadData(for range: HistoryRange) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let startDate: Date
        let numberOfDays: Int

        switch range {
        case .week:
            // Start from the most recent Sunday (or Monday depending on locale)
            let weekday = calendar.component(.weekday, from: today)
            let daysFromStart = weekday - calendar.firstWeekday
            let adjustedDays = daysFromStart >= 0 ? daysFromStart : daysFromStart + 7
            startDate = calendar.date(byAdding: .day, value: -adjustedDays, to: today)!
            numberOfDays = 7
        case .month:
            startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            numberOfDays = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        }

        guard let endDate = calendar.date(byAdding: .day, value: numberOfDays, to: startDate) else { return }

        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@ AND isDeletedFlag == NO",
            startDate as NSDate,
            endDate as NSDate
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HydrationEntry.createdAt, ascending: true)]

        do {
            let entries = try viewContext.fetch(fetchRequest)

            // Group entries by day
            var grouped: [Date: Double] = [:]
            for entry in entries {
                let day = calendar.startOfDay(for: entry.createdAt)
                grouped[day, default: 0] += entry.amountMl
            }

            // Build array with all days in range (including zero-intake days)
            var totals: [DailyTotal] = []
            for dayOffset in 0..<numberOfDays {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
                let totalMl = grouped[date] ?? 0
                let totalOz = totalMl / 29.5735
                totals.append(DailyTotal(date: date, totalOz: totalOz))
            }

            dailyTotals = totals
        } catch {
            print("Failed to fetch history: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

enum HistoryRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct DailyTotal: Identifiable {
    let id = UUID()
    let date: Date
    let totalOz: Double

    var label: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
}
