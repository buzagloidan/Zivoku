import Foundation

enum AdaptiveDifficulty {
    private static let skillKey = "skillEMA"
    private static let driftKey = "difficultyDrift"
    private static let gamesKey = "totalGamesForDrift"

    // Returns the target difficulty for the next game based on recent performance.
    static func nextDifficulty(recentScores: [(score: Int, elapsed: Double, mistakes: Int, hints: Int)]) -> Difficulty {
        let targetScore = nextTargetScore(recentScores: recentScores)
        return Difficulty.from(score: targetScore)
    }

    static func nextTargetScore(recentScores: [(score: Int, elapsed: Double, mistakes: Int, hints: Int)]) -> Int {
        var skillEMA = UserDefaults.standard.double(forKey: skillKey)
        if skillEMA == 0 { skillEMA = 1.0 }

        let drift = min(UserDefaults.standard.double(forKey: driftKey), 0.5)

        if let last = recentScores.last {
            let diff = Difficulty.from(score: last.score)
            let ratio = last.elapsed / diff.expectedTime
            var perf = min(max(1.0 / max(ratio, 0.1), 0.5), 2.0)
            perf -= 0.05 * Double(last.mistakes)
            perf -= 0.10 * Double(last.hints)
            perf = min(max(perf, 0.3), 2.0)
            skillEMA = 0.7 * skillEMA + 0.3 * perf
        }

        // Base score mapped from skill: skill=1.0 → steady, skill>1.5 → sharp/fierce, skill<0.7 → gentle
        let base: Double
        switch skillEMA {
        case ..<0.6:  base = Double(Difficulty.gentle.targetScore)
        case ..<0.85: base = Double(Difficulty.calm.targetScore)
        case ..<1.2:  base = Double(Difficulty.steady.targetScore)
        case ..<1.6:  base = Double(Difficulty.sharp.targetScore)
        default:      base = Double(Difficulty.fierce.targetScore)
        }

        // Apply drift (slow upward ramp) and ±10% jitter.
        let jitter = Double.random(in: 0.90...1.10)
        let target = Int((base * (1.0 + drift) * jitter).rounded())
        return max(1, target)
    }

    static func recordCompletion(elapsed: Double, score: Int, mistakes: Int, hints: Int) {
        var skillEMA = UserDefaults.standard.double(forKey: skillKey)
        if skillEMA == 0 { skillEMA = 1.0 }

        let diff = Difficulty.from(score: score)
        let ratio = elapsed / diff.expectedTime
        var perf = min(max(1.0 / max(ratio, 0.1), 0.5), 2.0)
        perf -= 0.05 * Double(mistakes)
        perf -= 0.10 * Double(hints)
        perf = min(max(perf, 0.3), 2.0)

        skillEMA = 0.7 * skillEMA + 0.3 * perf
        UserDefaults.standard.set(skillEMA, forKey: skillKey)

        let games = UserDefaults.standard.integer(forKey: gamesKey) + 1
        UserDefaults.standard.set(games, forKey: gamesKey)

        let newDrift = min(Double(games) * 0.01, 0.5)
        UserDefaults.standard.set(newDrift, forKey: driftKey)
    }
}
