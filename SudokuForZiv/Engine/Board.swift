// Engine types shared across Solver, Generator, HumanSolver.

typealias Grid = [Int]  // 81 ints, 0 = empty, 1-9 = digit

// Precomputed at launch, never mutated.
let boardPeers: [[Int]] = {
    (0..<81).map { i in
        let r = i / 9, c = i % 9, b = (r / 3) * 3 + (c / 3)
        var result = [Int]()
        result.reserveCapacity(20)
        for j in 0..<81 where j != i {
            let rj = j / 9, cj = j % 9, bj = (rj / 3) * 3 + (cj / 3)
            if rj == r || cj == c || bj == b { result.append(j) }
        }
        return result
    }
}()

let boardRows:   [[Int]] = (0..<9).map { r in (0..<9).map { r * 9 + $0 } }
let boardCols:   [[Int]] = (0..<9).map { c in (0..<9).map { $0 * 9 + c } }
let boardBoxes:  [[Int]] = (0..<9).map { b in
    let br = (b / 3) * 3, bc = (b % 3) * 3
    return (0..<3).flatMap { r in (0..<3).map { c in (br + r) * 9 + (bc + c) } }
}
let boardGroups: [[Int]] = boardRows + boardCols + boardBoxes

// Peer sets as Sets for O(1) membership test (used by HumanSolver/XY-Wing).
let boardPeerSets: [Set<Int>] = boardPeers.map { Set($0) }

// Box index for a cell index.
@inline(__always) func boxIndex(_ i: Int) -> Int { (i / 9 / 3) * 3 + (i % 9 / 3) }
