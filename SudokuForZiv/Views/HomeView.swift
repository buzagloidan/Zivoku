import SwiftUI
import SwiftData

struct HomeView: View {
    let onStartGame: (Puzzle, Bool, String?) -> Void
    let onContinue: () -> Void

    @Query private var activeGames: [ActiveGame]
    @Query private var dailyRecords: [DailyRecord]

    @State private var showStats = false
    @State private var isGenerating = false
    @State private var isDailyGenerating = false
    @State private var cachedPuzzle: Puzzle? = nil

    private static let dateStyle = Date.FormatStyle(date: .abbreviated, time: .omitted)

    private var todayString: String { DailyRecord.dateString(for: Date()) }
    private var dailyDone: Bool { dailyRecords.first { $0.dateString == todayString }?.completed == true }
    private var hasSavedGame: Bool { !activeGames.isEmpty }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    headerSection
                    if hasSavedGame { continueCard }
                    newGameCard
                    dailyCard
                    statsButton
                }
                .padding(.horizontal, 24)
                .padding(.top, 48)
                .padding(.bottom, 48)
            }
        }
        .sheet(isPresented: $showStats) { StatsView() }
        .onAppear { preGenerate() }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hi Ziv 💗")
                    .font(Theme.rounded(36, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Piggy and Maple saved your seat.")
                    .font(Theme.rounded(17))
                    .foregroundStyle(Theme.inkFaint)
            }

            Spacer(minLength: 0)

            ZStack(alignment: .bottom) {
                AnimatedCompanionSprite(
                    names: CompanionSprites.maple,
                    height: 82,
                    interval: 0.55,
                    flipped: true
                )
                .offset(x: 26, y: 6)

                AnimatedCompanionSprite(
                    names: CompanionSprites.piggy,
                    height: 70,
                    interval: 0.48
                )
                .offset(x: -28, y: 10)
            }
            .frame(width: 128, height: 104)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var continueCard: some View {
        Button(action: onContinue) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Continue")
                        .font(Theme.rounded(17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    if let game = activeGames.first {
                        Text(game.difficultyEnum.displayName)
                            .font(Theme.rounded(13))
                            .foregroundStyle(Theme.primarySoft)
                    }
                }
                Spacer()
                ZStack(alignment: .bottomTrailing) {
                    CompanionSprite(name: "piggy_02", height: 54)
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.primarySoft)
                        .background(Theme.surface, in: Circle())
                        .offset(x: 4, y: 2)
                }
            }
            .padding(20)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: Theme.ink.opacity(0.07), radius: 6, y: 2)
        }
    }

    private var newGameCard: some View {
        Button {
            startNewGame()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Game")
                        .font(Theme.rounded(20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Adapts to your skill")
                        .font(Theme.rounded(13))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                } else {
                    CompanionSprite(name: "piggy_08", height: 68)
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.primary)
                                .frame(width: 28, height: 28)
                                .background(.white.opacity(0.9), in: Circle())
                        }
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: [Theme.primary, Theme.primarySoft],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
            )
            .shadow(color: Theme.primary.opacity(0.35), radius: 12, y: 4)
        }
        .disabled(isGenerating)
        .accessibilityIdentifier("New Game")
    }

    private var dailyCard: some View {
        Button {
            startDailyPuzzle()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Puzzle")
                        .font(Theme.rounded(17, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(dailyDone ? "Completed today ✓" : formattedToday)
                        .font(Theme.rounded(13))
                        .foregroundStyle(dailyDone ? Theme.primary : Theme.inkFaint)
                }
                Spacer()
                if isDailyGenerating {
                    ProgressView().tint(Theme.primary)
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        CompanionSprite(name: dailyDone ? "maple_12" : "maple_05", height: 58)
                        Image(systemName: dailyDone ? "checkmark.seal.fill" : "calendar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(dailyDone ? Theme.primary : Theme.primarySoft)
                            .background(Theme.surface, in: Circle())
                            .offset(x: 3, y: 2)
                    }
                }
            }
            .padding(20)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: Theme.ink.opacity(0.07), radius: 6, y: 2)
        }
        .disabled(isDailyGenerating)
        .accessibilityIdentifier("Daily Puzzle")
    }

    private var statsButton: some View {
        Button { showStats = true } label: {
            HStack(spacing: 10) {
                CompanionSprite(name: "maple_09", height: 34)
                Label("Statistics", systemImage: "chart.bar.fill")
                    .font(Theme.rounded(15, weight: .medium))
                Spacer()
            }
            .foregroundStyle(Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .shadow(color: Theme.ink.opacity(0.05), radius: 4, y: 1)
        }
        .accessibilityIdentifier("Statistics")
    }

    // MARK: - Helpers

    private var formattedToday: String {
        Date().formatted(Self.dateStyle)
    }

    private func preGenerate() {
        guard cachedPuzzle == nil else { return }
        Task.detached(priority: .background) {
            let diff = await MainActor.run {
                Difficulty.from(score: AdaptiveDifficulty.nextTargetScore(recentScores: []))
            }
            let puzzle = Generator.generate(difficulty: diff)
            await MainActor.run { cachedPuzzle = puzzle }
        }
    }

    private func startNewGame() {
        isGenerating = true
        Task {
            let diff = Difficulty.from(score: AdaptiveDifficulty.nextTargetScore(recentScores: []))
            if let cached = cachedPuzzle {
                cachedPuzzle = nil
                isGenerating = false
                onStartGame(cached, false, nil)
                preGenerate()
                return
            }
            let puzzle = await Task.detached(priority: .userInitiated) {
                Generator.generate(difficulty: diff)
            }.value
            isGenerating = false
            onStartGame(puzzle, false, nil)
            preGenerate()
        }
    }

    private func startDailyPuzzle() {
        isDailyGenerating = true
        let today = todayString
        Task {
            let puzzle = await Task.detached(priority: .userInitiated) {
                Generator.daily(date: Date())
            }.value
            isDailyGenerating = false
            onStartGame(puzzle, true, today)
        }
    }
}
