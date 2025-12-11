//
//  Defs.swift
//  Permute
//
//  Ported from min2phase (Java/JS)
//

import Foundation

enum KociembaError: Error {
    case invalidScramble
    case solutionTimeout
}

struct Defs {
    // Moves
    static let U = 0, R = 1, F = 2, D = 3, L = 4, B = 5

    // Facelets/Cubies
    // Corners
    static let URF = 0, UFL = 1, ULB = 2, UBR = 3
    static let DFR = 4, DLF = 5, DBL = 6, DRB = 7

    // Edges
    static let UR = 0, UF = 1, UL = 2, UB = 3
    static let DR = 4, DF = 5, DL = 6, DB = 7
    static let FR = 8, FL = 9, BL = 10, BR = 11

    static let N_MOVES = 18
    static let N_MOVES2 = 10
    static let N_SLICE = 495
    static let N_TWIST = 2187
    static let N_FLIP = 2048
    static let N_URFTO_DLF = 20160
    static let N_FRTO_BR = 11880
    static let N_PARITY = 2
    static let N_URtoDF = 20160 // 8! / (8-6)!

    // Move names for printing
    static let moveNames = [
        "U", "U2", "U'", "R", "R2", "R'", "F", "F2", "F'",
        "D", "D2", "D'", "L", "L2", "L'", "B", "B2", "B'"
    ]
}
