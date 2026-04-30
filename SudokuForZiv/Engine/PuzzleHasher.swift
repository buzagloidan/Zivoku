import Foundation
import CryptoKit

enum PuzzleHasher {
    private static let key = "seenPuzzleHashes"
    private static let maxHistory = 20

    // Canonical hash: relabel digits in scan order so first digit = 1, second new digit = 2, etc.
    static func hash(_ givens: Grid) -> String {
        var map = [Int: Int]()
        var next = 1
        var canonical = [Int](repeating: 0, count: 81)
        for i in 0..<81 {
            let d = givens[i]
            if d == 0 { canonical[i] = 0; continue }
            if let mapped = map[d] {
                canonical[i] = mapped
            } else {
                map[d] = next
                canonical[i] = next
                next += 1
            }
        }
        let str = canonical.map { String($0) }.joined()
        let digest = SHA256.hash(data: Data(str.utf8))
        return digest.compactMap { String(format: "%02x", $0) }.joined().prefix(16).description
    }

    static func wasSeen(_ hash: String) -> Bool {
        history().contains(hash)
    }

    static func markSeen(_ hash: String) {
        var h = history()
        h.append(hash)
        if h.count > maxHistory { h.removeFirst(h.count - maxHistory) }
        UserDefaults.standard.set(h, forKey: key)
    }

    private static func history() -> [String] {
        UserDefaults.standard.stringArray(forKey: key) ?? []
    }
}
