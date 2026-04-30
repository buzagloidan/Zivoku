import Foundation

enum Technique: String, Sendable {
    case nakedSingle, hiddenSingle, lockedCandidates
    case nakedPair, nakedTriple
    case hiddenPair, hiddenTriple
    case xWing, swordfish, xyWing

    var weight: Int {
        switch self {
        case .nakedSingle:      return 1
        case .hiddenSingle:     return 2
        case .lockedCandidates: return 8
        case .nakedPair:        return 5
        case .nakedTriple:      return 10
        case .hiddenPair:       return 12
        case .hiddenTriple:     return 20
        case .xWing:            return 25
        case .swordfish:        return 40
        case .xyWing:           return 35
        }
    }
}

struct HumanSolveResult: Sendable {
    var solved: Bool
    var requiresGuessing: Bool
    var techniquesUsed: [Technique: Int]
    var totalScore: Int
}

// Mutable working state for the human-style solver.
private struct CandidateBoard {
    // bits 1–9 of candidates[i] = candidate set; placed[i] = digit is fixed
    var candidates: [Int]  // 81 ints
    var placed: [Bool]     // 81 bools

    init(grid: Grid) {
        candidates = Array(repeating: 0b1111111110, count: 81)  // bits 1-9
        placed = Array(repeating: false, count: 81)
        for i in 0..<81 where grid[i] != 0 {
            placeInternal(digit: grid[i], at: i)
        }
    }

    // Eliminate digit from a single cell's candidates.
    // Returns true if the cell is now a naked single (1 candidate left).
    @discardableResult
    private mutating func eliminate(_ digit: Int, from index: Int) -> Bool {
        guard !placed[index], (candidates[index] >> digit) & 1 == 1 else { return false }
        candidates[index] &= ~(1 << digit)
        return candidates[index].nonzeroBitCount == 1
    }

    mutating func placeInternal(digit: Int, at index: Int) {
        candidates[index] = 1 << digit
        placed[index] = true
        for j in boardPeers[index] {
            if !placed[j] {
                candidates[j] &= ~(1 << digit)
            }
        }
    }

    var isSolved: Bool { placed.allSatisfy { $0 } }

    // --- Technique implementations ---

    mutating func applyNakedSingle() -> Int {
        var count = 0
        for i in 0..<81 where !placed[i] {
            let c = candidates[i]
            if c != 0 && c & (c - 1) == 0 {  // exactly one bit set
                placeInternal(digit: c.trailingZeroBitCount, at: i)
                count += 1
            }
        }
        return count
    }

    mutating func applyHiddenSingle() -> Int {
        var count = 0
        for group in boardGroups {
            for d in 1...9 {
                let bit = 1 << d
                var found = -1
                var multiple = false
                for i in group where !placed[i] {
                    if candidates[i] & bit != 0 {
                        if found == -1 { found = i } else { multiple = true; break }
                    }
                }
                if !multiple, found != -1 {
                    placeInternal(digit: d, at: found)
                    count += 1
                }
            }
        }
        return count
    }

    mutating func applyLockedCandidates() -> Int {
        var count = 0
        // Pointing: box → row/col
        for b in 0..<9 {
            let boxCells = boardBoxes[b]
            let boxSet = Set(boxCells)
            for d in 1...9 {
                let bit = 1 << d
                let cells = boxCells.filter { !placed[$0] && candidates[$0] & bit != 0 }
                guard cells.count >= 2 else { continue }
                let rows = Set(cells.map { $0 / 9 })
                if rows.count == 1 {
                    let r = rows.first!
                    var changed = false
                    for j in boardRows[r] where !boxSet.contains(j) && !placed[j] {
                        if candidates[j] & bit != 0 { candidates[j] &= ~bit; changed = true }
                    }
                    if changed { count += 1 }
                }
                let cols = Set(cells.map { $0 % 9 })
                if cols.count == 1 {
                    let c = cols.first!
                    var changed = false
                    for j in boardCols[c] where !boxSet.contains(j) && !placed[j] {
                        if candidates[j] & bit != 0 { candidates[j] &= ~bit; changed = true }
                    }
                    if changed { count += 1 }
                }
            }
        }
        // Claiming: row/col → box
        for r in 0..<9 {
            let rowCells = boardRows[r]
            let rowSet = Set(rowCells)
            for d in 1...9 {
                let bit = 1 << d
                let cells = rowCells.filter { !placed[$0] && candidates[$0] & bit != 0 }
                guard cells.count >= 2 else { continue }
                let boxes = Set(cells.map { boxIndex($0) })
                if boxes.count == 1 {
                    let bx = boxes.first!
                    var changed = false
                    for j in boardBoxes[bx] where !rowSet.contains(j) && !placed[j] {
                        if candidates[j] & bit != 0 { candidates[j] &= ~bit; changed = true }
                    }
                    if changed { count += 1 }
                }
            }
        }
        for c in 0..<9 {
            let colCells = boardCols[c]
            let colSet = Set(colCells)
            for d in 1...9 {
                let bit = 1 << d
                let cells = colCells.filter { !placed[$0] && candidates[$0] & bit != 0 }
                guard cells.count >= 2 else { continue }
                let boxes = Set(cells.map { boxIndex($0) })
                if boxes.count == 1 {
                    let bx = boxes.first!
                    var changed = false
                    for j in boardBoxes[bx] where !colSet.contains(j) && !placed[j] {
                        if candidates[j] & bit != 0 { candidates[j] &= ~bit; changed = true }
                    }
                    if changed { count += 1 }
                }
            }
        }
        return count
    }

