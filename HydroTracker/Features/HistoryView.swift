//
//  HistoryView.swift
//  HydroTracker
//
//  Created by Chris Shireman on 3/9/26.
//

import SwiftUI
import CoreData
import Charts

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var viewModel: HistoryViewModel?
    @State private var selectedRange: HistoryRange = .week

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.dailyTotals.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: "chart.bar",
                            description: Text("Start logging water to see your history.")
                        )
                    } else {
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
                                summarySection(vm: vm)

                                // Bar chart
                                chartSection(vm: vm)
                            }
                            .padding(.top, 16)
                        }
                    }
                } else {
                    ProgressView()
                        .padding(.top, 40)
                }
            }
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
        .navigationTitle("History")
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

                if selectedRange == .month {
                    let tickDays = Array(stride(from: 1, through: max(totals.count, 1), by: 7))
                    Chart(totals) { total in
                        BarMark(
                            x: .value("Day", total.dayInt),
                            y: .value("Oz", total.totalOz)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 250)
                    .padding(.horizontal)
                    .chartXAxis {
                        AxisMarks(values: tickDays) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                } else {
                    BarChart(
                        data: totals,
                        xValue: \.label,
                        yValue: \.totalOz,
                        title: nil
                    )
                }
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
