//
//  BarChart.swift
//  ChrisUI
//
//  A bar chart for comparative data visualization
//

import SwiftUI
import Charts

/// A customizable bar chart for comparative data visualization
///
/// This component creates a bar chart using SwiftUI Charts framework,
/// ideal for comparing values across categories.
///
/// Example:
/// ```swift
/// BarChart(
///     data: salesByCategory,
///     xValue: \.category,
///     yValue: \.sales,
///     title: "Sales by Category"
/// )
/// ```
@available(iOS 16.0, *)
public struct BarChart<DataPoint: Identifiable, X: Plottable, Y: Plottable>: View {
    private let data: [DataPoint]
    private let xValue: KeyPath<DataPoint, X>
    private let yValue: KeyPath<DataPoint, Y>
    private let title: String?
    private let barColor: Color
    private let orientation: ChartOrientation
    private let labelInterval: Int?

    /// Creates a bar chart
    /// - Parameters:
    ///   - data: Array of data points
    ///   - xValue: KeyPath to x-axis value
    ///   - yValue: KeyPath to y-axis value
    ///   - title: Optional chart title
    ///   - barColor: Color of the bars
    ///   - orientation: Vertical or horizontal orientation
    ///   - labelInterval: If provided, only show a label every N items to prevent overlap
    public init(
        data: [DataPoint],
        xValue: KeyPath<DataPoint, X>,
        yValue: KeyPath<DataPoint, Y>,
        title: String? = nil,
        barColor: Color = .blue,
        orientation: ChartOrientation = .vertical,
        labelInterval: Int? = nil
    ) {
        self.data = data
        self.xValue = xValue
        self.yValue = yValue
        self.title = title
        self.barColor = barColor
        self.orientation = orientation
        self.labelInterval = labelInterval
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .padding(.horizontal)
            }

            Chart(data.indices, id: \.self) { index in
                let item = data[index]

                BarMark(
                    x: .value("X", item[keyPath: xValue]),
                    y: .value("Y", item[keyPath: yValue])
                )
                .foregroundStyle(barColor.gradient)
                .cornerRadius(6)
            }
            .frame(height: 250)
            .padding(.horizontal)
            .chartXAxis {
                if let interval = labelInterval, interval > 0 {
                    AxisMarks(values: .automatic(desiredCount: interval))
                } else {
                    AxisMarks(values: .automatic)
                }
            }
        }
        .accessibilityLabel(title ?? "Bar chart")
    }

}

/// Chart orientation options
public enum ChartOrientation {
    case vertical
    case horizontal
}

#Preview {
    struct DataPoint: Identifiable {
        let id = UUID()
        let category: String
        let value: Double
    }

    let data = [
        DataPoint(category: "1", value: 45),
        DataPoint(category: "2", value: 62),
        DataPoint(category: "3", value: 58),
        DataPoint(category: "4", value: 71),
        DataPoint(category: "5", value: 68),
        DataPoint(category: "6", value: 68),
        DataPoint(category: "7", value: 68),
        DataPoint(category: "8", value: 68),
        DataPoint(category: "9", value: 68),
        DataPoint(category: "10", value: 68),
        DataPoint(category: "11", value: 68),
        DataPoint(category: "12", value: 68),
        DataPoint(category: "13", value: 68),
        DataPoint(category: "14", value: 68),
        DataPoint(category: "15", value: 68),
        DataPoint(category: "16", value: 68),
        DataPoint(category: "17", value: 68),
        DataPoint(category: "18", value: 68),
        DataPoint(category: "19", value: 68),
        DataPoint(category: "20", value: 68),
        DataPoint(category: "21", value: 68),
        DataPoint(category: "22", value: 68),
        DataPoint(category: "23", value: 68),
        DataPoint(category: "24", value: 68),
        DataPoint(category: "25", value: 68),
        DataPoint(category: "26", value: 68),
        DataPoint(category: "27", value: 68),
        DataPoint(category: "28", value: 68),
        DataPoint(category: "29", value: 68),
        DataPoint(category: "30", value: 68),
        DataPoint(category: "31", value: 68)
    ]

    return ScrollView {
        VStack(spacing: 30) {
            if #available(iOS 16.0, *) {
                BarChart(
                    data: data,
                    xValue: \.category,
                    yValue: \.value,
                    title: "Monthly Sales",
                    labelInterval: 7
                )

//                BarChart(
//                    data: data,
//                    xValue: \.category,
//                    yValue: \.value,
//                    title: "Revenue Growth",
//                    barColor: .green
//                )
//
//                BarChart(
//                    data: data,
//                    xValue: \.category,
//                    yValue: \.value,
//                    title: "User Engagement",
//                    barColor: .purple
//                )
            } else {
                Text("Charts require iOS 16+")
            }
        }
        .padding(.vertical)
    }
}
