import XCTest
@testable import SudokuForZiv

final class DifficultyRaterTests: XCTestCase {

    private let knownEasy: Grid = Array(
        "003020600900305001001806400008102900700000008006708200002609500800203009005010300"
            .map { $0 == "0" ? 0 : Int(String($0))! }
    )

    func test_easyPuzzleScoresGentle() {
        let (score, diff) = DifficultyRater.rate(knownEasy)
        XCTAssertLessThanOrEqual(score, 80, "Easy puzzle should score ≤ 80, got \(score)")
        XCTAssertTrue(diff == .gentle || diff == .calm, "Easy puzzle should be Gentle or Calm, got \(diff)")
    }

    func test_difficultyFromScore_buckets() {
        XCTAssertEqual(Difficulty.from(score: 0),   .gentle)
        XCTAssertEqual(Difficulty.from(score: 30),  .gentle)
        XCTAssertEqual(Difficulty.from(score: 31),  .calm)
        XCTAssertEqual(Difficulty.from(score: 80),  .calm)
        XCTAssertEqual(Difficulty.from(score: 81),  .steady)
        XCTAssertEqual(Difficulty.from(score: 200), .steady)
        XCTAssertEqual(Difficulty.from(score: 201), .sharp)
        XCTAssertEqual(Difficulty.from(score: 500), .sharp)
        XCTAssertEqual(Difficulty.from(score: 501), .fierce)
        XCTAssertEqual(Difficulty.from(score: 999), .fierce)
    }

    func test_generatedGentlePuzzleRatesAsGentle() {
        let puzzle = Generator.generate(difficulty: .gentle)
        let (_, diff) = DifficultyRater.rate(puzzle.givens)
        // Accept gentle or calm — adjacent buckets are fine due to jitter.
        XCTAssertTrue(diff == .gentle || diff == .calm,
                      "Generated gentle puzzle rated as \(diff)")
    }
}
