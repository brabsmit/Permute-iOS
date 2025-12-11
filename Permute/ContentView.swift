//
//  ContentView.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    @State private var showSettings = false
    @State private var showAnalysis = false
    @State private var showManualEntry = false
    
    var body: some View {
        ZStack {
            // Background Color changes based on state
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Top: Scramble
                if viewModel.state != .running {
                    Text(viewModel.currentScramble)
                        .font(.system(size: 24, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Center: The Timer
                Text(timerText)
                    .font(.system(size: 80, weight: .bold, design: .monospaced))
                    .foregroundColor(timerColor)
                    .scaleEffect(viewModel.state == .holding ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.state)
                
                // Averages Display
                if viewModel.state != .running && viewModel.state != .inspection {
                    HStack(spacing: 40) {
                        VStack {
                            Text("Ao5")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(viewModel.ao5)
                                .font(.title2)
                                .monospacedDigit()
                                .foregroundColor(.white)
                        }

                        VStack {
                            Text("Ao12")
                                .font(.caption)
                                .foregroundColor(.gray)
                            Text(viewModel.ao12)
                                .font(.title2)
                                .monospacedDigit()
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 20)
                }

                Spacer()
                
                // Bottom: Stats List (Only show when not running)
                if viewModel.state != .running {
                    List {
                        ForEach(viewModel.solves) { solve in
                            HStack {
                                Text(solve.formattedTime)
                                    .font(.title3)
                                    .bold()
                                Spacer()
                                Text(solve.date, style: .time)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.vertical, 4)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: viewModel.deleteSolve)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .frame(height: 200)
                    .padding(.horizontal)
                }
            }
        }
        // The Invisible Touch Layer
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.0, pressing: { isPressing in
            if isPressing {
                viewModel.userTouchedDown()
            } else {
                viewModel.userTouchedUp()
            }
        }, perform: {})
        .overlay(alignment: .topTrailing) {
            if viewModel.state != .running && viewModel.state != .holding && viewModel.state != .readyToInspect {
                HStack(spacing: 0) {
                    Button(action: {
                        showManualEntry = true
                    }) {
                        Image(systemName: "keyboard")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }

                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(viewModel: viewModel, isPresented: $showManualEntry)
        }
    }
    
    // UI Helpers
    private var timerColor: Color {
        switch viewModel.state {
        case .idle: return .white
        case .readyToInspect: return .yellow
        case .inspection: return .white // Countdown is white
        case .holding: return .green // Ready to go!
        case .running: return .gray
        }
    }
    
    private var timerText: String {
        switch viewModel.state {
        case .inspection:
            return "\(viewModel.inspectionTime)"
        case .readyToInspect:
            return "INSPECT"
        default:
            return formatTime(viewModel.timeElapsed)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        time.formattedTime
    }
}

#Preview {
    ContentView()
}
