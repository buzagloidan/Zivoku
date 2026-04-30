import Foundation

struct Puzzle: Sendable {
    var givens: Grid        // 81 ints, 0 = empty
    var solution: Grid      // 81 ints, 1-9 everywhere
    var difficultyScore: Int
    var difficulty: Difficulty

    // 81-char string representation of givens ("0" = empty).
    var fingerprint: String {
        givens.map { $0 == 0 ? "0" : String($0) }.joined()
    }
}
