import Foundation

enum DifficultyRater {
    static func rate(_ grid: Grid) -> (score: Int, difficulty: Difficulty) {
        let result = HumanSolver.solve(grid)
        return (result.totalScore, Difficulty.from(score: result.totalScore))
    }
}
