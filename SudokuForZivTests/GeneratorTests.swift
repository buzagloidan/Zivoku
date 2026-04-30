import XCTest
@testable import SudokuForZiv

final class GeneratorTests: XCTestCase {

    func test_fillRandom_producesValidGrid() {
        var rng = SplitMix64(seed: 42)
        let grid = Generator.fillRandom(rng: &rng)
        XCTAssertEqual(grid.count, 81)
        for group in boardGroups {
            let vals = group.map { grid[$0] }
            XCTAssertEqual(Set(vals), Set(1...9), "Group \(group) is not valid")
        }
    }

    func test_fillRandom_isDeterministicWithSameSeed() {
        var rng1 = SplitMix64(seed: 123)
        var rng2 = SplitMix64(seed: 123)
        let g1 = Generator.fillRandom(rng: &rng1)
        let g2 = Generator.fillRandom(rng: &rng2)
        XCTAssertEqual(g1, g2)
    }

    func test_generate_producesValidPuzzles() {
        // Test 5 puzzles to keep test time reasonable.
        for diff in [Difficulty.gentle, .calm, .steady] {
            let puzzle = Generator.generate(difficulty: diff)
            XCTAssertEqual(puzzle.givens.count, 81)
            XCTAssertEqual(puzzle.solution.count, 81)
            // Givens must be a subset of solution.
            for i in 0..<81 where puzzle.givens[i] != 0 {
                XCTAssertEqual(puzzle.givens[i], puzzle.solution[i], "Given at \(i) doesn't match solution")
            }
            // Puzzle has unique solution.
            XCTAssertTrue(Solver.hasUniqueSolution(puzzle.givens), "Puzzle for \(diff) has non-unique solution")
        }
    }

    func test_daily_isDeterministic() {
        let date = Date(timeIntervalSince1970: 1_746_000_000)  // fixed date
        let p1 = Generator.daily(date: date)
        let p2 = Generator.daily(date: date)
        XCTAssertEqual(p1.givens, p2.givens)
    }

    func test_humanSolverCanSolveGeneratedPuzzles() {
        for _ in 0..<3 {
            let puzzle = Generator.generate(difficulty: .gentle)
            let result = HumanSolver.solve(puzzle.givens)
            XCTAssertTrue(result.solved, "HumanSolver could not solve a gentle puzzle")
            XCTAssertFalse(result.requiresGuessing)
        }
    }
}
