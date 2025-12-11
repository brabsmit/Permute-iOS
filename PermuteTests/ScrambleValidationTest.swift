//
//  ScrambleValidationTest.swift
//  PermuteTests
//
//  Created by Jules on 12/11/25.
//

import XCTest
@testable import Permute

final class ScrambleValidationTest: XCTestCase {

    func testScrambleGeneration() async {
        // Validation: "Create a Unit Test that generates 100 scrambles and verifies that no scramble is shorter than 2 moves and no move is repeated/redundant."

        // Wait for Kociemba solver to initialize
        _ = await ScrambleGenerator.generateScramble()

        for _ in 0..<100 {
            let scramble = await ScrambleGenerator.generateScramble()

            // Verify not empty
            XCTAssertFalse(scramble.isEmpty, "Scramble should not be empty")

            let moves = scramble.split(separator: " ").map { String($0) }

            // Verify length >= 2
            XCTAssertTrue(moves.count >= 2, "Scramble should be at least 2 moves long. Got: \(scramble)")

            // Verify no repeated moves (e.g. R R) or redundant moves (R R')
            // Note: Kociemba solver generally produces optimal or near-optimal solutions without redundancies.
            // But we should check.

            for i in 0..<(moves.count - 1) {
                let m1 = moves[i]
                let m2 = moves[i+1]

                let f1 = String(m1.prefix(1))
                let f2 = String(m2.prefix(1))

                XCTAssertNotEqual(f1, f2, "Scramble should not have repeated faces: \(m1) \(m2) in \(scramble)")
            }
        }
    }
}