    mutating func applyNakedPair() -> Int {
        var count = 0
        for group in boardGroups {
            let pairs = group.filter { !placed[$0] && candidates[$0].nonzeroBitCount == 2 }
            for i in 0..<pairs.count {
                for j in (i + 1)..<pairs.count {
                    let ci = pairs[i], cj = pairs[j]
                    guard candidates[ci] == candidates[cj] else { continue }
                    let mask = candidates[ci]
                    var changed = false
                    for k in group where k != ci && k != cj && !placed[k] {
                        let before = candidates[k]
                        candidates[k] &= ~mask
                        if candidates[k] != before { changed = true }
                    }
                    if changed { count += 1 }
                }
            }
        }
        return count
    }

    mutating func applyNakedTriple() -> Int {
        var count = 0
        for group in boardGroups {
            let eligible = group.filter { !placed[$0] && (2...3).contains(candidates[$0].nonzeroBitCount) }
            guard eligible.count >= 3 else { continue }
            for i in 0..<eligible.count {
                for j in (i + 1)..<eligible.count {
                    for k in (j + 1)..<eligible.count {
                        let ci = eligible[i], cj = eligible[j], ck = eligible[k]
                        let union = candidates[ci] | candidates[cj] | candidates[ck]
                        guard union.nonzeroBitCount == 3 else { continue }
                        var changed = false
                        for l in group where l != ci && l != cj && l != ck && !placed[l] {
                            let before = candidates[l]
                            candidates[l] &= ~union
                            if candidates[l] != before { changed = true }
                        }
                        if changed { count += 1 }
                    }
                }
            }
        }
        return count
    }

    mutating func applyHiddenPair() -> Int {
        var count = 0
        for group in boardGroups {
            for d1 in 1...8 {
                for d2 in (d1 + 1)...9 {
                    let bit1 = 1 << d1, bit2 = 1 << d2
                    let c1 = group.filter { !placed[$0] && candidates[$0] & bit1 != 0 }
                    let c2 = group.filter { !placed[$0] && candidates[$0] & bit2 != 0 }
                    guard c1.count == 2 && c2.count == 2 && Set(c1) == Set(c2) else { continue }
                    let pair = bit1 | bit2
                    var changed = false
                    for cell in c1 where candidates[cell] != pair {
                        candidates[cell] = pair
                        changed = true
                    }
                    if changed { count += 1 }
                }
            }
        }
        return count
    }

    mutating func applyHiddenTriple() -> Int {
        var count = 0
        for group in boardGroups {
            for d1 in 1...7 {
                for d2 in (d1 + 1)...8 {
                    for d3 in (d2 + 1)...9 {
                        let b1 = 1 << d1, b2 = 1 << d2, b3 = 1 << d3
                        let cells = group.filter { i in
                            !placed[i] && (candidates[i] & (b1 | b2 | b3)) != 0
                        }
                        guard cells.count == 3 else { continue }
                        // Every one of the three digits must appear in at least one of the three cells.
                        let union = cells.reduce(0) { $0 | candidates[$1] }
                        guard union & b1 != 0, union & b2 != 0, union & b3 != 0 else { continue }
                        // All occurrences of d1/d2/d3 in the group must be in these 3 cells.
                        let others = group.filter { i in !placed[i] && !cells.contains(i) }
                        let leaks = others.reduce(0) { $0 | candidates[$1] }
                        guard leaks & b1 == 0, leaks & b2 == 0, leaks & b3 == 0 else { continue }
                        // Remove other candidates from these 3 cells.
                        let keep = b1 | b2 | b3
                        var changed = false
                        for cell in cells where candidates[cell] & ~keep != 0 {
                            candidates[cell] &= keep
                            changed = true
                        }
                        if changed { count += 1 }
                    }
                }
            }
        }
        return count
    }

