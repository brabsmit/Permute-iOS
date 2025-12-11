//
//  AnalysisView.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI
import Charts

struct AnalysisView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var range: Int = 50
    @State private var averageMetric: String = "Ao5"
    @Environment(\.dismiss) var dismiss

    private let ranges = [50, 100]
    private let metrics = ["Ao5", "Ao12"]

    var body: some View {
        NavigationView {
            VStack {
                // Controls
                VStack(spacing: 16) {
                    Picker("Range", selection: $range) {
                        ForEach(ranges, id: \.self) { val in
                            Text("Last \(val)")
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Average", selection: $averageMetric) {
                        ForEach(metrics, id: \.self) { metric in
                            Text(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()

                // Chart
                if chartData.isEmpty {
                    Spacer()
                    Text("Not enough solves")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    Chart {
                        // Trend Line
                        ForEach(Array(chartData.enumerated()), id: \.offset) { index, solve in
                            LineMark(
                                x: .value("Index", index + 1), // 1-based index for display
                                y: .value("Time", solve.time)
                            )
                            .foregroundStyle(Color.blue)
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Index", index + 1),
                                y: .value("Time", solve.time)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(10)
                        }

                        // Average Line
                        if let avg = currentAverage {
                            RuleMark(y: .value("Current \(averageMetric)", avg))
                                .foregroundStyle(Color.green)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("\(averageMetric): \(avg.formattedTime)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                        }
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .padding()
                }

                Spacer()
            }
            .navigationTitle("Solve Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // Data Preparation
    private var chartData: [Solve] {
        let count = min(viewModel.solves.count, range)
        guard count > 0 else { return [] }
        // viewModel.solves is newest first. We want oldest first for the chart.
        let slice = viewModel.solves.prefix(count)
        return Array(slice.reversed())
    }

    private var currentAverage: Double? {
        if averageMetric == "Ao5" {
            return viewModel.getAverage(of: 5)
        } else {
            return viewModel.getAverage(of: 12)
        }
    }
}
