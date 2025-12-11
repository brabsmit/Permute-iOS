//
//  Search.swift
//  Permute
//
//  Ported from min2phase (Java/JS)
//

import Foundation

class Search {
    var pruningTable: PruningTable

    // Phase 1 moves (all 18)
    // Phase 2 moves (10 specific moves)
    // 0: U(0), 1: U2(1), 2: U'(2)
    // 3: D(9), 4: D2(10), 5: D'(11)
    // 6: R2(4)
    // 7: L2(13)
    // 8: F2(7)
    // 9: B2(16)
    let phase2Moves = [0, 1, 2, 9, 10, 11, 4, 13, 7, 16]

    // Axis map to avoid redundant moves
    // U(0), R(1), F(2), D(3), L(4), B(5)
    // Standard redundancy:
    // Don't do same face twice (e.g. U U)
    // Don't do opposite face if index is less (e.g. D U is ok, U D is not? No, U D is ok, D U is ok. But U D U is not.)
    // Wait, typical prune:
    // if move == lastMove: skip
    // if move == opposite(lastMove): skip if move < lastMove (canonical order)

    // Move indices in 0..17 are (Face * 3 + power)
    // Face = move / 3

    init(pruningTable: PruningTable) {
        self.pruningTable = pruningTable
    }

    // Solve a random CubieCube
    func solve(c: CubieCube) async -> String {
        // Run IDA*
        // Phase 1

        let cc = CoordCube(c: c)

        // We need to access pruning tables from Actor
        let pt = pruningTable

        // Since IDA* is recursive and we can't easily make recursive async calls efficiently or access actor state in synchronous loop without overhead.
        // It's better to fetch the tables once? No, they are huge.
        // But `PruningTable` is an actor.
        // Copying 2MB+ of tables is fine.
        // Let's copy the needed tables for the search.

        let twistSlicePrun = await pt.twistSlicePrun
        let flipSlicePrun = await pt.flipSlicePrun
        let cornerPrun = await pt.cornerPrun
        let edgePrun = await pt.edgePrun

        let twistMove = await pt.twistMove
        let flipMove = await pt.flipMove
        let sliceMove = await pt.sliceMove
        let edge4Move = await pt.edge4Move
        let cornerMove = await pt.cornerMove
        let edge8Move = await pt.edge8Move

        var solution: [Int] = []

        // IDA* Phase 1
        // Target: Twist=0, Flip=0, Slice=0? No, Slice just needs to bring edges to UD slice.
        // Actually Slice=0 corresponds to FR, FL, BL, BR being in 8, 9, 10, 11.

        // Distance heuristic: max(twistSlicePrun, flipSlicePrun)

        var minDepth1 = 0

        // Initial heuristic
        let h1 = max(
            twistSlicePrun[cc.twist * Defs.N_SLICE + cc.slice],
            flipSlicePrun[cc.flip * Defs.N_SLICE + cc.slice]
        )
        minDepth1 = Int(h1)

        // Phase 1 Search
        // We need to store phase 1 solution to apply it to get phase 2 state

        var moves1: [Int] = []
        var maxDepth1 = 12 // Typical phase 1 length

        while true {
            if let result = searchPhase1(
                twist: cc.twist,
                flip: cc.flip,
                slice: cc.slice,
                depth: 0,
                maxDepth: minDepth1,
                lastMove: -1,
                solution: &moves1,
                twistSlicePrun: twistSlicePrun,
                flipSlicePrun: flipSlicePrun,
                twistMove: twistMove,
                flipMove: flipMove,
                sliceMove: sliceMove
            ) {
                // Phase 1 found. Result is phase 2 state? No, searchPhase1 returns success.
                // We have moves1.
                // Apply moves1 to cc to get phase 2 state.

                var c2 = c.copy()
                for m in moves1 {
                    c2.multiply(CubieCube.moveCube[m])
                }
                let cc2 = CoordCube(c: c2)

                // Now search Phase 2
                // Phase 2 target: corner=0, edge8=0, edge4=0

                // Heuristic
                let h2 = max(
                    cornerPrun[cc2.edge4 * 40320 + cc2.corner],
                    edgePrun[cc2.edge4 * 40320 + cc2.edge8]
                )

                var minDepth2 = Int(h2)
                var moves2: [Int] = []

                // We can limit total length
                let maxTotal = 20
                if moves1.count + minDepth2 > maxTotal {
                    // Try next depth in phase 1?
                    // min2phase continues searching phase 1 for better solutions.
                    // For this task, we can just accept the first valid solution if it's short enough, or iterate.
                    // Let's try to solve phase 2.
                }

                // Search Phase 2
                while true {
                    if let _ = searchPhase2(
                        edge4: cc2.edge4,
                        edge8: cc2.edge8,
                        corner: cc2.corner,
                        depth: 0,
                        maxDepth: minDepth2,
                        lastMove: moves1.last ?? -1,
                        solution: &moves2,
                        cornerPrun: cornerPrun,
                        edgePrun: edgePrun,
                        edge4Move: edge4Move,
                        cornerMove: cornerMove,
                        edge8Move: edge8Move
                    ) {
                        // Found!
                        // Combine moves
                        let finalMoves = moves1 + moves2.map { phase2Moves[$0] }
                        return movesToString(finalMoves)
                    }
                    minDepth2 += 1
                    if moves1.count + minDepth2 > 24 { break } // Limit
                }

                // If we are here, phase 2 failed for this phase 1 solution (too long).
                // Continue phase 1 search?
                // For simplicity, we just increase minDepth1 and retry from scratch?
                // The recursive searchPhase1 should ideally yield all solutions at depth X.
                // But here I implemented it to return first one.
                // To do it properly, we need to integrate Phase 2 search inside the leaf of Phase 1.
            }
            minDepth1 += 1
            if minDepth1 > maxDepth1 { break } // Should not happen
        }

        return ""
    }

