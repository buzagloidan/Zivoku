import XCTest
@testable import SudokuForZiv

final class SolverTests: XCTestCase {

    // A well-known easy puzzle with a unique solution.
    private let easyPuzzle: Grid = Array(
        "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
            .map { $0 == "0" ? 0 : Int(String($0))! }
    )
    private let easySolution: Grid = Array(
        "483921657967345821251876493548132976729564138136798245372689514814253769695417382"
            .map { Int(String($0))! }
    )

    func test_solve_returnsCorrectSolution() {
        let result = Solver.solve(easyPuzzle)
        XCTAssertNotNil(result)
        XCTAssertEqual(result, easySolution)
    }

    func test_uniqueSolution_trueForUniquePuzzle() {
        XCTAssertTrue(Solver.hasUniqueSolution(easyPuzzle))
    }

    func test_uniqueSolution_falseForMultiSolution() {
        XCTAssertFalse(Solver.hasUniqueSolution(Grid(repeating: 0, count: 81)))
    }

    func test_solve_emptyBoardHasSolution() {
        let empty = Grid(repeating: 0, count: 81)
        let result = Solver.solve(empty)
        XCTAssertNotNil(result)
        // Verify the result is valid.
        if let s = result {
            XCTAssertTrue(isValidSolution(s))
        }
    }

    func test_candidates_excludesPeers() {
        var grid = Grid(repeating: 0, count: 81)
        grid[0] = 5  // row 0, col 0
        let cands = Solver.candidates(in: grid, at: 1)  // row 0, col 1
        XCTAssertFalse(cands.contains(5))
    }

    // MARK: - Helpers

    private func isValidSolution(_ grid: Grid) -> Bool {
        for group in boardGroups {
            let vals = group.map { grid[$0] }
            if Set(vals) != Set(1...9) { return false }
        }
        return true
    }
}
