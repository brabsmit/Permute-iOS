//
//  TimerViewModel.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI

enum TimerState {
    case idle       // Waiting for user
    case holding    // User is holding screen (getting ready)
    case running    // Timer is going
}

class TimerViewModel: ObservableObject {
    @Published var timeElapsed: TimeInterval = 0.0
    @Published var state: TimerState = .idle
    @Published var currentScramble: String = ""
    @Published var solves: [Solve] = []
    
    private var timer: Timer?
    private var startDate: Date?
    
    init() {
        newScramble()
    }
    
    func newScramble() {
        currentScramble = ScrambleGenerator.generateScramble()
    }
    
    // User touches screen
    func userTouchedDown() {
        if state == .idle {
            state = .holding
            // Reset timer visuals
            timeElapsed = 0.0
        } else if state == .running {
            stopTimer()
        }
    }
    
    // User releases screen
    func userTouchedUp() {
        if state == .holding {
            startTimer()
        }
    }
    
    private func startTimer() {
        state = .running
        startDate = Date()
        
        // High frequency timer for smooth UI updates
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            if let start = self.startDate {
                self.timeElapsed = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        state = .idle
        
        // Save the solve
        let newSolve = Solve(id: UUID(), time: timeElapsed, scramble: currentScramble, date: Date())
        solves.insert(newSolve, at: 0) // Add to top of list
        
        // Generate next scramble
        newScramble()
    }

    // Averages (Ao5 / Ao12)
    var ao5: String {
        return formatAverage(count: 5)
    }

    var ao12: String {
        return formatAverage(count: 12)
    }

    private func formatAverage(count: Int) -> String {
        guard let avg = calculateAverage(count: count) else { return "-" }
        return avg.formattedTime
    }

    private func calculateAverage(count: Int) -> TimeInterval? {
        guard solves.count >= count else { return nil }

        // Grab the last 'count' solves (from the beginning of the list)
        let subset = solves.prefix(count).map { $0.time }

        // Remove best and worst
        // We sort the times, then drop the first (min) and last (max)
        let sorted = subset.sorted()
        let trimmed = sorted.dropFirst().dropLast()

        // Average the middle
        let sum = trimmed.reduce(0, +)
        return sum / Double(trimmed.count)
    }
}
