//
//  CoordCube.swift
//  Permute
//
//  Ported from min2phase (Java/JS)
//

import Foundation

class CoordCube: @unchecked Sendable {
    // Phase 1 coordinates
    var twist: Int = 0 // Corner orientation 0..2186
    var flip: Int = 0 // Edge orientation 0..2047
    var slice: Int = 0 // 4 UD slice edges position 0..494

    // Phase 2 coordinates
    var edge4: Int = 0 // Permutation of 4 UD slice edges 0..23
    var edge8: Int = 0 // Permutation of 8 U/D edges 0..40319
    var corner: Int = 0 // Permutation of 8 corners 0..40319

    init(c: CubieCube) {
        self.twist = c.getTwist()
        self.flip = c.getFlip()
        self.slice = c.getSlice()
        self.edge4 = c.getEdge4()
        self.edge8 = c.getEdge8()
        self.corner = c.getCorner()
    }
}

extension CubieCube {
    // Twist (CO)
    func getTwist() -> Int {
        var ret = 0
        for i in 0..<7 {
            ret = 3 * ret + co[i]
        }
        return ret
    }

    func setTwist(_ twist: Int) {
        var twist = twist
        var twistParity = 0
        for i in stride(from: 6, through: 0, by: -1) {
            co[i] = twist % 3
            twistParity += co[i]
            twist /= 3
        }
        co[7] = (3 - twistParity % 3) % 3
    }

    // Flip (EO)
    func getFlip() -> Int {
        var ret = 0
        for i in 0..<11 {
            ret = 2 * ret + eo[i]
        }
        return ret
    }

    func setFlip(_ flip: Int) {
        var flip = flip
        var flipParity = 0
        for i in stride(from: 10, through: 0, by: -1) {
            eo[i] = flip % 2
            flipParity += eo[i]
            flip /= 2
        }
        eo[11] = (2 - flipParity % 2) % 2
    }

    // Slice (Positions of FR, FL, BL, BR edges)
    // Permute/Kociemba/Defs.swift defines FR=8, FL=9, BL=10, BR=11
    // The Slice coordinate is the position of these 4 edges among 12 positions.
    // C(12, 4) = 495
    func getSlice() -> Int {
        var ret = 0
        var x = 0
        // Check edges in reverse order
        for i in stride(from: 11, through: 0, by: -1) {
            // Is the edge at i one of the slice edges (8, 9, 10, 11)?
            if ep[i] >= 8 && ep[i] <= 11 {
                ret += Util.C(11 - i, x + 1)
                x += 1
            }
        }
        return ret
    }

    func setSlice(_ slice: Int) {
        var slice = slice
        var x = 4
        var offset = 0
        // Reset ep to -1 to mark empty
        for i in 0..<12 { ep[i] = -1 }

        for i in 0..<12 {
            if slice >= Util.C(11 - i, x) {
                slice -= Util.C(11 - i, x)
                ep[i] = 8 + offset // 8, 9, 10, 11
                offset += 1
                x -= 1
            }
        }
        // Fill the rest
        x = 0
        for i in 0..<12 {
            if ep[i] == -1 {
                ep[i] = x
                x += 1
            }
        }
    }

    // Phase 2 Coordinates

    // Edge4: Permutation of the 4 slice edges (8,9,10,11) in their positions
    func getEdge4() -> Int {
        var a = [0, 0, 0, 0]
        var x = 0
        for i in 0..<12 {
            if ep[i] >= 8 && ep[i] <= 11 {
                a[x] = ep[i] - 8
                x += 1
            }
        }

        var ret = 0
        // Permutation of 4 elements: 4! = 24
        // Use standard permutation to index
        for i in 0..<3 {
            var k = 0
            for j in (i+1)..<4 {
                if a[j] < a[i] { k += 1 }
            }
            ret = (ret + k) * (3 - i)
        }
        return ret
    }

    func setEdge4(_ edge4: Int) {
        var edge4 = edge4
        var sliceEdges = [8, 9, 10, 11]
        // Standard permutation from index
        // Extract permutation
        var p = [0, 0, 0, 0]
        var nums = [0, 1, 2, 3]

        let fact = [1, 1, 2, 6] // 0!, 1!, 2!, 3!

        for i in 0..<3 {
            let temp = edge4 / fact[3 - i]
            edge4 %= fact[3 - i]
            p[i] = nums[temp]
            nums.remove(at: temp)
        }
        p[3] = nums[0]

        // Place them back into the cube
        var x = 0
        for i in 0..<12 {
            if ep[i] >= 8 {
                ep[i] = p[x] + 8
                x += 1
            }
        }
    }

    // Edge8: Permutation of the 8 U/D edges (0..7)
    func getEdge8() -> Int {
        var a = [0, 0, 0, 0, 0, 0, 0, 0]
        var x = 0
        for i in 0..<12 {
            if ep[i] < 8 {
                a[x] = ep[i]
                x += 1
            }
        }

        var ret = 0
        for i in 0..<7 {
            var k = 0
            for j in (i+1)..<8 {
                if a[j] < a[i] { k += 1 }
            }
            ret = (ret + k) * (7 - i)
        }
        return ret
    }

    func setEdge8(_ edge8: Int) {
        var edge8 = edge8
        var nums = [0, 1, 2, 3, 4, 5, 6, 7]
        var p = [0, 0, 0, 0, 0, 0, 0, 0]
        let fact = [1, 1, 2, 6, 24, 120, 720, 5040]

        for i in 0..<7 {
            let temp = edge8 / fact[7 - i]
            edge8 %= fact[7 - i]
            p[i] = nums[temp]
            nums.remove(at: temp)
        }
        p[7] = nums[0]

        var x = 0
        for i in 0..<12 {
            if ep[i] < 8 {
                ep[i] = p[x]
                x += 1
            }
        }
    }

    // Corner: Permutation of 8 corners
    func getCorner() -> Int {
        var ret = 0
        for i in 0..<7 {
            var k = 0
            for j in (i+1)..<8 {
                if cp[j] < cp[i] { k += 1 }
            }
            ret = (ret + k) * (7 - i)
        }
        return ret
    }

    func setCorner(_ corner: Int) {
        var corner = corner
        var nums = [0, 1, 2, 3, 4, 5, 6, 7]
        let fact = [1, 1, 2, 6, 24, 120, 720, 5040]

        for i in 0..<7 {
            let temp = corner / fact[7 - i]
            corner %= fact[7 - i]
            cp[i] = nums[temp]
            nums.remove(at: temp)
        }
        cp[7] = nums[0]
    }
}

struct Util {
    static func C(_ n: Int, _ k: Int) -> Int {
        if n < k { return 0 }
        if k < 0 { return 0 }
        if k == 0 { return 1 }
        if k > n / 2 { return C(n, n - k) }

        var res = 1
        for i in 1...k {
            res = res * (n - i + 1) / i
        }
        return res
    }
}
