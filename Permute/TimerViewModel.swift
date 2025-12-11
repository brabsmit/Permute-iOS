//
//  TimerViewModel.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import SwiftUI
import UIKit

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
    @Published var lastSolveWasPB: Bool = false
    
    // Settings
    @Published var isInspectionEnabled: Bool = UserDefaults.standard.bool(forKey: "isInspectionEnabled") {
        didSet {
            UserDefaults.standard.set(isInspectionEnabled, forKey: "isInspectionEnabled")
        }
    }
    @Published var cubeType: String = UserDefaults.standard.string(forKey: "cubeType") ?? "3x3" {
        didSet {
            UserDefaults.standard.set(cubeType, forKey: "cubeType")
        }
    }

    var ao5: String {
        calculateAverage(of: 5)
    }

    var ao12: String {
        calculateAverage(of: 12)
    }

    private var timer: Timer?
    private var inspectionTimer: Timer?
    private var startDate: Date?
    private let solvesKey = "solves_history"
    
    init() {
        // Register default defaults
        UserDefaults.standard.register(defaults: ["isInspectionEnabled": true, "cubeType": "3x3"])

        // Re-load to ensure we have correct values if they were just registered
        self.isInspectionEnabled = UserDefaults.standard.bool(forKey: "isInspectionEnabled")
        self.cubeType = UserDefaults.standard.string(forKey: "cubeType") ?? "3x3"

        loadSolves()
        newScramble()
    }
    
    func newScramble() {
        currentScramble = ScrambleGenerator.generateScramble()
    }
    
    func deleteSolve(at offsets: IndexSet) {
        solves.remove(atOffsets: offsets)
    }

    // User touches screen
    func userTouchedDown() {
        switch state {
        case .idle:
            // Reset timer visuals
            timeElapsed = 0.0

            if isInspectionEnabled {
                state = .readyToInspect
            } else {
                state = .holding
            }
            triggerHapticFeedback(style: .light)

        case .inspection:
            state = .holding
            triggerHapticFeedback(style: .light)

        case .running:
            stopTimer()
            triggerHapticFeedback(style: .heavy)

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
            triggerHapticFeedback(style: .medium)

        case .holding:
            startTimer()
            triggerHapticFeedback(style: .medium)

        case .idle, .inspection, .running:
            break
        }
    }

    private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
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

        // Check for PB
        let otherSolves = solves // solves before inserting the new one
        if let bestPrevious = otherSolves.min(by: { $0.time < $1.time }) {
            lastSolveWasPB = newSolve.time < bestPrevious.time
        } else {
            // First solve ever is a PB
            lastSolveWasPB = true
        }

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

    private func calculateAverage(of count: Int) -> String {
        guard solves.count >= count else { return "--" }
        let recentSolves = Array(solves.prefix(count))
        let times = recentSolves.map { $0.time }
        guard let minTime = times.min(), let maxTime = times.max() else { return "--" }

        // Remove best and worst
        // Note: if multiple min or max exist, only one of each should be removed strictly speaking?
        // WCA Rule 9f8) "The best and worst result are discarded..."
        // If there are duplicate mins or maxs, we discard one of them.
        // Summing all and subtracting min and max achieves this safely.

        let sum = times.reduce(0, +) - minTime - maxTime
        let avg = sum / Double(count - 2)

        return avg.formattedTime
    }
}
