import Foundation

// Fast backtracking solver with MRV heuristic.
// Only uses value types — fully Sendable.
enum Solver {

    // Returns the first solution found, or nil.
    static func solve(_ grid: Grid) -> Grid? {
        var g = grid
        return backtrack(&g, limit: 1)
    }

    // Returns true iff the grid has exactly one solution.
    static func hasUniqueSolution(_ grid: Grid) -> Bool {
        var g = grid
        return countSolutions(&g, limit: 2) == 1
    }

    // Returns candidates for cell `index` given the current grid.
    static func candidates(in grid: Grid, at index: Int) -> [Int] {
        var mask = 0
        for j in boardPeers[index] {
            let d = grid[j]
            if d != 0 { mask |= (1 << d) }
        }
        return (1...9).filter { (mask >> $0) & 1 == 0 }
    }

    // MARK: - Private

    private static func maskForCell(_ grid: Grid, _ index: Int) -> Int {
        var mask = 0
        for j in boardPeers[index] {
            let d = grid[j]
            if d != 0 { mask |= (1 << d) }
        }
        return mask
    }

    // Tries to fill grid from the empty cells using backtracking.
    // Returns the solved grid or nil.
    private static func backtrack(_ grid: inout Grid, limit: Int) -> Grid? {
        // Find empty cell with fewest candidates (MRV).
        var bestIndex = -1
        var bestMask = 0
        var bestCount = 10
        for i in 0..<81 {
            if grid[i] != 0 { continue }
            let mask = maskForCell(grid, i)
            var c = 0
            for d in 1...9 where (mask >> d) & 1 == 0 { c += 1 }
            if c == 0 { return nil }  // dead end
            if c < bestCount {
                bestCount = c
                bestIndex = i
                bestMask = mask
                if bestCount == 1 { break }
            }
        }

        if bestIndex == -1 { return grid }  // all filled

        for d in 1...9 where (bestMask >> d) & 1 == 0 {
            grid[bestIndex] = d
            if let sol = backtrack(&grid, limit: limit) { return sol }
            grid[bestIndex] = 0
        }
        return nil
    }

    private static func countSolutions(_ grid: inout Grid, limit: Int) -> Int {
        var bestIndex = -1
        var bestMask = 0
        var bestCount = 10
        for i in 0..<81 {
            if grid[i] != 0 { continue }
            let mask = maskForCell(grid, i)
            var c = 0
            for d in 1...9 where (mask >> d) & 1 == 0 { c += 1 }
            if c == 0 { return 0 }
            if c < bestCount {
                bestCount = c
                bestIndex = i
                bestMask = mask
                if bestCount == 1 { break }
            }
        }
        if bestIndex == -1 { return 1 }

        var total = 0
        for d in 1...9 where (bestMask >> d) & 1 == 0 {
            grid[bestIndex] = d
            total += countSolutions(&grid, limit: limit)
            grid[bestIndex] = 0
            if total >= limit { break }
        }
        return total
    }
}
