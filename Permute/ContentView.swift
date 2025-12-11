//
//  ContentView.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TimerViewModel()
    
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
                
                Spacer()
                
                // Bottom: Stats List (Only show when not running)
                if viewModel.state != .running {
                    ScrollView {
                        VStack(spacing: 10) {
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
                            }
                        }
                        .padding()
                    }
                    .frame(height: 200)
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
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%02d", seconds, milliseconds)
        }
    }
}

#Preview {
    ContentView()
}