    // Integrated search
    // Returns full solution string
    func solveIntegrated(c: CubieCube) async -> String {
        let pt = pruningTable

        let twistSlicePrun = await pt.twistSlicePrun
        let flipSlicePrun = await pt.flipSlicePrun
        let cornerPrun = await pt.cornerPrun
        let edgePrun = await pt.edgePrun

        let twistMove = await pt.twistMove
        let flipMove = await pt.flipMove
        let sliceMove = await pt.sliceMove
        let edge4Move = await pt.edge4Move
        let cornerMove = await pt.cornerMove
        let edge8Move = await pt.edge8Move

        let cc = CoordCube(c: c)
        var moves1: [Int] = []
        var moves2: [Int] = []

        var depth1 = 0
        let h1 = max(
            twistSlicePrun[cc.twist * Defs.N_SLICE + cc.slice],
            flipSlicePrun[cc.flip * Defs.N_SLICE + cc.slice]
        )
        depth1 = Int(h1)

        while depth1 <= 12 { // Phase 1 usually <= 12
            if let sol = searchPhase1Integrated(
                twist: cc.twist,
                flip: cc.flip,
                slice: cc.slice,
                depth: 0,
                maxDepth: depth1,
                lastMove: -1,
                moves1: &moves1,
                moves2: &moves2,
                twistSlicePrun: twistSlicePrun,
                flipSlicePrun: flipSlicePrun,
                twistMove: twistMove,
                flipMove: flipMove,
                sliceMove: sliceMove,
                edge4Move: edge4Move,
                cornerMove: cornerMove,
                edge8Move: edge8Move,
                cornerPrun: cornerPrun,
                edgePrun: edgePrun,
                originalCube: c
            ) {
                return sol
            }
            depth1 += 1
        }
        return "Error"
    }

    func searchPhase1(
        twist: Int, flip: Int, slice: Int,
        depth: Int, maxDepth: Int, lastMove: Int,
        solution: inout [Int],
        twistSlicePrun: [Int8], flipSlicePrun: [Int8],
        twistMove: [[Int]], flipMove: [[Int]], sliceMove: [[Int]]
    ) -> Bool? {
        let h = max(
            twistSlicePrun[twist * Defs.N_SLICE + slice],
            flipSlicePrun[flip * Defs.N_SLICE + slice]
        )
        if h == 0 {
             return depth == maxDepth ? true : nil
        }

        if depth + Int(h) > maxDepth { return nil }

        for m in 0..<18 {
            if isRedundant(move: m, lastMove: lastMove) { continue }

            solution.append(m)
            if searchPhase1(
                twist: twistMove[twist][m],
                flip: flipMove[flip][m],
                slice: sliceMove[slice][m],
                depth: depth + 1,
                maxDepth: maxDepth,
                lastMove: m,
                solution: &solution,
                twistSlicePrun: twistSlicePrun,
                flipSlicePrun: flipSlicePrun,
                twistMove: twistMove,
                flipMove: flipMove,
                sliceMove: sliceMove
            ) != nil {
                return true
            }
            solution.removeLast()
        }
        return nil
    }

