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
    private let solvesKey = "solves_history"
    
    init() {
        loadSolves()
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
        saveSolves()
        
        // Generate next scramble
        newScramble()
    }

    private func saveSolves() {
        if let encoded = try? JSONEncoder().encode(solves) {
            UserDefaults.standard.set(encoded, forKey: solvesKey)
        }
    }

    private func loadSolves() {
        if let data = UserDefaults.standard.data(forKey: solvesKey),
           let decoded = try? JSONDecoder().decode([Solve].self, from: data) {
            solves = decoded
        }
    }
}
