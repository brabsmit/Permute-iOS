//
//  SpeechManager.swift
//  Permute
//
//  Created by Jules on 12/12/25.
//

import AVFoundation
import UIKit

class SpeechManager: NSObject {
    static let shared = SpeechManager()
    private let synthesizer = AVSpeechSynthesizer()

    func speak(scramble: String) {
        // Stop any ongoing speech
        stop()

        // Process the scramble string to make it more pronounceable
        let spokenText = processScrambleForSpeech(scramble)

        let utterance = AVSpeechUtterance(string: spokenText)
        utterance.rate = 0.5 // Adjust rate as needed
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Ensure audio session is active
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }

        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    private func processScrambleForSpeech(_ scramble: String) -> String {
        // Replace common notation with spoken words
        // R' -> R Prime
        // U2 -> U Two
        // etc.

        let components = scramble.split(separator: " ")
        var spokenComponents: [String] = []

        for move in components {
            var spokenMove = String(move)

            if spokenMove.hasSuffix("'") {
                spokenMove = spokenMove.replacingOccurrences(of: "'", with: " Prime")
            } else if spokenMove.hasSuffix("2") {
                spokenMove = spokenMove.replacingOccurrences(of: "2", with: " Two")
            }

            // Add a pause (comma) after each move to improve rhythm
            spokenComponents.append(spokenMove)
        }

        return spokenComponents.joined(separator: ", ")
    }
}
