# Data Sync Troubleshooting Guide

## Current Build Issues

The build is failing because the Watch app target needs to be properly configured in Xcode. Here's how to fix it:

### Fix 1: Remove Watch App Files from iPhone Target

1. Open `HydroTracker.xcodeproj` in Xcode
2. For EACH Watch app file, check its target membership:
   - Select the file in Project Navigator
   - Open File Inspector (right panel, first tab)
   - Under "Target Membership", **UNCHECK** "HydroTracker" (iPhone target)
   - Keep **ONLY** "HydroTracker Watch App" checked

Watch app files to check:
- `HydroTracker Watch App/HydroTrackerApp.swift`
- `HydroTracker Watch App/WatchMainView.swift`
- `HydroTracker Watch App/WatchPresetSelectionView.swift`
- `HydroTracker Watch App/WatchCustomAmountView.swift`
- `HydroTracker Watch App/WatchViewModel.swift`

### Fix 2: Configure App Groups Properly

This is CRITICAL for sync to work!

#### For iPhone App (HydroTracker target):
1. Select "HydroTracker" target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" → "App Groups"
4. Click "+" under App Groups
5. Enter: `group.com.christophershireman.HydroTracker`
6. Ensure the checkbox next to it is CHECKED

#### For Watch App (HydroTracker Watch App target):
1. Select "HydroTracker Watch App" target
2. Go to "Signing & Capabilities" tab
3. Click "+ Capability" → "App Groups"
4. Click "+" under App Groups
5. Enter: `group.com.christophershireman.HydroTracker` (EXACT same identifier)
6. Ensure the checkbox next to it is CHECKED

### Fix 3: Verify Shared Files are in BOTH Targets

These Core Data files MUST be in BOTH targets for sync to work:

1. Select `HydroTracker.xcdatamodeld`
2. In File Inspector, check BOTH:
   - ☑ HydroTracker
   - ☑ HydroTracker Watch App

3. Repeat for these files:
   - `Core/Models/HydrationEntry.swift`
   - `Core/Models/UserPrefs.swift`
   - `Core/Models/EntrySource.swift`
   - `Core/Models/UnitPreference.swift`
   - `Utilities/PersistenceController.swift`

## Verifying Sync is Working

### Step 1: Check Console Logs

When you run the app, check the Xcode console for these messages:

**Expected (Good):**
```
✅ Using shared App Group container: /path/to/group.com.christophershireman.HydroTracker/HydroTracker.sqlite
📦 Persistent store loaded: /path/to/...
```

**Problem (Bad):**
```
⚠️ App Group not available, using local storage: /path/to/Documents/HydroTracker.sqlite
⚠️ Make sure 'group.com.christophershireman.HydroTracker' is added to App Groups capability in Xcode
```

If you see the warning, your App Groups are NOT configured correctly.

### Step 2: Verify Same Database Path

1. Run the iPhone app - note the database path in console
2. Run the Watch app - note the database path in console
3. **They MUST be the EXACT same path** for sync to work

### Step 3: Test Data Sync

1. **Clean Start:**
   - Delete both apps from simulators
   - Reset simulator content if needed: Device → Erase All Content and Settings
   - Rebuild and reinstall

2. **Test iPhone → Watch:**
   - Open iPhone app
   - Add 8 oz of water
   - **Immediately** check Watch app - it should show 8 oz

3. **Test Watch → iPhone:**
   - Open Watch app
   - Add 16 oz of water
   - **Immediately** check iPhone app - it should show 24 oz total

## Why Sync May Not Work

### Issue 1: Different Databases
**Problem:** Each app is using its own database
**Cause:** App Groups not configured or different identifiers
**Solution:** Follow "Fix 2: Configure App Groups Properly" above

### Issue 2: Not Seeing Updates
**Problem:** Changes don't appear without restarting app
**Cause:** Core Data not observing remote changes
**Solution:**
- Verify `NSPersistentHistoryTrackingKey` is enabled (it is)
- Verify `NSPersistentStoreRemoteChangeNotificationPostOptionKey` is enabled (it is)
- Verify `automaticallyMergesChangesFromParent` is true (it is)

### Issue 3: Old Data Persisting
**Problem:** Old test data from before App Group was configured
**Solution:**
- Delete both apps completely
- Or reset simulator
- Reinstall fresh

## Updated Default Values

The app now has these defaults:
- **Daily Goal:** 98 oz (was 80 oz)
- **Presets:** 2 oz, 16 oz, 20 oz (was 8, 12, 16 oz)
- **Settings fields:** Limited to 1 decimal place

## Testing Checklist

- [ ] iPhone app builds and runs
- [ ] Watch app builds and runs
- [ ] Console shows "Using shared App Group container" for BOTH apps
- [ ] Both apps show same database path in console
- [ ] Adding water on iPhone appears on Watch immediately
- [ ] Adding water on Watch appears on iPhone immediately
- [ ] Changing settings on iPhone updates Watch presets
- [ ] Progress ring updates on both devices
- [ ] Default values are 98 oz goal, 2/16/20 oz presets

## Need More Help?

Check the following:
1. Both apps using same bundle identifier prefix
2. App Group capability properly provisioned in your Apple Developer account
3. Signing configured correctly for both targets
4. Simulators are paired (for Watch)
