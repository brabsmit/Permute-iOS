//
//  SolveModel.swift
//  Permute
//
//  Created by Bryan Smith on 12/11/25.
//

import Foundation

struct Solve: Identifiable, Codable {
    let id: UUID
    let time: TimeInterval
    let scramble: String
    let date: Date
    
    // Helper to format time as 12.34
    var formattedTime: String {
        return time.formattedTime
    }
}

extension TimeInterval {
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
