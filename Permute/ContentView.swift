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
    @State private var showUndo = false
    @State private var shareImage: Image?
    @State private var showAnalysis = false
    @State private var showManualEntry = false
    
    var body: some View {
        ZStack {
            // Background Color changes based on state
            Color.black.edgesIgnoringSafeArea(.all)
            
            // Gesture Layer for Two-Finger Tap (Underneath main content but above background)
            // Active during idle and waiting (to capture tap during wait phase)
            if viewModel.state == .idle || viewModel.state == .waiting {
                TwoFingerTapView {
                    viewModel.togglePlusTwo()
                }
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(true) // Ensure it captures touches
            }

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
                    // Swipe Right on Timer to Delete
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if viewModel.state == .idle && value.translation.width > 50 {
                                    viewModel.deleteLastSolve()
                                    showUndo = true
                                    // Hide undo after 3 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        showUndo = false
                                    }
                                }
                            }
                    )
                
                // Share PB Button
                if viewModel.state != .running && viewModel.lastSolveWasPB, let shareImage = shareImage {
                    ShareLink(
                        item: shareImage,
                        preview: SharePreview("New PB", image: shareImage)
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share PB")
                        }
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(20)
                    }
                    .padding(.top, 10)
                }

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
        // The Invisible Touch Layer for Timer
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.0, pressing: { isPressing in
            // Only trigger if not performing gestures
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
        .overlay(alignment: .bottom) {
            // Undo Button
            if showUndo && viewModel.lastDeletedSolve != nil {
                Button(action: {
                    viewModel.undoDelete()
                    showUndo = false
                }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo Delete")
                    }
                    .padding()
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(20)
                }
                .padding(.bottom, 50)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: showUndo)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .onChange(of: viewModel.lastSolveWasPB) { isPB in
            if isPB, let lastSolve = viewModel.solves.first {
                self.shareImage = generateShareImage(for: lastSolve)
            } else {
                self.shareImage = nil
            }
        }
        .sheet(isPresented: $showManualEntry) {
            ManualEntryView(viewModel: viewModel, isPresented: $showManualEntry)
        }
    }
    
    // UI Helpers
    private var timerColor: Color {
        switch viewModel.state {
        case .idle, .waiting: return .white
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
        case .idle, .waiting:
            // Display the last solve's formatted time (with penalties) if available
            if let lastSolve = viewModel.solves.first, viewModel.timeElapsed == lastSolve.time {
                return lastSolve.formattedTime
            }
            return formatTime(viewModel.timeElapsed)
        case .running:
            if viewModel.isFocusModeEnabled {
                return "Solving..."
            }
            return formatTime(viewModel.timeElapsed)
        default:
            return formatTime(viewModel.timeElapsed)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        time.formattedTime
    }

    @MainActor
    private func generateShareImage(for solve: Solve) -> Image {
        let renderer = ImageRenderer(content: ShareCardView(solve: solve))
        renderer.scale = 3.0
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }
}

#Preview {
    ContentView()
}