    // Integrated Phase 1 + Phase 2
    func searchPhase1Integrated(
        twist: Int, flip: Int, slice: Int,
        depth: Int, maxDepth: Int, lastMove: Int,
        moves1: inout [Int], moves2: inout [Int],
        twistSlicePrun: [Int8], flipSlicePrun: [Int8],
        twistMove: [[Int]], flipMove: [[Int]], sliceMove: [[Int]],
        edge4Move: [[Int]], cornerMove: [[Int]], edge8Move: [[Int]],
        cornerPrun: [Int8], edgePrun: [Int8],
        originalCube: CubieCube
    ) -> String? {
        let h = max(
            twistSlicePrun[twist * Defs.N_SLICE + slice],
            flipSlicePrun[flip * Defs.N_SLICE + slice]
        )

        // Found Phase 1 solution
        if h == 0 && depth == maxDepth {
            // Initialize Phase 2
            // We need to compute phase 2 coordinates from original cube + moves1
            let c2 = originalCube.copy()
            for m in moves1 {
                c2.multiply(CubieCube.moveCube[m])
            }

            // Verify Phase 1 solved
            if c2.getTwist() != 0 || c2.getFlip() != 0 || c2.getSlice() != 0 {
                // Slice in phase 2 means 0?
                // getSlice checks if FR, FL, BL, BR are in 8,9,10,11.
                // Yes.
            }

            let edge4 = c2.getEdge4()
            let corner = c2.getCorner()
            let edge8 = c2.getEdge8()

            // Heuristic for Phase 2
            let h2 = max(
                cornerPrun[edge4 * 40320 + corner],
                edgePrun[edge4 * 40320 + edge8]
            )

            var maxDepth2 = Int(h2)
            // Limit total length to ~21-22
            let totalLimit = 22
            if depth + maxDepth2 > totalLimit { return nil }

            while depth + maxDepth2 <= totalLimit {
                moves2.removeAll()
                if searchPhase2(
                    edge4: edge4, edge8: edge8, corner: corner,
                    depth: 0, maxDepth: maxDepth2, lastMove: lastMove,
                    solution: &moves2,
                    cornerPrun: cornerPrun, edgePrun: edgePrun,
                    edge4Move: edge4Move, cornerMove: cornerMove, edge8Move: edge8Move
                ) != nil {
                    let finalMoves = moves1 + moves2.map { phase2Moves[$0] }
                    return movesToString(finalMoves)
                }
                maxDepth2 += 1
            }
            return nil
        }

        if depth + Int(h) > maxDepth { return nil }

        for m in 0..<18 {
            if isRedundant(move: m, lastMove: lastMove) { continue }

            moves1.append(m)
            if let res = searchPhase1Integrated(
                twist: twistMove[twist][m],
                flip: flipMove[flip][m],
                slice: sliceMove[slice][m],
                depth: depth + 1,
                maxDepth: maxDepth,
                lastMove: m,
                moves1: &moves1,
                moves2: &moves2,
                twistSlicePrun: twistSlicePrun,
                flipSlicePrun: flipSlicePrun,
                twistMove: twistMove,
                flipMove: flipMove,
                sliceMove: sliceMove,
                edge4Move: edge4Move,
                cornerMove: cornerMove,
                edge8Move: edge8Move,
                cornerPrun: cornerPrun,
                edgePrun: edgePrun,
                originalCube: originalCube
            ) {
                return res
            }
            moves1.removeLast()
        }
        return nil
    }

    func searchPhase2(
        edge4: Int, edge8: Int, corner: Int,
        depth: Int, maxDepth: Int, lastMove: Int,
        solution: inout [Int],
        cornerPrun: [Int8], edgePrun: [Int8],
        edge4Move: [[Int]], cornerMove: [[Int]], edge8Move: [[Int]]
    ) -> Bool? {
        let h = max(
            cornerPrun[edge4 * 40320 + corner],
            edgePrun[edge4 * 40320 + edge8]
        )

        if h == 0 { return true }
        if depth + Int(h) > maxDepth { return nil }

        for i in 0..<10 {
            let m = phase2Moves[i]
            if isRedundant(move: m, lastMove: lastMove) { continue }

            solution.append(i)
            if searchPhase2(
                edge4: edge4Move[edge4][i],
                edge8: edge8Move[edge8][i],
                corner: cornerMove[corner][i],
                depth: depth + 1,
                maxDepth: maxDepth,
                lastMove: m,
                solution: &solution,
                cornerPrun: cornerPrun,
                edgePrun: edgePrun,
                edge4Move: edge4Move,
                cornerMove: cornerMove,
                edge8Move: edge8Move
            ) != nil {
                return true
            }
            solution.removeLast()
        }
        return nil
    }

    func isRedundant(move: Int, lastMove: Int) -> Bool {
        if lastMove == -1 { return false }

        let lastFace = lastMove / 3
        let face = move / 3

        if face == lastFace { return true }
        // Commutative moves: U(0) & D(3), R(1) & L(4), F(2) & B(5)
        // If opposite faces, enforce order (e.g. U then D is allowed, D then U is not)
        if face == lastFace + 3 { // e.g. D(3) after U(0)
             // Allow? Yes.
             // But U after D? No.
             return false
        }
        if lastFace == face + 3 { // e.g. U(0) after D(3)
             return true // Prune to enforce canonical order
        }
        return false
    }

    func movesToString(_ moves: [Int]) -> String {
        return moves.map { Defs.moveNames[$0] }.joined(separator: " ")
    }
}
