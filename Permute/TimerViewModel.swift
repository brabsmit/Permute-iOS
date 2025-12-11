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
    case waiting        // User touched, waiting to confirm hold (prevent accidental starts on taps)
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
    
    @Published var lastDeletedSolve: Solve?

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
    private var waitTimer: Timer?
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
        saveSolves()
    }

    func deleteLastSolve() {
        guard !solves.isEmpty else { return }
        lastDeletedSolve = solves.removeFirst()
        saveSolves()
    }

    func undoDelete() {
        guard let solve = lastDeletedSolve else { return }
        solves.insert(solve, at: 0)
        lastDeletedSolve = nil
        saveSolves()
    }

    func togglePlusTwo() {
        guard !solves.isEmpty else { return }
        var solve = solves[0]
        if solve.penalty == .plusTwo {
            solve.penalty = .none
        } else {
            solve.penalty = .plusTwo
        }
        solves[0] = solve
        saveSolves()
    }

    // User touches screen
    func userTouchedDown() {
        switch state {
        case .idle:
            // Go to waiting to distinguish tap from hold
            state = .waiting

            // Start a short timer to confirm hold
            waitTimer?.invalidate()
            waitTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                // Confirm hold
                self.timeElapsed = 0.0
                if self.isInspectionEnabled {
                    self.state = .readyToInspect
                } else {
                    self.state = .holding
                }
                self.triggerHapticFeedback(style: .light)
            }

        case .inspection:
            state = .holding
            triggerHapticFeedback(style: .light)

        case .running:
            stopTimer()
            triggerHapticFeedback(style: .heavy)

        case .readyToInspect, .holding, .waiting:
            // Ignore additional touches if already holding
            break
        }
    }
    
    // User releases screen
    func userTouchedUp() {
        switch state {
        case .waiting:
            // Released before hold confirmation -> Tap
            waitTimer?.invalidate()
            waitTimer = nil
            state = .idle

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
        // Use effectiveTime for averages
        let times = recentSolves.map { $0.effectiveTime }

        // Handle DNF: if any are DNF (0 in effectiveTime currently, but logically infinite)
        // WCA Rule: if more than 1 DNF in average of 5, result is DNF.
        // If 1 DNF, it counts as worst.

        // Count DNFs
        let dnfCount = recentSolves.filter { $0.penalty == .dnf }.count

        if count == 5 {
            if dnfCount > 1 { return "DNF" }
        } else if count == 12 {
            if dnfCount > 1 { return "DNF" } // Wait, for Ao12, is it > 1? WCA: Any result > 1 DNF is DNF.
        }

        // If there is 1 DNF, we treat it as the worst time.
        // My effectiveTime returns 0 for DNF.
        // So I should filter out DNFs for min/max calculation logic?

        // Better strategy: Map DNF to infinity
        let numericTimes = recentSolves.map { solve -> Double in
            if solve.penalty == .dnf {
                return Double.infinity
            }
            return solve.effectiveTime
        }

        guard let minTime = numericTimes.min(), let maxTime = numericTimes.max() else { return "--" }

        // If maxTime is infinity (DNF), it gets removed as the "worst".

        // Remove best and worst
        let sum = numericTimes.reduce(0) { currentSum, time in
            if time == Double.infinity { return currentSum } // Infinity shouldn't add to sum
            return currentSum + time
        }

        // If maxTime was Infinity (DNF), we just didn't add it.
        // If minTime was somehow Infinity (impossible unless all are DNF), we have issue.

        // We need to subtract minTime from sum. maxTime is excluded by not adding if it's infinity, or subtracting if it is finite.

        var adjustedSum = sum

        if maxTime != Double.infinity {
            adjustedSum -= maxTime
        }

        adjustedSum -= minTime

        let avg = adjustedSum / Double(count - 2)

        return avg.formattedTime
    }
}
