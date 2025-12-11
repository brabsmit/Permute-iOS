//
//  CompetitionView.swift
//  Permute
//
//  Created for WCA Integration.
//

import SwiftUI
import CoreLocation

struct CompetitionView: View {
    @StateObject private var viewModel = CompetitionViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Finding competitions near you...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error")
                            .font(.headline)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                        Button("Retry") {
                            viewModel.requestLocation()
                        }
                        .padding()
                    }
                    .padding()
                } else if viewModel.competitions.isEmpty {
                    VStack(spacing: 20) {
                        if viewModel.userLocation == nil {
                            if #available(iOS 17, *) {
                                ContentUnavailableView(
                                    "Location Needed",
                                    systemImage: "location.slash",
                                    description: Text("Please enable location services to find competitions near you.")
                                )
                            } else {
                                VStack {
                                    Image(systemName: "location.slash")
                                        .font(.largeTitle)
                                    Text("Location Needed")
                                        .font(.title)
                                    Text("Please enable location services to find competitions near you.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Button("Enable Location") {
                                viewModel.requestLocation()
                            }
                        } else {
                            if #available(iOS 17, *) {
                                ContentUnavailableView(
                                    "No Competitions Found",
                                    systemImage: "globe.americas.fill",
                                    description: Text("We couldn't find any upcoming competitions in your country.")
                                )
                            } else {
                                VStack {
                                    Image(systemName: "globe.americas.fill")
                                        .font(.largeTitle)
                                    Text("No Competitions Found")
                                        .font(.title)
                                    Text("We couldn't find any upcoming competitions in your country.")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Button("Refresh") {
                                Task {
                                    await viewModel.fetchCompetitionsBasedOnLocation()
                                }
                            }
                        }
                    }
                } else {
                    List(viewModel.competitions) { comp in
                        CompetitionRow(competition: comp, viewModel: viewModel)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Competitions")
            .onAppear {
                viewModel.requestLocation()
            }
        }
    }
}

struct CompetitionRow: View {
    let competition: Competition
    @ObservedObject var viewModel: CompetitionViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(competition.name)
                .font(.headline)
                .foregroundColor(.primary)

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(formatDate(competition.start_date))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "location.fill")
                    .foregroundColor(.secondary)
                Text(viewModel.distanceTo(competition))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }

            HStack {
                Text(competition.city)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }

    func formatDate(_ dateString: String) -> String {
        if let date = CompetitionRow.inputFormatter.date(from: dateString) {
            return CompetitionRow.outputFormatter.string(from: date)
        }
        return dateString
    }

    private static let inputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let outputFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

#Preview {
    CompetitionView()
}
