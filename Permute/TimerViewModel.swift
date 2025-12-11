//
//  TimerViewModel.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI

enum TimerState {
    case idle           // Waiting for user
    case readyToInspect // User holding to start inspection
    case inspection     // Inspection countdown
    case holding        // User is holding screen (getting ready to solve)
    case running        // Timer is going
}

class TimerViewModel: ObservableObject {
    @Published var timeElapsed: TimeInterval = 0.0
    @Published var state: TimerState = .idle
    @Published var currentScramble: String = ""
    @Published var solves: [Solve] = []
    @Published var inspectionTime: Int = 15
    
    private var timer: Timer?
    private var inspectionTimer: Timer?
    private var startDate: Date?
    
    init() {
        newScramble()
    }
    
    func newScramble() {
        currentScramble = ScrambleGenerator.generateScramble()
    }
    
    // User touches screen
    func userTouchedDown() {
        switch state {
        case .idle:
            state = .readyToInspect
            // Reset timer visuals
            timeElapsed = 0.0
        case .inspection:
            state = .holding
        case .running:
            stopTimer()
        case .readyToInspect, .holding:
            // Ignore additional touches if already holding
            break
        }
    }
    
    // User releases screen
    func userTouchedUp() {
        switch state {
        case .readyToInspect:
            startInspection()
        case .holding:
            startTimer()
        case .idle, .inspection, .running:
            break
        }
    }

    private func startInspection() {
        state = .inspection
        inspectionTime = 15

        inspectionTimer?.invalidate()
        inspectionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.inspectionTime -= 1
        }
    }
    
    private func startTimer() {
        inspectionTimer?.invalidate()
        inspectionTimer = nil

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
        inspectionTimer?.invalidate()
        inspectionTimer = nil

        state = .idle
        
        // Save the solve
        let newSolve = Solve(id: UUID(), time: timeElapsed, scramble: currentScramble, date: Date())
        solves.insert(newSolve, at: 0) // Add to top of list
        
        // Generate next scramble
        newScramble()
    }
}
