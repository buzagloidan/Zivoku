import SwiftData
import Foundation

@Model
final class ActiveGame {
    var givens: [Int]        // 81: 0 = empty
    var solution: [Int]      // 81: 1-9
    var playerValues: [Int]  // 81: 0 = empty
    // Pencil marks as flat [Int] length 729: cell i, digit d → pencilFlat[i*9+(d-1)]
    var pencilFlat: [Int]
    var elapsedSeconds: Double
    var mistakes: Int
    var hintsUsed: Int
    var difficultyScore: Int
    var difficulty: String
    var isDaily: Bool
    var dailyDate: String?
    var createdAt: Date

    init(puzzle: Puzzle, isDaily: Bool = false, dailyDate: String? = nil) {
        self.givens = puzzle.givens
        self.solution = puzzle.solution
        self.playerValues = Array(repeating: 0, count: 81)
        self.pencilFlat = Array(repeating: 0, count: 81 * 9)
        self.elapsedSeconds = 0
        self.mistakes = 0
        self.hintsUsed = 0
        self.difficultyScore = puzzle.difficultyScore
        self.difficulty = puzzle.difficulty.rawValue
        self.isDaily = isDaily
        self.dailyDate = dailyDate
        self.createdAt = Date()
    }

    var difficultyEnum: Difficulty {
        Difficulty(rawValue: difficulty) ?? .gentle
    }

    func pencilMarks(at index: Int) -> [Int] {
        (1...9).filter { pencilFlat[index * 9 + ($0 - 1)] == 1 }
    }

    func setPencilMark(_ digit: Int, at index: Int, on: Bool) {
        pencilFlat[index * 9 + (digit - 1)] = on ? 1 : 0
    }
}
