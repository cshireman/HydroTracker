import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var connectivityManager: WatchConnectivityManager
    @State private var viewModel: HomeViewModel?
    @State private var showingCustomAmountSheet = false
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

    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Ring with percentage text
                ZStack {
                    ProgressRing(progress: progress, thickness: 16)
                        .frame(width: 160, height: 160)
                        .accessibilityLabel(Text("Hydration progress"))
                        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityHidden(true)
                }

                // Intake line: "51 oz → 80 oz"
                HStack(spacing: 4) {
                    Text("\(Int(totalOzToday)) oz")
                    Image(systemName: "arrow.right")
                        .font(.body.weight(.medium))
                    Text("\(Int(goalOunces)) oz")
                }
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.medium)
                .accessibilityElement()
                .accessibilityLabel(Text("Current intake and goal"))
                .accessibilityValue(Text("\(Int(totalOzToday)) ounces out of \(Int(goalOunces)) ounces"))

                // Quick-add buttons
                HStack(spacing: 16) {
                    if let presets = viewModel?.presets {
                        ForEach(presets.prefix(3), id: \.self) { preset in
                            QuickAddButton(amountOz: Int(preset), action: addAmount(ounces:))
                        }
                    }
                }

                // Add Custom Amount Button
                Button {
                    showingCustomAmountSheet = true
                } label: {
                    Text("+ Custom")
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.2)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Add a custom amount of water"))

                // Today Log
                if !todayEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Log")
                            .font(.headline)
                            .padding(.top, 8)

                        ForEach(todayEntries) { entry in
                            EntryRow(entry: entry, viewModel: viewModel, onDelete: { deleteEntry(entry) })
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 20)
            }
            .padding(24)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = HomeViewModel(context: viewContext)
            }
            checkForDayChange()
            // Sync data on app startup to get latest from Watch
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
        .sheet(isPresented: $showingCustomAmountSheet) {
            if let vm = viewModel {
                CustomAmountSheet(baseViewModel: vm, viewContext: viewContext)
            }
        }
    }

    // MARK: - Actions
    private func addAmount(ounces: Double) {
        guard let vm = viewModel else { return }
        withAnimation {
            do {
                try vm.addAmount(ounces: ounces, syncManager: connectivityManager)
            } catch {
                print("Failed to save hydration entry: \(error.localizedDescription)")
            }
        }
    }

    private func deleteEntry(_ entry: HydrationEntry) {
        guard let vm = viewModel else { return }
        withAnimation {
            do {
                try vm.deleteEntry(entry, syncManager: connectivityManager)
            } catch {
                print("Failed to delete entry: \(error.localizedDescription)")
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

// MARK: - QuickAddButton Subview
private struct QuickAddButton: View {
    let amountOz: Int
    let action: (Double) -> Void

    var body: some View {
        Button {
            action(Double(amountOz))
        } label: {
            Text("\(amountOz) oz")
                .fontWeight(.medium)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(minWidth: 80, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Add \(amountOz) ounces of water"))
    }
}

// MARK: - EntryRow Subview
private struct EntryRow: View {
    let entry: HydrationEntry
    let viewModel: HomeViewModel?
    let onDelete: () -> Void

    private var amountText: String {
        guard let vm = viewModel else { return "\(Int(entry.amountMl)) ml" }
        let oz = vm.mlToOz(entry.amountMl)
        return String(format: "%.0f oz", oz)
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: entry.createdAt)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(amountText)
                    .font(.body.weight(.medium))
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - ProgressRing Subview
private struct ProgressRing: View {
    let progress: Double
    let thickness: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: thickness)
                .foregroundColor(Color.gray.opacity(0.2))
            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    Color.blue,
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
