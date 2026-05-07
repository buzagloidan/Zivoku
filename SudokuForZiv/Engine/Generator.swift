import Foundation

// SplitMix64 — fast, seedable, passes BigCrush.
struct SplitMix64: RandomNumberGenerator, Sendable {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

enum Generator {

    // Generate a random fully-solved grid.
    static func fillRandom<R: RandomNumberGenerator>(rng: inout R) -> Grid {
        var grid = Grid(repeating: 0, count: 81)
        let ok = fill(&grid, index: 0, rng: &rng)
        assert(ok, "fillRandom failed — should always succeed")
        return grid
    }

    // Dig holes in a solved grid targeting the given bucket.
    // Returns a Puzzle or nil if the target score can't be reached on this seed.
    static func dig(solution: Grid, difficulty: Difficulty, rng: inout some RandomNumberGenerator) -> Puzzle? {
        let target = difficulty.targetEmptyCells
        var givens = solution  // start fully filled

        // Build symmetric cell pairs (180° rotation) for aesthetics.
        let indices = Array(0..<81).shuffled(using: &rng)

        for idx in indices {
            let sym = 80 - idx
            guard givens[idx] != 0 else { continue }

            // Try removing both idx and its symmetric partner.
            let saved = (givens[idx], givens[sym])
            givens[idx] = 0
            if sym != idx { givens[sym] = 0 }

            if !Solver.hasUniqueSolution(givens) {
                givens[idx] = saved.0
                givens[sym] = saved.1
            }

            let emptyCells = givens.filter { $0 == 0 }.count
            if emptyCells >= target { break }
        }

        // Rate the resulting puzzle.
        let result = HumanSolver.solve(givens)
        guard !result.requiresGuessing else { return nil }

        let score = result.totalScore
        let diff = Difficulty.from(score: score)

        // Accept if the bucket matches (allow adjacent buckets too to avoid infinite retry).
        let buckets = Difficulty.allCases
        let targetIdx = buckets.firstIndex(of: difficulty) ?? 0
        let diffIdx   = buckets.firstIndex(of: diff) ?? 0
        guard abs(diffIdx - targetIdx) <= 1 else { return nil }

        return Puzzle(givens: givens, solution: solution, difficultyScore: score, difficulty: diff)
    }

    // High-level: generate a puzzle of the given difficulty, retrying until success.
    static func generate(difficulty: Difficulty) -> Puzzle {
        var rng = SplitMix64(seed: UInt64(bitPattern: Int64(Date().timeIntervalSince1970 * 1000)))
        for _ in 0..<30 {
            let solution = fillRandom(rng: &rng)
            if let puzzle = dig(solution: solution, difficulty: difficulty, rng: &rng) {
                return puzzle
            }
        }
        // Fallback: return a gentle puzzle rather than crashing.
        let solution = fillRandom(rng: &rng)
        var givens = solution
        for i in (0..<81).shuffled(using: &rng).prefix(30) { givens[i] = 0 }
        let score = HumanSolver.solve(givens).totalScore
        return Puzzle(givens: givens, solution: solution, difficultyScore: score, difficulty: .from(score: score))
    }

    // Deterministic daily puzzle from a date.
    static func daily(date: Date) -> Puzzle {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day, .weekday], from: date)
        let y = comps.year ?? 2025
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        let seed = UInt64(y * 10000 + m * 100 + d)

        // Rotate difficulty by day-of-week: Mon=gentle, Tue=calm, … Sun=fierce
        let weekday = (comps.weekday ?? 1)  // 1=Sun, 2=Mon, …, 7=Sat
        let difficulties: [Difficulty] = [.fierce, .gentle, .calm, .steady, .sharp, .fierce, .steady]
        let diff = difficulties[(weekday - 1) % difficulties.count]

        var rng = SplitMix64(seed: seed)
        for _ in 0..<30 {
            let solution = fillRandom(rng: &rng)
            if let puzzle = dig(solution: solution, difficulty: diff, rng: &rng) {
                return puzzle
            }
        }
        // Deterministic fallback: keep the daily puzzle playable even if the
        // requested bucket cannot be generated on this seed.
        return fallbackDaily(seed: seed, difficulty: diff)
    }

    // MARK: - Private

    private static func fallbackDaily(seed: UInt64, difficulty: Difficulty) -> Puzzle {
        var rng = SplitMix64(seed: seed &+ 9999)
        let solution = fillRandom(rng: &rng)
        var givens = solution
        let target = min(difficulty.targetEmptyCells, Difficulty.calm.targetEmptyCells)
        var score = 0

        for idx in Array(0..<81).shuffled(using: &rng) {
            let saved = givens[idx]
            givens[idx] = 0

            guard Solver.hasUniqueSolution(givens) else {
                givens[idx] = saved
                continue
            }

            let result = HumanSolver.solve(givens)
            guard !result.requiresGuessing else {
                givens[idx] = saved
                continue
            }

            score = result.totalScore
            if givens.filter({ $0 == 0 }).count >= target { break }
        }

        if !givens.contains(0) {
            givens[0] = 0
            score = HumanSolver.solve(givens).totalScore
        }

        let ratedDifficulty = Difficulty.from(score: score)
        return Puzzle(givens: givens, solution: solution, difficultyScore: score, difficulty: ratedDifficulty)
    }

    private static func fill<R: RandomNumberGenerator>(_ grid: inout Grid, index: Int, rng: inout R) -> Bool {
        if index == 81 { return true }
        var digits = Array(1...9)
        digits.shuffle(using: &rng)
        for d in digits {
            if isValid(grid, index: index, digit: d) {
                grid[index] = d
                if fill(&grid, index: index + 1, rng: &rng) { return true }
                grid[index] = 0
            }
        }
        return false
    }

    private static func isValid(_ grid: Grid, index: Int, digit: Int) -> Bool {
        for j in boardPeers[index] where grid[j] == digit { return false }
        return true
    }
}
