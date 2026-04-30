import SwiftData
import Foundation

@Model
final class CompletedGame {
    var completedAt: Date
    var elapsedSeconds: Double
    var mistakes: Int
    var hintsUsed: Int
    var difficultyScore: Int
    var difficulty: String
    var isDaily: Bool
    var dailyDate: String?

    init(from game: ActiveGame) {
        self.completedAt = Date()
        self.elapsedSeconds = game.elapsedSeconds
        self.mistakes = game.mistakes
        self.hintsUsed = game.hintsUsed
        self.difficultyScore = game.difficultyScore
        self.difficulty = game.difficulty
        self.isDaily = game.isDaily
        self.dailyDate = game.dailyDate
    }

    var difficultyEnum: Difficulty {
        Difficulty(rawValue: difficulty) ?? .gentle
    }
}
