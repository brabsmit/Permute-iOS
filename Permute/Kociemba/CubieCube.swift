//
//  CubieCube.swift
//  Permute
//
//  Ported from min2phase (Java/JS)
//

import Foundation

class CubieCube: @unchecked Sendable {
    // 8 corner permutations, 8 corner orientations
    var cp: [Int] = [0, 1, 2, 3, 4, 5, 6, 7]
    var co: [Int] = [0, 0, 0, 0, 0, 0, 0, 0]

    // 12 edge permutations, 12 edge orientations
    var ep: [Int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    var eo: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    init() {}

    init(cp: [Int], co: [Int], ep: [Int], eo: [Int]) {
        self.cp = cp
        self.co = co
        self.ep = ep
        self.eo = eo
    }

    func copy() -> CubieCube {
        return CubieCube(cp: cp, co: co, ep: ep, eo: eo)
    }

    // Multiply this cube by another cube b
    // result = this * b
    func multiply(_ b: CubieCube) {
        var newCp = [Int](repeating: 0, count: 8)
        var newCo = [Int](repeating: 0, count: 8)
        var newEp = [Int](repeating: 0, count: 12)
        var newEo = [Int](repeating: 0, count: 12)

        for i in 0..<8 {
            newCp[i] = cp[b.cp[i]]
            newCo[i] = (co[b.cp[i]] + b.co[i]) % 3
        }

        for i in 0..<12 {
            newEp[i] = ep[b.ep[i]]
            newEo[i] = (eo[b.ep[i]] + b.eo[i]) % 2
        }

        self.cp = newCp
        self.co = newCo
        self.ep = newEp
        self.eo = newEo
    }

    // Set this cube to the inverse of d
    func invFrom(_ d: CubieCube) {
        for i in 0..<8 {
            self.cp[d.cp[i]] = i
        }
        for i in 0..<8 {
            self.co[i] = (3 - d.co[self.cp[i]]) % 3
        }

        for i in 0..<12 {
            self.ep[d.ep[i]] = i
        }
        for i in 0..<12 {
            self.eo[i] = (2 - d.eo[self.ep[i]]) % 2
        }
    }

    func verify() -> String? {
        var sum = 0
        var edgeCount = [Int](repeating: 0, count: 12)
        for e in ep {
            edgeCount[e] += 1
        }
        for i in 0..<12 {
            if edgeCount[i] != 1 { return "Error: Wrong edge permutation" }
        }

        sum = 0
        for i in 0..<12 { sum += eo[i] }
        if sum % 2 != 0 { return "Error: Wrong edge orientation" }

        var cornerCount = [Int](repeating: 0, count: 8)
        for c in cp {
            cornerCount[c] += 1
        }
        for i in 0..<8 {
            if cornerCount[i] != 1 { return "Error: Wrong corner permutation" }
        }

        sum = 0
        for i in 0..<8 { sum += co[i] }
        if sum % 3 != 0 { return "Error: Wrong corner orientation" }

        return nil
    }

    // Basic moves
    static var moveCube: [CubieCube] = []

    static func initMoveCubes() {
        moveCube = [CubieCube](repeating: CubieCube(), count: 18)

        let basicMovesCp = [
            [Defs.UBR, Defs.URF, Defs.UFL, Defs.ULB, Defs.DFR, Defs.DLF, Defs.DBL, Defs.DRB], // U
            [Defs.DFR, Defs.UFL, Defs.ULB, Defs.URF, Defs.DRB, Defs.DLF, Defs.DBL, Defs.UBR], // R
            [Defs.UFL, Defs.DLF, Defs.ULB, Defs.UBR, Defs.URF, Defs.DFR, Defs.DBL, Defs.DRB], // F
            [Defs.URF, Defs.UFL, Defs.ULB, Defs.UBR, Defs.DLF, Defs.DBL, Defs.DRB, Defs.DFR], // D
            [Defs.URF, Defs.ULB, Defs.DBL, Defs.UBR, Defs.DFR, Defs.UFL, Defs.DLF, Defs.DRB], // L
            [Defs.URF, Defs.UFL, Defs.UBR, Defs.DRB, Defs.DFR, Defs.DLF, Defs.ULB, Defs.DBL]  // B
        ]

        let basicMovesCo = [
            [0, 0, 0, 0, 0, 0, 0, 0], // U
            [2, 0, 0, 1, 1, 0, 0, 2], // R
            [1, 2, 0, 0, 2, 1, 0, 0], // F
            [0, 0, 0, 0, 0, 0, 0, 0], // D
            [0, 1, 2, 0, 0, 2, 1, 0], // L
            [0, 0, 1, 2, 0, 0, 2, 1]  // B
        ]

        let basicMovesEp = [
            [Defs.UB, Defs.UR, Defs.UF, Defs.UL, Defs.DR, Defs.DF, Defs.DL, Defs.DB, Defs.FR, Defs.FL, Defs.BL, Defs.BR], // U
            [Defs.FR, Defs.UF, Defs.UL, Defs.UB, Defs.BR, Defs.DF, Defs.DL, Defs.DB, Defs.DR, Defs.FL, Defs.BL, Defs.UR], // R
            [Defs.UR, Defs.FL, Defs.UL, Defs.UB, Defs.DR, Defs.FR, Defs.DL, Defs.DB, Defs.UF, Defs.DF, Defs.BL, Defs.BR], // F
            [Defs.UR, Defs.UF, Defs.UL, Defs.UB, Defs.DF, Defs.DL, Defs.DB, Defs.DR, Defs.FR, Defs.FL, Defs.BL, Defs.BR], // D
            [Defs.UR, Defs.UF, Defs.BL, Defs.UB, Defs.DR, Defs.DF, Defs.FL, Defs.DB, Defs.FR, Defs.UL, Defs.DL, Defs.BR], // L
            [Defs.UR, Defs.UF, Defs.UL, Defs.BR, Defs.DR, Defs.DF, Defs.DL, Defs.BL, Defs.FR, Defs.FL, Defs.UB, Defs.DB]  // B
        ]

        // Corrected EO values
        // F flips UF(1), DF(5), FL(9), FR(8)
        // B flips UB(3), DB(7), BL(10), BR(11)
        let basicMovesEo = [
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // U
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // R
            [0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 0, 0], // F
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // D
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // L
            [0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1]  // B
        ]

        for i in 0..<6 {
            let move = CubieCube()
            move.cp = basicMovesCp[i]
            move.co = basicMovesCo[i]
            move.ep = basicMovesEp[i]
            move.eo = basicMovesEo[i]

            moveCube[i * 3] = move

            let move2 = CubieCube()
            move2.cp = move.cp
            move2.co = move.co
            move2.ep = move.ep
            move2.eo = move.eo
            move2.multiply(move)
            moveCube[i * 3 + 1] = move2

            let move3 = CubieCube()
            move3.cp = move2.cp
            move3.co = move2.co
            move3.ep = move2.ep
            move3.eo = move2.eo
            move3.multiply(move)
            moveCube[i * 3 + 2] = move3
        }
    }
}
