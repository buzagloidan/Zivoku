import SwiftUI

struct WinView: View {
    let viewModel: GameViewModel
    let onPlayAnother: () -> Void
    let onGoHome: () -> Void

    private static let messages = [
        "You're brilliant, Ziv 💗",
        "That's my girl! 💕",
        "Look at you go, Ziv ✨",
        "Solving puzzles like a pro 💗",
        "Ziv + Zivoku = unbeatable 🌸",
        "You make it look easy 💖",
        "Pure genius, Ziv! 💗",
    ]

    @State private var message = messages.randomElement()!
    @State private var showConfetti = false

    private var timeString: String {
        let t = Int(viewModel.elapsedSeconds)
        let m = t / 60, s = t % 60
        return String(format: "%d:%02d", m, s)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                celebrationScene

                VStack(spacing: 8) {
                    Text(message)
                        .font(Theme.rounded(26, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .multilineTextAlignment(.center)

                    Text(viewModel.difficulty.displayName)
                        .font(Theme.rounded(15, weight: .medium))
                        .foregroundStyle(Theme.primarySoft)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Theme.primarySoft.opacity(0.15), in: Capsule())
                }

                // Stats row
                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 24) { statsRow }
                } else {
                    statsRow
                }

                Spacer()

                if #available(iOS 26, *) {
                    GlassEffectContainer(spacing: 12) { winButtons }
                } else {
                    winButtons
                }
            }
            .padding(.horizontal, 24)
        }
        .onAppear { showConfetti = true }
    }

    private var celebrationScene: some View {
        ZStack {
            HStack(alignment: .bottom, spacing: 14) {
                CompanionSprite(name: "maple_11", height: 104, flipped: true, rotation: .degrees(-8))
                    .offset(y: showConfetti ? 0 : 18)
                CompanionSprite(name: "piggy_08", height: 96, rotation: .degrees(4))
                    .offset(y: showConfetti ? 0 : 18)
            }
            .scaleEffect(showConfetti ? 1 : 0.82)
            .animation(.spring(response: 0.5, dampingFraction: 0.65), value: showConfetti)

            HStack(spacing: 20) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "heart.fill")
                        .font(.system(size: i.isMultiple(of: 2) ? 20 : 16))
                        .foregroundStyle(Theme.primary)
                        .scaleEffect(showConfetti ? 1 : 0.3)
                        .opacity(showConfetti ? 1 : 0)
                        .offset(y: showConfetti ? -64 - CGFloat(i % 2) * 16 : -20)
                        .animation(
                            .spring(response: 0.45, dampingFraction: 0.6)
                                .delay(Double(i) * 0.07),
                            value: showConfetti
                        )
                }
            }
        }
        .frame(height: 130)
    }

    private var statsRow: some View {
        HStack(spacing: 24) {
            statChip(icon: "clock", value: timeString, label: "Time")
            if viewModel.mistakes > 0 {
                statChip(icon: "exclamationmark.circle", value: String(viewModel.mistakes), label: "Mistakes")
            }
            if viewModel.hintsRemaining < 3 {
                statChip(icon: "lightbulb", value: String(3 - viewModel.hintsRemaining), label: "Hints")
            }
        }
    }

    private var winButtons: some View {
        VStack(spacing: 12) {
            Button(action: onPlayAnother) {
                Text("Play Another")
                    .font(Theme.rounded(17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .themedControlSurface(
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius),
                        tint: Theme.primary.opacity(0.28),
                        fallbackFill: Theme.primary,
                        shadowOpacity: 0.12
                    )
            }
            Button(action: onGoHome) {
                Text("Home")
                    .font(Theme.rounded(17, weight: .medium))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .themedControlSurface(in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
    }

    private func statChip(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Theme.primary)
            Text(value)
                .font(Theme.rounded(20, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(12))
                .foregroundStyle(Theme.inkFaint)
        }
        .frame(minWidth: 70)
        .padding(.vertical, 14)
        .padding(.horizontal, 10)
        .themedControlSurface(in: RoundedRectangle(cornerRadius: 12))
    }
}
