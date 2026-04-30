import SwiftUI
import SwiftData

@Observable
@MainActor
final class GameViewModel {

    // MARK: - Puzzle state
    var givens: [Int] = []
    var solution: [Int] = []
    var playerValues: [Int] = Array(repeating: 0, count: 81)
    var pencilMarks: [[Int]] = Array(repeating: [], count: 81)  // 81 sorted digit arrays

    // MARK: - Interaction
    var selectedIndex: Int? = nil
    var isNotesMode: Bool = false

    // MARK: - Progress
    var mistakes: Int = 0
    var hintsRemaining: Int = 3
    var elapsedSeconds: Double = 0
    var isPaused: Bool = false
    var isComplete: Bool = false
    var showMistakeTooMany: Bool = false

    // MARK: - Metadata
    var difficultyScore: Int = 0
    var difficulty: Difficulty = .gentle
    var isDaily: Bool = false
    var dailyDate: String? = nil

    // MARK: - Undo
    private struct UndoState {
        var values: [Int]
        var pencilMarks: [[Int]]
    }
    private var undoStack: [UndoState] = []
    private let maxUndoDepth = 50

    // MARK: - Timer
    private var timerTask: Task<Void, Never>? = nil

    // MARK: - Persistence
    private weak var modelContext: ModelContext?

    // MARK: - Setup

    func newGame(puzzle: Puzzle, isDaily: Bool, dailyDate: String?, context: ModelContext) {
        stopTimer()
        self.givens = puzzle.givens
        self.solution = puzzle.solution
        self.playerValues = Array(repeating: 0, count: 81)
        self.pencilMarks = Array(repeating: [], count: 81)
        self.difficultyScore = puzzle.difficultyScore
        self.difficulty = puzzle.difficulty
        self.isDaily = isDaily
        self.dailyDate = dailyDate
        self.mistakes = 0
        self.hintsRemaining = 3
        self.elapsedSeconds = 0
        self.isPaused = false
        self.isComplete = false
        self.selectedIndex = nil
        self.undoStack = []
        self.modelContext = context

        // Delete any old active game and save this new one.
        let existingGames = (try? context.fetch(FetchDescriptor<ActiveGame>())) ?? []
        for g in existingGames { context.delete(g) }
        let newRecord = ActiveGame(puzzle: puzzle, isDaily: isDaily, dailyDate: dailyDate)
        context.insert(newRecord)
        try? context.save()

        startTimer()
    }

    func load(from game: ActiveGame, context: ModelContext) {
        stopTimer()
        self.givens = game.givens
        self.solution = game.solution
        self.playerValues = game.playerValues
        self.pencilMarks = (0..<81).map { game.pencilMarks(at: $0) }
        self.difficultyScore = game.difficultyScore
        self.difficulty = game.difficultyEnum
        self.isDaily = game.isDaily
        self.dailyDate = game.dailyDate
        self.mistakes = game.mistakes
        self.hintsRemaining = 3 - game.hintsUsed
        self.elapsedSeconds = game.elapsedSeconds
        self.isPaused = false
        self.isComplete = false
        self.selectedIndex = nil
        self.undoStack = []
        self.modelContext = context
        startTimer()
    }

    // MARK: - Actions

    func selectCell(_ index: Int) {
        selectedIndex = index
    }

    func place(_ digit: Int) {
        guard let idx = selectedIndex, givens[idx] == 0, !isComplete else { return }

        if isNotesMode {
            pushUndo()
            var marks = pencilMarks[idx]
            if marks.contains(digit) {
                marks.removeAll { $0 == digit }
            } else {
                marks.append(digit)
                marks.sort()
            }
            pencilMarks[idx] = marks
        } else {
            guard playerValues[idx] != digit else { return }
            pushUndo()
            playerValues[idx] = digit
            pencilMarks[idx] = []
            // Clear pencil marks of that digit in peers.
            for j in boardPeers[idx] {
                pencilMarks[j].removeAll { $0 == digit }
            }
            if digit != solution[idx] {
                mistakes += 1
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                if mistakes >= 3 { showMistakeTooMany = true }
            } else {
                // Check if row/box/col is complete → medium haptic.
                checkGroupCompletions(for: idx)
                checkWin()
            }
        }
        saveState()
    }

    func erase() {
        guard let idx = selectedIndex, givens[idx] == 0, !isComplete else { return }
        guard playerValues[idx] != 0 || !pencilMarks[idx].isEmpty else { return }
        pushUndo()
        playerValues[idx] = 0
        pencilMarks[idx] = []
        saveState()
    }

    func undo() {
        guard let state = undoStack.popLast() else { return }
        playerValues = state.values
        pencilMarks = state.pencilMarks
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        saveState()
    }

