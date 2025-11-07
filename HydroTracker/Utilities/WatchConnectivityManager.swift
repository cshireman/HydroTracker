//
//  WatchConnectivityManager.swift
//  HydroTracker
//
//  Created by Chris Shireman on 11/7/25.
//

import Foundation
import WatchConnectivity
import CoreData
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    private var session: WCSession?
    private let viewContext: NSManagedObjectContext

    override init() {
        self.viewContext = PersistenceController.shared.container.viewContext
        super.init()

        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("📱 WatchConnectivity activated")
        } else {
            print("⚠️ WatchConnectivity not supported on this device")
        }
    }

    // MARK: - Send Data

    func syncAllData() {
        // Fetch all today's entries
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return }

        let predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt < %@ AND isDeletedFlag == NO",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
        fetchRequest.predicate = predicate

        do {
            let entries = try viewContext.fetch(fetchRequest)
            let entriesData = entries.map { entry -> [String: Any] in
                return [
                    "id": entry.id.uuidString,
                    "amountMl": entry.amountMl,
                    "createdAt": entry.createdAt.timeIntervalSince1970,
                    "source": entry.source.rawValue
                ]
            }

            // Also fetch user prefs
            let prefsRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
            let prefs = try viewContext.fetch(prefsRequest).first

            var prefsData: [String: Any] = [:]
            if let prefs = prefs {
                prefsData = [
                    "dailyGoalMl": prefs.dailyGoalMl,
                    "unit": prefs.unit.rawValue,
                    "presetsMl": prefs.presetsMl
                ]
            }

            let message: [String: Any] = [
                "action": "fullSync",
                "entries": entriesData,
                "prefs": prefsData,
                "timestamp": Date().timeIntervalSince1970
            ]

            sendMessage(message)
        } catch {
            print("❌ Failed to fetch data for sync: \(error.localizedDescription)")
        }
    }

    func syncData() {
        syncAllData()
    }

    private func sendMessage(_ message: [String: Any]) {
        guard let session = session else {
            print("⚠️ WatchConnectivity not supported")
            return
        }

        // Try to send immediately if reachable
        if session.isReachable {
            session.sendMessage(message, replyHandler: { response in
                print("✅ Sync message acknowledged: \(response)")
            }) { error in
                print("❌ Failed to send sync message: \(error.localizedDescription)")
                // Fall back to application context
                self.updateContext(message)
            }
        } else {
            // If not reachable, update application context
            updateContext(message)
        }
    }

    private func updateContext(_ message: [String: Any]) {
        guard let session = session else { return }
        do {
            try session.updateApplicationContext(message)
            print("📤 Updated application context for later delivery")
        } catch {
            print("❌ Failed to update application context: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ WCSession activated with state: \(activationState.rawValue)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("📱 WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("📱 WCSession deactivated, reactivating...")
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📩 Received message: \(message)")
        processReceivedData(message)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📩 Received message with reply: \(message)")
        processReceivedData(message)
        replyHandler(["status": "received"])
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📩 Received application context: \(applicationContext)")
        processReceivedData(applicationContext)
    }

    private func processReceivedData(_ message: [String: Any]) {
        guard message["action"] as? String == "fullSync" else { return }

        DispatchQueue.main.async {
            // Process entries
            if let entriesData = message["entries"] as? [[String: Any]] {
                for entryData in entriesData {
                    guard let idString = entryData["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let amountMl = entryData["amountMl"] as? Double,
                          let createdAtTimestamp = entryData["createdAt"] as? TimeInterval,
                          let sourceString = entryData["source"] as? String,
                          let source = EntrySource(rawValue: sourceString) else {
                        continue
                    }

                    let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)

                    // Check if entry already exists
                    let fetchRequest: NSFetchRequest<HydrationEntry> = HydrationEntry.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

                    do {
                        let existing = try self.viewContext.fetch(fetchRequest)
                        if existing.isEmpty {
                            // Create new entry
                            _ = HydrationEntry(
                                context: self.viewContext,
                                id: id,
                                amountMl: amountMl,
                                createdAt: createdAt,
                                source: source
                            )
                            print("✅ Imported entry: \(amountMl)ml at \(createdAt)")
                        }
                    } catch {
                        print("❌ Failed to check for existing entry: \(error.localizedDescription)")
                    }
                }
            }

            // Process prefs
            if let prefsData = message["prefs"] as? [String: Any],
               let dailyGoalMl = prefsData["dailyGoalMl"] as? Double,
               let unitString = prefsData["unit"] as? String,
               let unit = UnitPreference(rawValue: unitString),
               let presetsMl = prefsData["presetsMl"] as? [Double] {

                let fetchRequest: NSFetchRequest<UserPrefs> = UserPrefs.fetchRequest()
                do {
                    let prefs = try self.viewContext.fetch(fetchRequest).first ?? UserPrefs(context: self.viewContext)
                    prefs.dailyGoalMl = dailyGoalMl
                    prefs.unit = unit
                    prefs.presetsMl = presetsMl
                    print("✅ Updated preferences from sync")
                } catch {
                    print("❌ Failed to update preferences: \(error.localizedDescription)")
                }
            }

            // Save all changes
            do {
                try self.viewContext.save()
                print("🔄 Sync completed successfully")
            } catch {
                print("❌ Failed to save synced data: \(error.localizedDescription)")
            }
        }
    }
}

