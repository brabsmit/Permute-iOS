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
    
    // Sessions
    @Published var sessions: [Session] = []
    @Published var currentSessionId: UUID = UUID()

    // Settings
    @Published var isInspectionEnabled: Bool = UserDefaults.standard.bool(forKey: "isInspectionEnabled") {
        didSet {
            UserDefaults.standard.set(isInspectionEnabled, forKey: "isInspectionEnabled")
        }
    }
    @Published var cubeType: String = UserDefaults.standard.string(forKey: "cubeType") ?? "3x3" {
        didSet {
            // When cubeType changes globally (via settings), update current session
            // Note: This might be triggered when we switch session and update cubeType, causing a loop?
            // We need to be careful.
            UserDefaults.standard.set(cubeType, forKey: "cubeType")
            updateCurrentSessionSettings()
            newScramble()
        }
    }

    var ao5: String {
        formatAverage(calculateAverage(of: 5))
    }

    var ao12: String {
        formatAverage(calculateAverage(of: 12))
    }

    // Public getter for analysis view
    func getAverage(of count: Int) -> Double? {
        calculateAverage(of: count)
    }

    var currentSession: Session? {
        sessions.first(where: { $0.id == currentSessionId })
    }

    private var timer: Timer?
    private var inspectionTimer: Timer?
    private var startDate: Date?
    private let solvesKey = "solves_history" // Legacy key
    private let sessionsKey = "sessions_history"
    private let currentSessionKey = "current_session_id"
    
    init() {
        // Register default defaults
        UserDefaults.standard.register(defaults: ["isInspectionEnabled": true, "cubeType": "3x3"])

        // Re-load to ensure we have correct values if they were just registered
        self.isInspectionEnabled = UserDefaults.standard.bool(forKey: "isInspectionEnabled")

        // We load sessions first.
        loadData()

        // If we have a current session, use its cube type.
        if let session = currentSession {
            self.cubeType = session.cubeType
            self.solves = session.solves
        } else {
            self.cubeType = UserDefaults.standard.string(forKey: "cubeType") ?? "3x3"
        }

        newScramble()
    }
    
    func newScramble() {
        currentScramble = ScrambleGenerator.generateScramble()
    }
    
    func deleteSolve(at offsets: IndexSet) {
        solves.remove(atOffsets: offsets)
        saveData()
    }

    func addManualSolve(time: TimeInterval) {
        let newSolve = Solve(id: UUID(), time: time, scramble: currentScramble, date: Date())
        solves.insert(newSolve, at: 0)
        saveSolves()
        newScramble()
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
        saveData()
        
        // Generate next scramble
        newScramble()
    }

    // Session Management

    func createSession(name: String, cubeType: String) {
        let newSession = Session(id: UUID(), name: name, solves: [], cubeType: cubeType)
        sessions.append(newSession)
        switchSession(to: newSession.id)
        saveData()
    }

    func switchSession(to id: UUID) {
        guard let session = sessions.first(where: { $0.id == id }) else { return }
        currentSessionId = id
        solves = session.solves

        // Updating cubeType will trigger didSet, which calls updateCurrentSessionSettings
        // We want to update the local cubeType state to match the session
        // But we avoid infinite loop by checking if it's different
        if cubeType != session.cubeType {
            cubeType = session.cubeType
        }

        // Also save current session ID
        UserDefaults.standard.set(currentSessionId.uuidString, forKey: currentSessionKey)
        newScramble() // Scramble might depend on cubeType? Currently ScrambleGenerator is static/global but maybe not?
        // Actually ScrambleGenerator seems to not take parameters in the current code I've seen?
        // Let's check ScrambleGenerator.swift if I can. But for now newScramble() is safe.
    }

    func deleteSession(id: UUID) {
        // Don't delete the last session
        guard sessions.count > 1 else { return }

        if let index = sessions.firstIndex(where: { $0.id == id }) {
            sessions.remove(at: index)

            // If we deleted the current session, switch to the first one
            if id == currentSessionId {
                if let first = sessions.first {
                    switchSession(to: first.id)
                }
            }
            saveData()
        }
    }

    private func updateCurrentSessionSettings() {
        if let index = sessions.firstIndex(where: { $0.id == currentSessionId }) {
            sessions[index].cubeType = cubeType
            // We don't save solves here, just settings.
            // But we should persist sessions.
            // Note: This is called from cubeType didSet.
            saveSessions()
        }
    }

    private func saveData() {
        // Sync current solves to current session
        if let index = sessions.firstIndex(where: { $0.id == currentSessionId }) {
            sessions[index].solves = solves
        }
        saveSessions()
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
        UserDefaults.standard.set(currentSessionId.uuidString, forKey: currentSessionKey)
    }

    private func loadData() {
        // Try to load sessions
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([Session].self, from: data),
           !decoded.isEmpty {
            sessions = decoded

            // Restore current session ID
            if let savedIdString = UserDefaults.standard.string(forKey: currentSessionKey),
               let savedId = UUID(uuidString: savedIdString),
               sessions.contains(where: { $0.id == savedId }) {
                currentSessionId = savedId
            } else {
                currentSessionId = sessions.first!.id
            }
        } else {
            // Migration: Check for legacy solves
            var initialSolves: [Solve] = []
            if let data = UserDefaults.standard.data(forKey: solvesKey),
               let decoded = try? JSONDecoder().decode([Solve].self, from: data) {
                initialSolves = decoded
            }

            let defaultSession = Session(id: UUID(), name: "Main Session", solves: initialSolves, cubeType: UserDefaults.standard.string(forKey: "cubeType") ?? "3x3")
            sessions = [defaultSession]
            currentSessionId = defaultSession.id
            saveSessions()
        }
    }

    private func calculateAverage(of count: Int) -> Double? {
        guard solves.count >= count else { return nil }
        let recentSolves = Array(solves.prefix(count))
        let times = recentSolves.map { $0.time }
        guard let minTime = times.min(), let maxTime = times.max() else { return nil }

        // Remove best and worst
        // Note: if multiple min or max exist, only one of each should be removed strictly speaking?
        // WCA Rule 9f8) "The best and worst result are discarded..."
        // If there are duplicate mins or maxs, we discard one of them.
        // Summing all and subtracting min and max achieves this safely.

        let sum = times.reduce(0, +) - minTime - maxTime
        let avg = sum / Double(count - 2)

        return avg
    }

    private func formatAverage(_ average: Double?) -> String {
        guard let avg = average else { return "--" }
        return avg.formattedTime
    }
}
