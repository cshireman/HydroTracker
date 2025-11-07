# Watch App Setup Instructions

I've created all the necessary Swift files for the Watch app. To complete the setup, you'll need to add the Watch app target in Xcode. Here's how:

## Step 1: Add Watch App Target

1. Open `HydroTracker.xcodeproj` in Xcode
2. In the project navigator, select the HydroTracker project (blue icon at top)
3. Click the "+" button at the bottom of the targets list
4. Choose "watchOS" → "Watch App" (NOT "Watch App for iOS App")
5. Set the following:
   - Product Name: `HydroTracker Watch App`
   - Bundle Identifier: `com.christophershireman.HydroTracker.watchkitapp`
   - Organization Identifier: `com.christophershireman`
   - Interface: SwiftUI
   - Language: Swift
6. Click "Finish"
7. When prompted "Activate 'HydroTracker Watch App' scheme?", click "Activate"

## Step 2: Add Files to Watch Target

1. In the project navigator, find the "HydroTracker Watch App" folder
2. Delete any auto-generated files (ContentView.swift, etc.)
3. Add the files I created:
   - Right-click "HydroTracker Watch App" folder → "Add Files to HydroTracker..."
   - Navigate to the "HydroTracker Watch App" folder
   - Select all .swift files (WatchMainView.swift, WatchPresetSelectionView.swift, etc.)
   - Make sure "Copy items if needed" is UNCHECKED
   - Make sure target membership includes "HydroTracker Watch App"
   - Click "Add"

## Step 3: Share Core Data Models and Utilities

The Watch app needs access to the Core Data models and utilities. Add these to the Watch target:

1. Select `HydroTracker.xcdatamodeld` in the project navigator
2. In the File Inspector (right panel), check the box for "HydroTracker Watch App" target
3. Repeat for:
   - `HydroTracker/Core/Models/HydrationEntry.swift`
   - `HydroTracker/Core/Models/UserPrefs.swift`
   - `HydroTracker/Core/Models/EntrySource.swift`
   - `HydroTracker/Core/Models/UnitPreference.swift`
   - `HydroTracker/Utilities/PersistenceController.swift`
   - All files in `HydroTracker/Core/DI/` (if needed)

## Step 4: Configure App Groups

### For iPhone App:
1. Select the HydroTracker target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" and add "App Groups"
4. Click "+" under App Groups and add: `group.com.christophershireman.HydroTracker`
5. Make sure it's checked

### For Watch App:
1. Select the HydroTracker Watch App target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" and add "App Groups"
4. Click "+" under App Groups and add: `group.com.christophershireman.HydroTracker`
5. Make sure it's checked

## Step 5: Build and Run

1. Select the "HydroTracker Watch App" scheme
2. Choose a Watch simulator (e.g., "Apple Watch Series 9 (45mm)")
3. Click Run (⌘R)

## Step 6: Test iPhone ↔ Watch Sync

1. Run the iPhone app in one simulator
2. Run the Watch app in a Watch simulator
3. Add water on the iPhone → should appear on Watch within seconds
4. Add water on Watch → should appear on iPhone within seconds

## How the Sync Works

- Both apps use the same SQLite database stored in the App Group container
- Core Data's `NSPersistentHistoryTracking` and `NSPersistentStoreRemoteChangeNotificationPost` ensure changes are detected
- `automaticallyMergesChangesFromParent` keeps the UI in sync
- Changes should propagate within 1-2 seconds

## Troubleshooting

If data doesn't sync:
1. Check that both apps have the EXACT same App Group identifier
2. Verify both targets have App Groups capability enabled
3. Check Console.app for any Core Data errors
4. Make sure both apps are running in their respective simulators
5. Try force-quitting and restarting both apps

## Watch App Features

### Main Screen
- Displays progress ring with current water intake
- Shows goal
- "Add Water" button to add water

### Preset Selection Screen
- Three quick-add preset buttons (matches iPhone settings)
- "Custom" button to enter custom amount

### Custom Amount Screen
- Use Digital Crown to adjust amount (1-64 oz in 0.5 oz increments)
- "Add" button to log the amount
- "Cancel" to go back

All data is shared in real-time between iPhone and Watch!