    mutating func applyXWing() -> Int {
        var count = 0
        for d in 1...9 {
            let bit = 1 << d
            // Row-based
            let rowsWithTwo = (0..<9).filter { r in
                boardRows[r].filter { !placed[$0] && candidates[$0] & bit != 0 }.count == 2
            }
            for i in 0..<rowsWithTwo.count {
                for j in (i + 1)..<rowsWithTwo.count {
                    let r1 = rowsWithTwo[i], r2 = rowsWithTwo[j]
                    let cols1 = Set(boardRows[r1].filter { !placed[$0] && candidates[$0] & bit != 0 }.map { $0 % 9 })
                    let cols2 = Set(boardRows[r2].filter { !placed[$0] && candidates[$0] & bit != 0 }.map { $0 % 9 })
                    guard cols1 == cols2, cols1.count == 2 else { continue }
                    var changed = false
                    for c in cols1 {
                        for r in 0..<9 where r != r1 && r != r2 {
                            let cell = r * 9 + c
                            if !placed[cell] && candidates[cell] & bit != 0 {
                                candidates[cell] &= ~bit; changed = true
                            }
                        }
                    }
                    if changed { count += 1 }
                }
            }
            // Col-based
            let colsWithTwo = (0..<9).filter { c in
                boardCols[c].filter { !placed[$0] && candidates[$0] & bit != 0 }.count == 2
            }
            for i in 0..<colsWithTwo.count {
                for j in (i + 1)..<colsWithTwo.count {
                    let c1 = colsWithTwo[i], c2 = colsWithTwo[j]
                    let rows1 = Set(boardCols[c1].filter { !placed[$0] && candidates[$0] & bit != 0 }.map { $0 / 9 })
                    let rows2 = Set(boardCols[c2].filter { !placed[$0] && candidates[$0] & bit != 0 }.map { $0 / 9 })
                    guard rows1 == rows2, rows1.count == 2 else { continue }
                    var changed = false
                    for r in rows1 {
                        for c in 0..<9 where c != c1 && c != c2 {
                            let cell = r * 9 + c
                            if !placed[cell] && candidates[cell] & bit != 0 {
                                candidates[cell] &= ~bit; changed = true
                            }
                        }
                    }
                    if changed { count += 1 }
                }
            }
        }
        return count
    }

    mutating func applySwordfish() -> Int {
        var count = 0
        for d in 1...9 {
            let bit = 1 << d
            // Row-based
            let eligible = (0..<9).filter { r in
                let c = boardRows[r].filter { !placed[$0] && candidates[$0] & bit != 0 }.count
                return c == 2 || c == 3
            }
            if eligible.count >= 3 {
                for i in 0..<eligible.count {
                    for j in (i + 1)..<eligible.count {
                        for k in (j + 1)..<eligible.count {
                            let rows = [eligible[i], eligible[j], eligible[k]]
                            let allCols = Set(rows.flatMap { r in
                                boardRows[r].filter { !placed[$0] && candidates[$0] & bit != 0 }.map { $0 % 9 }
                            })
                            guard allCols.count == 3 else { continue }
                            var changed = false
                            for c in allCols {
                                for r in 0..<9 where !rows.contains(r) {
                                    let cell = r * 9 + c
                                    if !placed[cell] && candidates[cell] & bit != 0 {
                                        candidates[cell] &= ~bit; changed = true
                                    }
                                }
                            }
                            if changed { count += 1 }
                        }
                    }
                }
            }
            // Col-based
            let eligibleC = (0..<9).filter { c in
                let r = boardCols[c].filter { !placed[$0] && candidates[$0] & bit != 0 }.count
                return r == 2 || r == 3
            }
            if eligibleC.count >= 3 {
                for i in 0..<eligibleC.count {
                    for j in (i + 1)..<eligibleC.count {
                        for k in (j + 1)..<eligibleC.count {
                            let cols = [eligibleC[i], eligibleC[j], eligibleC[k]]
                            let allRows = Set(cols.flatMap { c in
                                boardCols[c].filter { !placed[$0] && candidates[$0] & bit != 0 }.map { $0 / 9 }
                            })
                            guard allRows.count == 3 else { continue }
                            var changed = false
                            for r in allRows {
                                for c in 0..<9 where !cols.contains(c) {
                                    let cell = r * 9 + c
                                    if !placed[cell] && candidates[cell] & bit != 0 {
                                        candidates[cell] &= ~bit; changed = true
                                    }
                                }
                            }
                            if changed { count += 1 }
                        }
                    }
                }
            }
        }
        return count
    }

