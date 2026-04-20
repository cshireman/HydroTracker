//
//  HistoryView.swift
//  HydroTracker
//
//  Created by Chris Shireman on 3/9/26.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var viewModel: HistoryViewModel?
    @State private var selectedRange: HistoryRange = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Range picker
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(HistoryRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    // Summary stats
                    if let vm = viewModel {
                        summarySection(vm: vm)
                    }

                    // Bar chart
                    if let vm = viewModel {
                        chartSection(vm: vm)
                    }
                }
                .padding(.top, 16)
            }
            .navigationTitle("History")
            .onAppear {
                if viewModel == nil {
                    viewModel = HistoryViewModel(context: viewContext)
                }
                viewModel?.loadData(for: selectedRange)
            }
            .onChange(of: selectedRange) { _, newRange in
                viewModel?.loadData(for: newRange)
            }
        }
    }

    // MARK: - Summary Section

    @ViewBuilder
    private func summarySection(vm: HistoryViewModel) -> some View {
        let totals = vm.dailyTotals
        let average = totals.isEmpty ? 0 : totals.map(\.totalOz).reduce(0, +) / Double(totals.count)
        let daysMetGoal = totals.filter { $0.totalOz >= vm.goalOunces }.count

        HStack(spacing: 24) {
            StatCard(title: "Daily Avg", value: "\(Int(average)) oz")
            StatCard(title: "Goal Met", value: "\(daysMetGoal)/\(totals.count)")
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Chart Section

    @ViewBuilder
    private func chartSection(vm: HistoryViewModel) -> some View {
        let totals = vm.dailyTotals

        if totals.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.bar",
                description: Text("Start logging water to see your history.")
            )
            .padding(.top, 40)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedRange == .week ? "This Week" : "This Month")
                    .font(.headline)
                    .padding(.horizontal, 24)

                BarChart(
                    data: totals,
                    xValue: selectedRange == .week ? \.label : \.dayNumber,
                    yValue: \.totalOz,
                    title: nil,
                    labelInterval: selectedRange == .week ? 7 : 7
                )
            }
        }
    }
}

// MARK: - StatCard

private struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Preview

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
