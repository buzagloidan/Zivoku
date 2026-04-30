import XCTest
@testable import SudokuForZiv

final class HumanSolverTests: XCTestCase {

    // Puzzle solvable with naked/hidden singles only.
    private let gentlePuzzle: Grid = Array(
        "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
            .map { $0 == "0" ? 0 : Int(String($0))! }
    )

    func test_solve_gentlePuzzle() {
        let result = HumanSolver.solve(gentlePuzzle)
        XCTAssertTrue(result.solved)
        XCTAssertFalse(result.requiresGuessing)
        XCTAssertGreaterThan(result.totalScore, 0)
    }

    func test_solve_usesNakedSingle() {
        let result = HumanSolver.solve(gentlePuzzle)
        // Gentle puzzles should use naked singles.
        XCTAssertNotNil(result.techniquesUsed[.nakedSingle])
    }

    func test_solve_emptyPuzzleRequiresGuessing() {
        let empty = Grid(repeating: 0, count: 81)
        let result = HumanSolver.solve(empty)
        XCTAssertFalse(result.solved)
        XCTAssertTrue(result.requiresGuessing)
    }

    func test_solve_solvedPuzzleImmediatelyComplete() {
        var rng = SplitMix64(seed: 999)
        let solution = Generator.fillRandom(rng: &rng)
        let result = HumanSolver.solve(solution)
        XCTAssertTrue(result.solved)
        XCTAssertFalse(result.requiresGuessing)
        XCTAssertEqual(result.totalScore, 0)
    }

    func test_difficultPuzzleHasHigherScore() {
        // Score for an easy puzzle should be lower than for a harder one.
        let easyResult = HumanSolver.solve(gentlePuzzle)
        let fiercePuzzle = Generator.generate(difficulty: .sharp)
        let hardResult = HumanSolver.solve(fiercePuzzle.givens)
        XCTAssertGreaterThan(hardResult.totalScore, easyResult.totalScore)
    }
}
