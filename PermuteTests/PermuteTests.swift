//
//  PermuteTests.swift
//  PermuteTests
//
//  Created by Bryan Smith on 12/11/25.
//

import XCTest
@testable import Permute

class PermuteTests: XCTestCase {

    let solvesKey = "solves_history"

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        UserDefaults.standard.removeObject(forKey: solvesKey)
    }

    override func tearDown() {
        // Clean up after
        UserDefaults.standard.removeObject(forKey: solvesKey)
        super.tearDown()
    }

    func testPersistence() {
        // 1. Create ViewModel and simulate a solve
        let vm1 = TimerViewModel()

        // Initial state check
        XCTAssertTrue(vm1.solves.isEmpty)

        // Simulate interaction flow: Idle -> Holding -> Running -> Idle (Saved)
        vm1.userTouchedDown() // Idle -> Holding
        vm1.userTouchedUp()   // Holding -> Running

        // Let it run for a tiny bit (not strictly necessary for logic, but good for realism)
        // RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        // Actually, since we don't need actual time passed to verify persistence, we can skip waiting.

        vm1.userTouchedDown() // Running -> Idle. Triggers save.

        XCTAssertEqual(vm1.solves.count, 1)
        let firstSolve = vm1.solves.first!

        // Verify it is in UserDefaults
        if let data = UserDefaults.standard.data(forKey: solvesKey) {
            let decoder = JSONDecoder()
            if let savedSolves = try? decoder.decode([Solve].self, from: data) {
                XCTAssertEqual(savedSolves.count, 1)
                XCTAssertEqual(savedSolves.first?.id, firstSolve.id)
            } else {
                XCTFail("Could not decode saved solves")
            }
        } else {
            XCTFail("Solves not saved to UserDefaults")
        }

        // 2. Create a NEW ViewModel and verify it loads the data
        let vm2 = TimerViewModel()
        XCTAssertEqual(vm2.solves.count, 1)
        XCTAssertEqual(vm2.solves.first?.id, firstSolve.id)
    }
}
