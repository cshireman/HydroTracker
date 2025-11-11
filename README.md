# HydroTracker

A native iOS and watchOS hydration tracking application built with SwiftUI and CoreData, designed to help users monitor their daily water intake across iPhone and Apple Watch.

## Features

### Core Functionality
- **Daily Water Tracking**: Log water intake with customizable preset amounts
- **Custom Amounts**: Add custom water intake amounts in ounces or milliliters
- **Progress Visualization**: Ring-based progress indicator showing daily hydration goal completion
- **Cross-Device Sync**: Automatic synchronization between iPhone and Apple Watch
- **Today's Log**: View all hydration entries for the current day with timestamps
- **Soft Deletion**: Entries are marked as deleted rather than removed, preserving sync integrity

### Settings & Customization
- **Daily Goal Configuration**: Set personalized daily hydration goals
- **Unit Preferences**: Switch between ounces (oz) and milliliters (ml)
- **Quick-Add Presets**: Configure up to 3 quick-add buttons with custom amounts
- **Health Integration**: Optional write access to Apple Health (planned feature)

### Device-Specific Features

#### iPhone App
- Full-featured interface with detailed entry logs
- Settings management
- Custom amount entry with increment/decrement controls
- Delete entries with swipe or tap

#### Apple Watch App
- Optimized watchOS interface with Digital Crown support
- Quick-add presets for fast logging
- Custom amount entry using Digital Crown rotation
- Progress ring with goal display

## Architecture

### Technology Stack
- **SwiftUI**: Modern declarative UI framework for both iOS and watchOS
- **CoreData**: Persistent storage with shared App Group container
- **WatchConnectivity**: Real-time sync between iPhone and Apple Watch
- **Observation Framework**: Modern state management using `@Observable`

### Design Patterns
- **MVVM (Model-View-ViewModel)**: Clean separation of concerns
- **Repository Pattern**: Centralized data access through PersistenceController
- **Dependency Injection**: ViewModels receive context via initialization
- **Soft Delete**: Entries marked as deleted for sync consistency

### Data Sync Strategy
The app uses a hybrid sync approach:
- **CoreData Persistent History Tracking**: Primary sync mechanism on physical devices
- **WatchConnectivity Framework**: Fallback for simulators and immediate updates
- **App Group Container**: Shared storage between iPhone and Watch apps

## Project Structure

```
HydroTracker/
├── HydroTracker/                    # iPhone App
│   ├── Core/
│   │   └── Models/                  # CoreData entities
│   │       ├── HydrationEntry.swift
│   │       ├── UserPrefs.swift
│   │       ├── EntrySource.swift
│   │       └── UnitPreference.swift
│   ├── Features/                    # Feature modules
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   ├── CustomAmountSheet.swift
│   │   ├── CustomAmountViewModel.swift
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   ├── Utilities/
│   │   ├── PersistenceController.swift
│   │   └── WatchConnectivityManager.swift
│   ├── HydroTracker.xcdatamodeld/   # CoreData model
│   └── HydroTrackerApp.swift
│
├── HydroTracker Watch App/          # watchOS App
│   ├── WatchMainView.swift
│   ├── WatchViewModel.swift
│   ├── WatchPresetSelectionView.swift
│   ├── WatchCustomAmountView.swift
│   ├── WatchCustomAmountViewModel.swift
│   └── HydroTrackerApp.swift
│
└── HydroTrackerTests/               # Unit Tests
    ├── PersistenceControllerTests.swift
    ├── HomeViewModelTests.swift
    ├── CustomAmountViewModelTests.swift
    ├── SettingsViewModelTests.swift
    └── WatchConnectivityManagerTests.swift
```

## Data Models

### HydrationEntry
```swift
- id: UUID
- createdAt: Date
- amountMl: Double
- source: EntrySource (.iphone, .watch, .healthkit)
- isDeletedFlag: Bool
- lastModifiedAt: Date
- note: String? (optional)
```

### UserPrefs
```swift
- id: UUID
- dailyGoalMl: Double
- unit: UnitPreference (.oz, .ml)
- presetsMl: [Double]
- healthWriteEnabled: Bool
- healthReadEnabled: Bool
```

## Testing

The project includes comprehensive unit tests covering:
- Persistence layer (CoreData operations)
- ViewModels (business logic and state management)
- Data synchronization (WatchConnectivity)
- Conversion functions (oz ↔ ml)
- Data validation and integrity

### Running Tests

