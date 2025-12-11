//
//  PruningTable.swift
//  Permute
//
//  Ported from min2phase (Java/JS)
//

import Foundation

actor PruningTable {
    // Phase 1 Tables
    var twistMove = [[Int]](repeating: [Int](repeating: 0, count: 18), count: Defs.N_TWIST)
    var flipMove = [[Int]](repeating: [Int](repeating: 0, count: 18), count: Defs.N_FLIP)
    var sliceMove = [[Int]](repeating: [Int](repeating: 0, count: 18), count: Defs.N_SLICE)

    var twistPrun = [Int8](repeating: -1, count: Defs.N_TWIST)
    var flipPrun = [Int8](repeating: -1, count: Defs.N_FLIP)
    var slicePrun = [Int8](repeating: -1, count: Defs.N_SLICE)

    // Phase 2 Tables
    // Note: min2phase uses composite coordinates for Phase 2 pruning
    // Here we implement simplified version or follow min2phase logic
    // min2phase logic:
    // UDSlice sorted * Corner -> Prun
    // UDSlice sorted * Edge8 -> Prun
    //
    // N_SLICE_SORTED (Permutation of 4 edges in slice) = 24. Wait, "Phase 2 Slice"
    // Actually Phase 2 uses:
    // Edge4 (24)
    // Corner (40320)
    // Edge8 (40320)
    //
    // Pruning Tables:
    // Slice (Edge4) & Corner -> 24 * 40320 / 2 (symmetry) ~ 480KB
    // Slice (Edge4) & Edge8 -> 24 * 40320 / 2 ~ 480KB

    // Let's use simpler tables if needed, but for "industry standard speed", we need good pruning.
    // However, implementing full symmetry reduction is very complex for this task.
    // I will implement raw tables without symmetry reduction for now, as it fits within memory (iOS has plenty).
    // 24 * 40320 = 967,680 entries. 1MB. Trivial.

    var edge4Move = [[Int]](repeating: [Int](repeating: 0, count: 10), count: 24)
    var cornerMove = [[Int]](repeating: [Int](repeating: 0, count: 10), count: 40320)
    var edge8Move = [[Int]](repeating: [Int](repeating: 0, count: 10), count: 40320)

    var cornerPrun = [Int8](repeating: -1, count: 24 * 40320)
    var edgePrun = [Int8](repeating: -1, count: 24 * 40320)

    // Phase 1 Pruning Combination
    // Twist & Slice? Flip & Slice?
    // min2phase uses: UDSlice & Twist, UDSlice & Flip.
    // UDSlice (495) * Twist (2187) = 1,082,565 ~ 1MB.
    // UDSlice (495) * Flip (2048) = 1,013,760 ~ 1MB.
    // So let's implement these combined tables instead of simple ones.

    var twistSlicePrun = [Int8](repeating: -1, count: Defs.N_TWIST * Defs.N_SLICE)
    var flipSlicePrun = [Int8](repeating: -1, count: Defs.N_FLIP * Defs.N_SLICE)

    var initialized = false

    init() {}

    func initTables() {
        if initialized { return }

        initPhase1Moves()
        initPhase1Prun()

        initPhase2Moves()
        initPhase2Prun()

        initialized = true
    }

    private func initPhase1Moves() {
        let a = CubieCube()
        for i in 0..<Defs.N_TWIST {
            for j in 0..<18 {
                a.setTwist(i)
                a.multiply(CubieCube.moveCube[j])
                twistMove[i][j] = a.getTwist()
            }
        }

        for i in 0..<Defs.N_FLIP {
            for j in 0..<18 {
                a.setFlip(i)
                a.multiply(CubieCube.moveCube[j])
                flipMove[i][j] = a.getFlip()
            }
        }

        for i in 0..<Defs.N_SLICE {
            for j in 0..<18 {
                a.setSlice(i)
                a.multiply(CubieCube.moveCube[j])
                sliceMove[i][j] = a.getSlice()
            }
        }
    }

    private func initPhase1Prun() {
        // TwistSlice
        twistSlicePrun.withUnsafeMutableBufferPointer { buffer in
            buffer.fill(repeatElement: -1)
            buffer[0] = 0

            var depth: Int8 = 0
            var done = 1
            let total = Defs.N_TWIST * Defs.N_SLICE

            while done < total {
                for i in 0..<total {
                    if buffer[i] == depth {
                        let twist = i / Defs.N_SLICE
                        let slice = i % Defs.N_SLICE

                        for j in 0..<18 {
                            let newTwist = twistMove[twist][j]
                            let newSlice = sliceMove[slice][j]
                            let idx = newTwist * Defs.N_SLICE + newSlice
                            if buffer[idx] == -1 {
                                buffer[idx] = depth + 1
                                done += 1
                            }
                        }
                    }
                }
                depth += 1
            }
        }

        // FlipSlice
        flipSlicePrun.withUnsafeMutableBufferPointer { buffer in
            buffer.fill(repeatElement: -1)
            buffer[0] = 0

            var depth: Int8 = 0
            var done = 1
            let total = Defs.N_FLIP * Defs.N_SLICE

            while done < total {
                for i in 0..<total {
                    if buffer[i] == depth {
                        let flip = i / Defs.N_SLICE
                        let slice = i % Defs.N_SLICE

                        for j in 0..<18 {
                            let newFlip = flipMove[flip][j]
                            let newSlice = sliceMove[slice][j]
                            let idx = newFlip * Defs.N_SLICE + newSlice
                            if buffer[idx] == -1 {
                                buffer[idx] = depth + 1
                                done += 1
                            }
                        }
                    }
                }
                depth += 1
            }
        }
    }

    private func initPhase2Moves() {
        let a = CubieCube()

        // Edge4 (0..23)
        // Only Phase 2 moves (U, U', U2, D, D', D2, R2, L2, F2, B2)
        // Indices in moveCube: 0, 1, 2 (U), 9, 10, 11 (D), 4 (R2), 13 (L2), 7 (F2), 16 (B2)
        // Wait, move indices:
        // U: 0, 1, 2
        // R: 3, 4, 5 -> R2 is 4
        // F: 6, 7, 8 -> F2 is 7
        // D: 9, 10, 11
        // L: 12, 13, 14 -> L2 is 13
        // B: 15, 16, 17 -> B2 is 16
        // Phase 2 moves map to 0..9
        // 0: U(0), 1: U2(1), 2: U'(2)
        // 3: D(9), 4: D2(10), 5: D'(11)
        // 6: R2(4)
        // 7: L2(13)
        // 8: F2(7)
        // 9: B2(16)

        let phase2Moves = [0, 1, 2, 9, 10, 11, 4, 13, 7, 16]

        for i in 0..<24 {
            for j in 0..<10 {
                a.setEdge4(i)
                a.multiply(CubieCube.moveCube[phase2Moves[j]])
                edge4Move[i][j] = a.getEdge4()
            }
        }

        for i in 0..<40320 {
            for j in 0..<10 {
                a.setCorner(i)
                a.multiply(CubieCube.moveCube[phase2Moves[j]])
                cornerMove[i][j] = a.getCorner()
            }
        }

        for i in 0..<40320 {
            for j in 0..<10 {
                a.setEdge8(i)
                a.multiply(CubieCube.moveCube[phase2Moves[j]])
                edge8Move[i][j] = a.getEdge8()
            }
        }
    }

    private func initPhase2Prun() {
        // Corner & Edge4
        cornerPrun.withUnsafeMutableBufferPointer { buffer in
            buffer.fill(repeatElement: -1)
            buffer[0] = 0 // Solved state: corner=0, edge4=0

            var depth: Int8 = 0
            var done = 1
            let total = 24 * 40320

            while done < total {
                for i in 0..<total {
                    if buffer[i] == depth {
                        let edge4 = i / 40320
                        let corner = i % 40320

                        for j in 0..<10 {
                            let newEdge4 = edge4Move[edge4][j]
                            let newCorner = cornerMove[corner][j]
                            let idx = newEdge4 * 40320 + newCorner
                            if buffer[idx] == -1 {
                                buffer[idx] = depth + 1
                                done += 1
                            }
                        }
                    }
                }
                depth += 1
            }
        }

        // Edge8 & Edge4
        edgePrun.withUnsafeMutableBufferPointer { buffer in
            buffer.fill(repeatElement: -1)
            buffer[0] = 0

            var depth: Int8 = 0
            var done = 1
            let total = 24 * 40320

            while done < total {
                for i in 0..<total {
                    if buffer[i] == depth {
                        let edge4 = i / 40320
                        let edge8 = i % 40320

                        for j in 0..<10 {
                            let newEdge4 = edge4Move[edge4][j]
                            let newEdge8 = edge8Move[edge8][j]
                            let idx = newEdge4 * 40320 + newEdge8
                            if buffer[idx] == -1 {
                                buffer[idx] = depth + 1
                                done += 1
                            }
                        }
                    }
                }
                depth += 1
            }
        }
    }
}
