import Foundation

enum Difficulty: String, CaseIterable, Sendable, Codable, Hashable {
    case gentle, calm, steady, sharp, fierce

    static func from(score: Int) -> Difficulty {
        switch score {
        case 0...30:   return .gentle
        case 31...80:  return .calm
        case 81...200: return .steady
        case 201...500: return .sharp
        default:       return .fierce
        }
    }

    var displayName: String { rawValue.capitalized }

    // Mid-point target score used when generating for this bucket.
    var targetScore: Int {
        switch self {
        case .gentle: return 15
        case .calm:   return 55
        case .steady: return 140
        case .sharp:  return 350
        case .fierce: return 700
        }
    }

    // Expected solve time (seconds) — used by AdaptiveDifficulty.
    var expectedTime: Double {
        switch self {
        case .gentle: return 300
        case .calm:   return 600
        case .steady: return 900
        case .sharp:  return 1500
        case .fierce: return 2400
        }
    }

    // Rough target empty-cell count to aim for during hole digging.
    var targetEmptyCells: Int {
        switch self {
        case .gentle: return 33
        case .calm:   return 40
        case .steady: return 49
        case .sharp:  return 55
        case .fierce: return 62
        }
    }
}
