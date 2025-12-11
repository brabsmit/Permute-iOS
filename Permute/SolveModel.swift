//
//  SolveModel.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import Foundation

extension TimeInterval {
    // Helper to format time as 12.34
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        let milliseconds = Int((self.truncatingRemainder(dividingBy: 1)) * 100)
        
        if minutes > 0 {
            return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
        } else {
            return String(format: "%d.%02d", seconds, milliseconds)
        }
    }
}

enum Penalty: String, Codable {
    case none
    case plusTwo = "+2"
    case dnf = "DNF"
}

struct Solve: Identifiable, Codable {
    let id: UUID
    let time: TimeInterval
    let scramble: String
    let date: Date
    var penalty: Penalty? = .none // Optional for backward compatibility

    var effectiveTime: TimeInterval {
        switch penalty ?? .none {
        case .none: return time
        case .plusTwo: return time + 2.0
        case .dnf: return 0 // DNF logic should be handled in averages
        }
    }

    var formattedTime: String {
        switch penalty ?? .none {
        case .none:
            return time.formattedTime
        case .plusTwo:
            return effectiveTime.formattedTime + "+"
        case .dnf:
            return "DNF"
        }
    }
}

struct Session: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var solves: [Solve]
    var cubeType: String
}
