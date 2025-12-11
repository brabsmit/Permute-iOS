//
//  TimerViewModelTests.swift
//  PermuteTests
//
//  Created by Jules on 12/12/25.
//

import XCTest
@testable import Permute

class TimerViewModelTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset defaults
        UserDefaults.standard.removeObject(forKey: "isInspectionEnabled")
        UserDefaults.standard.removeObject(forKey: "cubeType")
    }

    func testInspectionToggleDefaults() {
        let vm = TimerViewModel()
        // Default is true
        XCTAssertTrue(vm.isInspectionEnabled)

        vm.isInspectionEnabled = false

        // Test persistence
        let vm2 = TimerViewModel()
        XCTAssertFalse(vm2.isInspectionEnabled)
    }

    func testCubeTypeDefaults() {
        let vm = TimerViewModel()
        // Default is 3x3
        XCTAssertEqual(vm.cubeType, "3x3")

        vm.cubeType = "4x4"

        // Test persistence
        let vm2 = TimerViewModel()
        XCTAssertEqual(vm2.cubeType, "4x4")
    }

    func testInspectionLogic_Enabled() {
        let vm = TimerViewModel()
        vm.isInspectionEnabled = true

        XCTAssertEqual(vm.state, .idle)

        // Touch down -> Ready to Inspect
        vm.userTouchedDown()
        XCTAssertEqual(vm.state, .readyToInspect)

        // Touch up -> Inspection
        vm.userTouchedUp()
        XCTAssertEqual(vm.state, .inspection)

        // Touch down -> Holding
        vm.userTouchedDown()
        XCTAssertEqual(vm.state, .holding)

        // Touch up -> Running
        vm.userTouchedUp()
        XCTAssertEqual(vm.state, .running)
    }

    func testInspectionLogic_Disabled() {
        let vm = TimerViewModel()
        vm.isInspectionEnabled = false

        XCTAssertEqual(vm.state, .idle)

        // Touch down -> Holding (skipping inspection)
        vm.userTouchedDown()
        XCTAssertEqual(vm.state, .holding)

        // Touch up -> Running
        vm.userTouchedUp()
        XCTAssertEqual(vm.state, .running)
    }

    func testAddManualSolve() {
        let vm = TimerViewModel()
        let initialScramble = vm.currentScramble
        let manualTime: TimeInterval = 12.45

        vm.addManualSolve(time: manualTime)

        // Check if solve was added
        XCTAssertEqual(vm.solves.count, 1)
        XCTAssertEqual(vm.solves.first?.time, manualTime)
        XCTAssertEqual(vm.solves.first?.scramble, initialScramble)

        // Check if scramble was updated
        XCTAssertNotEqual(vm.currentScramble, initialScramble)

        // Check persistence
        let vm2 = TimerViewModel()
        XCTAssertEqual(vm2.solves.count, 1)
        XCTAssertEqual(vm2.solves.first?.time, manualTime)
    }
}
