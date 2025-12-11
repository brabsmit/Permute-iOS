//
//  KociembaSolver.swift
//  Permute
//
//  Main entry point for Kociemba solver
//

import Foundation

actor KociembaSolver {
    static let shared = KociembaSolver()

    private let pruningTable = PruningTable()
    private var search: Search?
    private var isInitializing = false

    init() {
        // Start initialization on background
        Task.detached(priority: .background) {
            await self.initialize()
        }
    }

    func initialize() async {
        if isInitializing || search != nil { return }
        isInitializing = true

        CubieCube.initMoveCubes()
        await pruningTable.initTables()

        search = Search(pruningTable: pruningTable)
        isInitializing = false
    }

    func solve(scramble: String) async -> String? {
        // Not used for generating scrambles, but for solving
        return nil
    }

    func generateRandomScramble() async -> String {
        // Ensure initialized
        if search == nil {
            await initialize()
        }

        // Generate random valid state
        // Simplest way: Randomize CP, CO, EP, EO then fix parity
        // Actually simplest is: Apply N random moves and solve? No, that's not random state.

        // Random State Generation:
        // 1. Random Corner Permutation (8!)
        // 2. Random Corner Orientation (3^7)
        // 3. Random Edge Permutation (12!)
        // 4. Random Edge Orientation (2^11)
        // 5. Check Parity (Permutation parity must match)

        let c = CubieCube()

        // Random CP
        c.setCorner(Int.random(in: 0..<40320))
        // Random CO
        c.setTwist(Int.random(in: 0..<2187))
        // Random EO
        c.setFlip(Int.random(in: 0..<2048))

        // Random EP
        // We don't have setEdgePermutation directly.
        // We have setEdge8 and setSlice? No.
        // Let's implement full random EP

        var edges = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
        edges.shuffle()
        c.ep = edges

        // Fix Parity
        // Edge parity must equal Corner parity
        // Corner parity from setCorner?
        // We need to check current parity

        let cornerParity = c.getCornerParity()
        let edgeParity = c.getEdgeParity()

        if cornerParity != edgeParity {
            // Swap two edges to flip edge parity
            let temp = c.ep[0]
            c.ep[0] = c.ep[1]
            c.ep[1] = temp
        }

        // Solve the random state
        if let s = search {
             return await s.solveIntegrated(c: c)
        }

        return ""
    }
}

extension CubieCube {
    func getCornerParity() -> Int {
        var ret = 0
        for i in 0..<7 {
            for j in (i+1)..<8 {
                if cp[i] > cp[j] { ret += 1 }
            }
        }
        return ret % 2
    }

    func getEdgeParity() -> Int {
        var ret = 0
        for i in 0..<11 {
            for j in (i+1)..<12 {
                if ep[i] > ep[j] { ret += 1 }
            }
        }
        return ret % 2
    }
}
