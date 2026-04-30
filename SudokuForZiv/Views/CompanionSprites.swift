import SwiftUI

enum CompanionSprites {
    static let maple = [
        "maple_01", "maple_02", "maple_03", "maple_04",
        "maple_05", "maple_06", "maple_07", "maple_08",
        "maple_09", "maple_10", "maple_11", "maple_12",
    ]

    static let piggy = [
        "piggy_01", "piggy_02", "piggy_03", "piggy_04",
        "piggy_05", "piggy_06", "piggy_07", "piggy_08",
        "piggy_09", "piggy_10", "piggy_11",
    ]
}

struct CompanionSprite: View {
    let name: String
    var height: CGFloat
    var flipped = false
    var rotation: Angle = .zero

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .scaleEffect(x: flipped ? -1 : 1, y: 1)
            .rotationEffect(rotation)
            .shadow(color: Theme.ink.opacity(0.12), radius: 5, y: 3)
            .accessibilityHidden(true)
    }
}

struct AnimatedCompanionSprite: View {
    let names: [String]
    var height: CGFloat
    var interval: TimeInterval = 0.5
    var flipped = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: interval)) { context in
            let index = reduceMotion ? 0 : frameIndex(for: context.date)
            CompanionSprite(name: names[index], height: height, flipped: flipped)
        }
    }

    private func frameIndex(for date: Date) -> Int {
        guard !names.isEmpty else { return 0 }
        return Int(date.timeIntervalSinceReferenceDate / interval) % names.count
    }
}