    mutating func applyXYWing() -> Int {
        var count = 0
        let pivots = (0..<81).filter { !placed[$0] && candidates[$0].nonzeroBitCount == 2 }
        for pivot in pivots {
            let (px, py) = twoDigits(candidates[pivot])
            // Wings that see the pivot and have 2 candidates including px or py
            let wings = boardPeers[pivot].filter { !placed[$0] && candidates[$0].nonzeroBitCount == 2 }
            let wingsX = wings.filter { (candidates[$0] >> px) & 1 == 1 }  // includes x → x,z
            let wingsY = wings.filter { (candidates[$0] >> py) & 1 == 1 }  // includes y → y,z
            for wx in wingsX {
                let (a, b) = twoDigits(candidates[wx])
                let z1 = a == px ? b : a  // the non-x digit
                for wy in wingsY where wy != wx {
                    let (c, dd) = twoDigits(candidates[wy])
                    let z2 = c == py ? dd : c  // the non-y digit
                    guard z1 == z2 else { continue }
                    let z = z1
                    let bit = 1 << z
                    // Cells that see both wx and wy can't have z
                    var changed = false
                    let wpeers = boardPeerSets[wx]
                    for cell in boardPeers[wy]
                        where cell != pivot && cell != wx && cell != wy
                             && wpeers.contains(cell) && !placed[cell]
                             && candidates[cell] & bit != 0
                    {
                        candidates[cell] &= ~bit
                        changed = true
                    }
                    if changed { count += 1 }
                }
            }
        }
        return count
    }

    private func twoDigits(_ mask: Int) -> (Int, Int) {
        let a = mask.trailingZeroBitCount
        let b = (mask & ~(1 << a)).trailingZeroBitCount
        return (a, b)
    }
}

// MARK: - Public API

enum HumanSolver {
    static func solve(_ grid: Grid) -> HumanSolveResult {
        var board = CandidateBoard(grid: grid)
        var techCounts = [Technique: Int]()

        var progress = true
        while progress && !board.isSolved {
            progress = false

            var n = board.applyNakedSingle()
            if n > 0 { techCounts[.nakedSingle, default: 0] += n; progress = true; continue }

            n = board.applyHiddenSingle()
            if n > 0 { techCounts[.hiddenSingle, default: 0] += n; progress = true; continue }

            n = board.applyLockedCandidates()
            if n > 0 { techCounts[.lockedCandidates, default: 0] += n; progress = true; continue }

            n = board.applyNakedPair()
            if n > 0 { techCounts[.nakedPair, default: 0] += n; progress = true; continue }

            n = board.applyNakedTriple()
            if n > 0 { techCounts[.nakedTriple, default: 0] += n; progress = true; continue }

            n = board.applyHiddenPair()
            if n > 0 { techCounts[.hiddenPair, default: 0] += n; progress = true; continue }

            n = board.applyHiddenTriple()
            if n > 0 { techCounts[.hiddenTriple, default: 0] += n; progress = true; continue }

            n = board.applyXWing()
            if n > 0 { techCounts[.xWing, default: 0] += n; progress = true; continue }

            n = board.applySwordfish()
            if n > 0 { techCounts[.swordfish, default: 0] += n; progress = true; continue }

            n = board.applyXYWing()
            if n > 0 { techCounts[.xyWing, default: 0] += n; progress = true; continue }
        }

        let score = techCounts.reduce(0) { $0 + $1.key.weight * $1.value }
        return HumanSolveResult(
            solved: board.isSolved,
            requiresGuessing: !board.isSolved,
            techniquesUsed: techCounts,
            totalScore: score
        )
    }
}