    func useHint() {
        guard hintsRemaining > 0, let idx = selectedIndex,
              givens[idx] == 0, playerValues[idx] != solution[idx], !isComplete else { return }
        pushUndo()
        playerValues[idx] = solution[idx]
        pencilMarks[idx] = []
        for j in boardPeers[idx] { pencilMarks[j].removeAll { $0 == solution[idx] } }
        hintsRemaining -= 1
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        checkGroupCompletions(for: idx)
        checkWin()
        saveState()
    }

    func pause() {
        isPaused = true
        stopTimer()
        saveState()
    }

    func resume() {
        isPaused = false
        startTimer()
    }

    // MARK: - Computed helpers

    var canUndo: Bool { !undoStack.isEmpty }

    /// Digits still placeable (appear < 9 times among givens + player values).
    var remainingCounts: [Int: Int] {
        var counts = [Int: Int]()
        for d in 1...9 {
            let placed = (0..<81).filter { (givens[$0] == d || playerValues[$0] == d) }.count
            counts[d] = 9 - placed
        }
        return counts
    }

    func highlightState(for index: Int) -> CellHighlight {
        guard !givens.isEmpty else { return .none }
        if index == selectedIndex { return .selected }
        guard let sel = selectedIndex else { return .none }
        // Same digit
        let selVal = givens[sel] != 0 ? givens[sel] : playerValues[sel]
        let cellVal = givens[index] != 0 ? givens[index] : playerValues[index]
        if selVal != 0 && cellVal == selVal { return .sameDigit }
        // Same row/col/box
        if boardPeerSets[sel].contains(index) { return .peer }
        return .none
    }

    func isMistake(at index: Int) -> Bool {
        let v = playerValues[index]
        return v != 0 && v != solution[index]
    }

    // MARK: - Private

    private func pushUndo() {
        undoStack.append(UndoState(values: playerValues, pencilMarks: pencilMarks))
        if undoStack.count > maxUndoDepth { undoStack.removeFirst() }
    }

    private func checkGroupCompletions(for index: Int) {
        let r = index / 9, c = index % 9, b = boxIndex(index)
        let groups = [boardRows[r], boardCols[c], boardBoxes[b]]
        for group in groups {
            let complete = group.allSatisfy { i in
                (givens[i] != 0 ? givens[i] : playerValues[i]) != 0
            }
            if complete {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
    }

    private func checkWin() {
        let solved = (0..<81).allSatisfy { i in
            (givens[i] != 0 ? givens[i] : playerValues[i]) == solution[i]
        }
        guard solved else { return }
        isComplete = true
        stopTimer()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        recordCompletion()
    }

    private func recordCompletion() {
        guard let ctx = modelContext else { return }
        // Save CompletedGame
        let games = (try? ctx.fetch(FetchDescriptor<ActiveGame>())) ?? []
        if let active = games.first {
            active.elapsedSeconds = elapsedSeconds
            active.mistakes = mistakes
            active.hintsUsed = 3 - hintsRemaining
            let completed = CompletedGame(from: active)
            ctx.insert(completed)
            ctx.delete(active)
        }
        // Update DailyRecord if daily
        if isDaily, let date = dailyDate {
            let pred = #Predicate<DailyRecord> { $0.dateString == date }
            let records = (try? ctx.fetch(FetchDescriptor(predicate: pred))) ?? []
            if let record = records.first {
                record.completed = true
                record.elapsedSeconds = elapsedSeconds
            } else {
                let r = DailyRecord(dateString: date)
                r.completed = true
                r.elapsedSeconds = elapsedSeconds
                ctx.insert(r)
            }
        }
        try? ctx.save()
        AdaptiveDifficulty.recordCompletion(
            elapsed: elapsedSeconds,
            score: difficultyScore,
            mistakes: mistakes,
            hints: 3 - hintsRemaining
        )
    }

    private func saveState() {
        guard let ctx = modelContext else { return }
        let games = (try? ctx.fetch(FetchDescriptor<ActiveGame>())) ?? []
        guard let active = games.first else { return }
        active.playerValues = playerValues
        for i in 0..<81 {
            for d in 1...9 {
                active.setPencilMark(d, at: i, on: pencilMarks[i].contains(d))
            }
        }
        active.elapsedSeconds = elapsedSeconds
        active.mistakes = mistakes
        active.hintsUsed = 3 - hintsRemaining
        try? ctx.save()
    }

    private func startTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                if let self, !self.isPaused, !self.isComplete {
                    self.elapsedSeconds += 1
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
}

enum CellHighlight { case none, selected, peer, sameDigit }