#### Command Line
```bash
xcodebuild test \
  -project HydroTracker.xcodeproj \
  -scheme HydroTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

#### Xcode
1. Open `HydroTracker.xcodeproj`
2. Select Product > Test (⌘U)

### Test Coverage
- **PersistenceControllerTests**: 8 tests covering CoreData operations
- **HomeViewModelTests**: 16 tests covering main app logic
- **CustomAmountViewModelTests**: 16 tests covering custom amount features
- **SettingsViewModelTests**: 16 tests covering settings management
- **WatchConnectivityManagerTests**: 15 tests covering sync functionality

**Total: 71 unit tests**

## Requirements

- iOS 17.0+
- watchOS 10.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

### 1. Clone the Repository
```bash
git clone https://github.com/cshireman/HydroTracker.git
cd HydroTracker
```

### 2. Configure App Groups
Ensure the App Group capability is enabled for both targets:
- App Group ID: `group.com.<YOUR_TEAM_NAME>.HydroTracker`

#### iPhone Target
1. Select the HydroTracker target
2. Go to Signing & Capabilities
3. Ensure "App Groups" capability is enabled
4. Verify `group.com.christophershireman.HydroTracker` is checked

#### Watch Target
1. Select the HydroTracker Watch App target
2. Go to Signing & Capabilities
3. Ensure "App Groups" capability is enabled
4. Verify `group.com.<YOUR_TEAM_NAME>.HydroTracker` is checked

### 3. Enable CoreData Model in Test Target
For unit tests to run:
1. Select `HydroTracker.xcdatamodeld` in Xcode
2. In File Inspector, check "HydroTrackerTests" under Target Membership

### 4. Build and Run
```bash
# Build iPhone app
xcodebuild build \
  -project HydroTracker.xcodeproj \
  -scheme HydroTracker \
  -destination 'generic/platform=iOS Simulator'

# Build Watch app
xcodebuild build \
  -project HydroTracker.xcodeproj \
  -scheme "HydroTracker Watch App" \
  -destination 'generic/platform=watchOS Simulator'
```

## Usage

### iPhone App

#### Logging Water Intake
1. Open the app
2. Tap a preset button (e.g., "8 oz", "16 oz", "20 oz")
3. Or tap "+ Custom" to enter a custom amount

#### Viewing Today's Log
- Scroll down on the home screen to see all entries for today
- Each entry shows amount and timestamp
- Swipe or tap trash icon to delete an entry

#### Settings
1. Tap the settings icon (top right)
2. Customize:
   - Daily goal
   - Preferred unit (oz/ml)
   - Three quick-add presets
   - Health app integration

### Apple Watch App

#### Quick Logging
1. Launch the app on your watch
2. Tap "+ Add Water"
3. Select a preset amount

#### Custom Amount
1. Tap "+ Add Water"
2. Tap "Custom"
3. Rotate the Digital Crown to adjust amount
4. Tap "Add"

## Sync Behavior

### On Physical Devices
- Changes sync automatically via shared App Group container
- CoreData's persistent history tracking handles change propagation
- Updates appear within seconds across devices

### In Simulators
- WatchConnectivity framework provides sync capability
- Requires both simulators to be running simultaneously
- Data is transmitted via WCSession messages

## Known Limitations

1. **Simulator Sync**: iOS Simulator and watchOS Simulator use separate App Group containers. Sync works via WatchConnectivity, requiring both simulators to be active.

2. **Historical Data**: The app currently focuses on daily tracking. Historical trend analysis is a planned feature.

3. **Health Integration**: Health app write capability is a planned feature.

## Troubleshooting

### Tests Failing
**Issue**: Tests fail with CoreData model errors

**Solution**: Ensure `HydroTracker.xcdatamodeld` is added to the HydroTrackerTests target:
1. Select the .xcdatamodeld file
2. Check HydroTrackerTests in Target Membership (File Inspector)

### Sync Not Working
**Issue**: Changes don't appear on the other device

**Solution**:
- On real devices: Ensure both devices are logged into the same iCloud account
- On simulators: Ensure both simulators are running and paired
- Check that App Groups are configured correctly

### App Group Errors
**Issue**: "App Group not available" warnings in logs

**Solution**:
1. Verify App Group capability is enabled in both targets
2. Ensure the identifier matches: `group.com.christophershireman.HydroTracker`
3. Clean build folder (Product > Clean Build Folder)

## Future Enhancements

- [ ] Historical trend charts and analytics
- [ ] Weekly/monthly hydration summaries
- [ ] Reminders and notifications
- [ ] Full Apple Health integration
- [ ] Customizable hydration goals based on activity
- [ ] Multiple drink types (water, juice, etc.)
- [ ] Export data to CSV/PDF
- [ ] Widget support for iOS and watchOS
- [ ] Complications for watch faces

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain MVVM architecture
- Write unit tests for new features
- Update documentation as needed

## License

This project is available for personal and educational use.

## Author

Christopher Shireman

## Acknowledgments

- Built with SwiftUI and CoreData
- Inspired by the need for simple, effective hydration tracking
- Thanks to the Swift community for excellent documentation and resources

---

## Version History

### Version 1.0 (Current)
- Initial release
- Basic hydration tracking
- iPhone and Apple Watch apps
- Cross-device sync
- Customizable presets and goals
- Comprehensive unit tests
