//
//  ScrambleGenerator.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import Foundation

struct ScrambleGenerator {
    
    // Legacy generator as fallback
    static func generateLegacyScramble(length: Int = 20) -> String {
        let moves = ["U", "D", "L", "R", "F", "B"]
        let modifiers = ["", "'", "2"]
        var scramble: [String] = []
        var lastMoveIndex = -1
        
        for _ in 0..<length {
            var randomMoveIndex: Int
            repeat {
                randomMoveIndex = Int.random(in: 0..<moves.count)
            } while randomMoveIndex == lastMoveIndex
            lastMoveIndex = randomMoveIndex
            
            let move = moves[randomMoveIndex]
            let modifier = modifiers.randomElement()!
            scramble.append("\(move)\(modifier)")
        }
        return scramble.joined(separator: " ")
    }

    static func generateScramble(length: Int = 20) async -> String {
        // Use Kociemba Solver
        let scramble = await KociembaSolver.shared.generateRandomScramble()
        if scramble.isEmpty {
            return generateLegacyScramble(length: length)
        }
        return scramble
    }
}
