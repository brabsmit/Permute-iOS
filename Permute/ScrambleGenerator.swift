//
//  ScrambleGenerator.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//


import Foundation

struct ScrambleGenerator {
    private static let moves = ["U", "D", "L", "R", "F", "B"]
    private static let modifiers = ["", "'", "2"]
    
    static func generateScramble(length: Int = 20) -> String {
        var scramble: [String] = []
        var lastMoveIndex = -1
        
        for _ in 0..<length {
            var randomMoveIndex: Int
            
            // Ensure we don't pick the same face twice in a row
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
}