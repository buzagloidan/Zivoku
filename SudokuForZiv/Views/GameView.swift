import SwiftUI

struct GameView: View {
    @Bindable var viewModel: GameViewModel
    let onExit: () -> Void

    @State private var showWin = false
    @State private var showPause = false

    private var timerString: String {
        let t = Int(viewModel.elapsedSeconds)
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if showWin {
                WinView(
                    viewModel: viewModel,
                    onPlayAnother: { onExit() },
                    onGoHome: { onExit() }
                )
                .transition(.opacity)
            } else {
                mainContent
                    .blur(radius: viewModel.isPaused ? 20 : 0)
                    .overlay {
                        if viewModel.isPaused {
                            pauseOverlay
                        }
                    }
            }
        }
        .onChange(of: viewModel.isComplete) { _, complete in
            if complete {
                withAnimation(.easeInOut(duration: 0.4).delay(0.6)) {
                    showWin = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showMistakeTooMany) {
            MistakeAlertView(onRetry: {
                viewModel.showMistakeTooMany = false
            }, onExit: {
                viewModel.showMistakeTooMany = false
                onExit()
            })
            .presentationDetents([.height(260)])
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                headerButton(systemName: "pause") {
                    viewModel.pause()
                    showPause = true
                }
                Spacer()
                VStack(spacing: 0) {
                    Text(viewModel.difficulty.displayName)
                        .font(Theme.rounded(12, weight: .medium))
                        .foregroundStyle(Theme.primarySoft)
                    Text(timerString)
                        .font(Theme.rounded(22, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: timerString)
                }
                Spacer()
                headerButton(systemName: "xmark", action: onExit)
                    .accessibilityIdentifier("Back")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            companionStatus
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

            // Board
            BoardView(viewModel: viewModel)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

            Spacer(minLength: 8)

            // Toolbar
            ToolbarView(viewModel: viewModel)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)

            // Number pad
            NumberPadView(viewModel: viewModel)
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
        }
    }

    private var companionStatus: some View {
        HStack(spacing: 10) {
            CompanionSprite(name: companionSpriteName, height: 40)

            VStack(alignment: .leading, spacing: 1) {
                Text(companionTitle)
                    .font(Theme.rounded(13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(companionSubtitle)
                    .font(Theme.rounded(11))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 4) {
                ForEach(0..<3) { i in
                    Image(systemName: i < viewModel.mistakes ? "xmark.circle.fill" : "circle")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(i < viewModel.mistakes ? Theme.mistake : Theme.inkFaint)
                }
            }
            .accessibilityLabel("\(viewModel.mistakes) mistakes")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Theme.surface.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: Theme.ink.opacity(0.05), radius: 4, y: 1)
    }

    private var companionSpriteName: String {
        if viewModel.mistakes >= 2 { return "piggy_09" }
        if viewModel.isNotesMode { return "maple_07" }
        if viewModel.hintsRemaining == 0 { return "maple_12" }
        return viewModel.mistakes == 0 ? "piggy_05" : "piggy_06"
    }

    private var companionTitle: String {
        if viewModel.mistakes >= 2 { return "Careful now" }
        if viewModel.isNotesMode { return "Maple is watching the notes" }
        if viewModel.hintsRemaining == 0 { return "No hints left" }
        return viewModel.mistakes == 0 ? "Piggy is cheering" : "Still steady"
    }

    private var companionSubtitle: String {
        if viewModel.mistakes >= 2 { return "One clean move at a time" }
        if viewModel.isNotesMode { return "Tiny marks, big plans" }
        if viewModel.hintsRemaining == 1 { return "1 hint left" }
        return "\(viewModel.hintsRemaining) hints left"
    }

    private var pauseOverlay: some View {
        VStack(spacing: 20) {
            CompanionSprite(name: "maple_12", height: 82)
            Text("Paused")
                .font(Theme.rounded(28, weight: .bold))
                .foregroundStyle(Theme.ink)
            Button {
                viewModel.resume()
                showPause = false
            } label: {
                Label("Resume", systemImage: "play.fill")
                    .font(Theme.rounded(17, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Theme.primary, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }

    private func headerButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .frame(width: 42, height: 42)
                .themedControlSurface(
                    in: Circle(),
                    fallbackFill: Theme.surface.opacity(0.72)
                )
        }
        .buttonStyle(.plain)
    }
}

// Shown after 3 mistakes.
private struct MistakeAlertView: View {
    let onRetry: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            CompanionSprite(name: "piggy_09", height: 76)
            Text("3 Mistakes 😅")
                .font(Theme.rounded(22, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Keep going or start fresh?")
                .font(Theme.rounded(15))
                .foregroundStyle(Theme.inkFaint)
            HStack(spacing: 12) {
                Button(action: onRetry) {
                    Text("Keep Going")
                        .font(Theme.rounded(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
                }
                Button(action: onExit) {
                    Text("New Game")
                        .font(Theme.rounded(15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.primary, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(28)
    }
}
