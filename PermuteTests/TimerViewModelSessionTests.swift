//
//  TimerViewModelSessionTests.swift
//  PermuteTests
//
//  Created by Jules on 12/12/25.
//

import XCTest
@testable import Permute

class TimerViewModelSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset defaults and session storage
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }

    func testSessionCreation() {
        let vm = TimerViewModel()

        // Should have at least one session (default)
        XCTAssertFalse(vm.sessions.isEmpty)
        let initialSessionId = vm.currentSessionId

        vm.createSession(name: "One-Handed", cubeType: "3x3")

        // Should have 2 sessions
        XCTAssertEqual(vm.sessions.count, 2)
        XCTAssertNotEqual(vm.currentSessionId, initialSessionId)
        XCTAssertEqual(vm.currentSession?.name, "One-Handed")
    }

    func testSessionSwitching() {
        let vm = TimerViewModel()
        let firstSessionId = vm.currentSessionId

        vm.createSession(name: "2x2", cubeType: "2x2")
        let secondSessionId = vm.currentSessionId

        XCTAssertNotEqual(firstSessionId, secondSessionId)
        XCTAssertEqual(vm.cubeType, "2x2")

        // Switch back to first
        vm.switchSession(to: firstSessionId)
        XCTAssertEqual(vm.currentSessionId, firstSessionId)
        // Default cube type for first session is usually 3x3 unless changed
        XCTAssertEqual(vm.cubeType, "3x3")
    }

    func testSolvesAreSessionSpecific() {
        let vm = TimerViewModel()

        // Add solve to first session (simulate)
        // Since we can't easily simulate touches here without async waits, we modify solves manually if possible?
        // But `solves` is sync'd.

        // Let's use internal method or simulate state changes.
        // Easier: simulate state changes.
        vm.isInspectionEnabled = false
        vm.userTouchedDown() // Holding
        vm.userTouchedUp()   // Running
        vm.userTouchedDown() // Stop -> Idle (adds solve)

        XCTAssertEqual(vm.solves.count, 1)
        let solveId = vm.solves.first?.id

        // Create new session
        vm.createSession(name: "New Session", cubeType: "3x3")
        XCTAssertEqual(vm.solves.count, 0)

        // Switch back
        vm.switchSession(to: vm.sessions.first!.id)
        XCTAssertEqual(vm.solves.count, 1)
        XCTAssertEqual(vm.solves.first?.id, solveId)
    }

    func testSessionPersistence() {
        var vm = TimerViewModel()
        vm.createSession(name: "Persisted Session", cubeType: "4x4")
        let sessionId = vm.currentSessionId

        // New instance
        vm = TimerViewModel()

        XCTAssertTrue(vm.sessions.contains(where: { $0.name == "Persisted Session" }))
        XCTAssertEqual(vm.currentSessionId, sessionId)
        XCTAssertEqual(vm.cubeType, "4x4")
    }
}
