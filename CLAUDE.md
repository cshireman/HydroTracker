# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Simulator

Always use `'generic/platform=iOS Simulator'` as the destination (not a named device) when running `xcodebuild` commands. Named simulators (e.g., `name=iPhone 16`) may not be installed; the generic destination picks the latest available model automatically.

## Commands

**Build:**
```bash
# iPhone app
xcodebuild build -project HydroTracker.xcodeproj -scheme HydroTracker -destination 'generic/platform=iOS Simulator'

# Watch app
xcodebuild build -project HydroTracker.xcodeproj -scheme "HydroTracker Watch App" -destination 'generic/platform=watchOS Simulator'
```

**Test:**
```bash
# Run all tests
xcodebuild test -project HydroTracker.xcodeproj -scheme HydroTracker -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test class (replace TestClassName)
xcodebuild test -project HydroTracker.xcodeproj -scheme HydroTracker -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HydroTrackerTests/TestClassName
```

**Note:** If tests fail with CoreData model errors, ensure `HydroTracker.xcdatamodeld` has `HydroTrackerTests` checked under Target Membership in Xcode's File Inspector.

## Architecture

### MVVM with `@Observable`

ViewModels use the Swift `@Observable` macro (not `ObservableObject`/`@Published`). Each ViewModel receives an `NSManagedObjectContext` at init — no singleton context access within VMs.

```swift
@Observable
class HomeViewModel {
    init(context: NSManagedObjectContext) { ... }
}
```

Views instantiate their ViewModel lazily via `@State private var viewModel: HomeViewModel?` and create it in `.onAppear`.

### Data Layer

**All hydration amounts are stored internally in milliliters.** Ounces are only used for display. Conversion: `1 oz = 29.5735 ml`.

`PersistenceController` (singleton via `.shared`) wraps `NSPersistentContainer`. The SQLite store lives in the App Group container (`group.com.christophershireman.HydroTracker`) so both iPhone and Watch targets share it on physical devices.

**Soft delete:** Entries are never removed from CoreData. Instead, `isDeletedFlag = true` is set and `lastModifiedAt` updated. Fetch requests always filter with `isDeletedFlag == NO`.

### Cross-Device Sync

Two sync mechanisms work together:

1. **CoreData Persistent History Tracking** (primary, physical devices): Enabled via `NSPersistentHistoryTrackingKey`. The shared App Group SQLite file propagates changes automatically.

2. **WatchConnectivity** (`WatchConnectivityManager`, fallback/simulators): Sends a `"fullSync"` message with all of today's entries and user prefs. Uses `sendMessage` when reachable, falls back to `updateApplicationContext`.

`WatchConnectivityManager.shared` is injected as an `@EnvironmentObject` from the app root and passed explicitly to ViewModel methods that need to trigger sync (e.g., `addAmount(ounces:syncManager:)`).

### iPhone vs. Watch Target

Watch-specific code is gated with `#if os(watchOS)`. The Watch app (`HydroTracker Watch App/`) has its own ViewModels (`WatchViewModel`, `WatchCustomAmountViewModel`) that mirror the iPhone VMs but with `.watch` as the entry source. Shared models (`HydrationEntry`, `UserPrefs`, etc.) live in `HydroTracker/Core/Models/` and are compiled into both targets.

### Testing

Tests use **Swift Testing** framework (`import Testing`, `@Test`, `#expect`), not XCTest. Each test creates an isolated in-memory CoreData stack:

```swift
func createTestContext() -> NSManagedObjectContext {
    PersistenceController(inMemory: true).container.viewContext
}
```

The in-memory store uses `/dev/null` as its URL, so tests are fully isolated.

### Components

`HydroTracker/Components/Charts/BarChart.swift` is a generic, reusable SwiftUI Charts wrapper (`@available(iOS 16.0, *)`). It's used in `HistoryView` to display weekly/monthly totals via `HistoryViewModel`, which groups `HydrationEntry` records by day into `DailyTotal` structs.
