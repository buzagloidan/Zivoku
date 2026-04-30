import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CompletedGame.completedAt, order: .reverse) private var games: [CompletedGame]
    @Query private var dailyRecords: [DailyRecord]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    companionHeader
                    summarySection
                    bestTimesSection
                    dailyCalendarSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(Theme.rounded(16, weight: .semibold))
                        .foregroundStyle(Theme.primary)
                }
            }
        }
    }

    // MARK: - Sections

    private var companionHeader: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottom) {
                CompanionSprite(name: games.isEmpty ? "maple_12" : "maple_09", height: 72)
                    .offset(x: 18, y: 2)
                CompanionSprite(name: games.isEmpty ? "piggy_10" : "piggy_05", height: 62, flipped: games.isEmpty)
                    .offset(x: -26, y: 8)
            }
            .frame(width: 104, height: 82)

            VStack(alignment: .leading, spacing: 4) {
                Text(games.isEmpty ? "First puzzle awaits" : "Ziv's puzzle shelf")
                    .font(Theme.rounded(19, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text(games.isEmpty ? "Piggy and Maple will keep score." : statsSubtitle)
                    .font(Theme.rounded(13))
                    .foregroundStyle(Theme.inkFaint)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .shadow(color: Theme.ink.opacity(0.06), radius: 5, y: 2)
    }

    private var summarySection: some View {
        HStack(spacing: 12) {
            statCard(value: "\(games.count)", label: "Puzzles Solved", sprite: "piggy_08")
            statCard(value: "\(currentStreak)", label: "Streak 🔥", sprite: currentStreak > 0 ? "maple_11" : "maple_12")
            statCard(value: "\(longestStreak)", label: "Best Streak", sprite: "maple_05")
        }
    }

    private var bestTimesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Best Times")
                .font(Theme.rounded(17, weight: .semibold))
                .foregroundStyle(Theme.ink)
            ForEach(Difficulty.allCases, id: \.self) { diff in
                let best = bestTime(for: diff)
                HStack {
                    Text(diff.displayName)
                        .font(Theme.rounded(15))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text(best.map { formatTime($0) } ?? "—")
                        .font(Theme.rounded(15, weight: .semibold))
                        .foregroundStyle(best == nil ? Theme.inkFaint : Theme.primary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 10))
                .shadow(color: Theme.ink.opacity(0.05), radius: 3, y: 1)
            }
        }
    }

    private var dailyCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Puzzles (last 30 days)")
                .font(Theme.rounded(17, weight: .semibold))
                .foregroundStyle(Theme.ink)

            let dates = last30Days
            let cols = 7
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: cols), spacing: 6) {
                ForEach(dates, id: \.self) { date in
                    let str = DailyRecord.dateString(for: date)
                    let rec = dailyRecords.first { $0.dateString == str }
                    Circle()
                        .fill(rec?.completed == true ? Theme.primary : Theme.primarySoft.opacity(0.20))
                        .frame(height: 32)
                        .overlay {
                            if rec?.completed == true {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                }
            }
        }
    }

    // MARK: - Helpers

    private func statCard(value: String, label: String, sprite: String? = nil) -> some View {
        VStack(spacing: 4) {
            if let sprite {
                CompanionSprite(name: sprite, height: 34)
                    .frame(height: 34)
            }
            Text(value)
                .font(Theme.rounded(26, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(Theme.rounded(11))
                .foregroundStyle(Theme.inkFaint)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .shadow(color: Theme.ink.opacity(0.06), radius: 4, y: 2)
    }

    private var statsSubtitle: String {
        if currentStreak > 0 {
            return "\(currentStreak)-day daily streak with Maple on patrol."
        }
        return "Piggy has \(games.count) solved puzzles on the shelf."
    }

    private func bestTime(for diff: Difficulty) -> Double? {
        games.filter { $0.difficulty == diff.rawValue }.map(\.elapsedSeconds).min()
    }

    private func formatTime(_ s: Double) -> String {
        let t = Int(s)
        return String(format: "%d:%02d", t / 60, t % 60)
    }

    private var currentStreak: Int {
        let cal = Calendar(identifier: .gregorian)
        var streak = 0
        var checkDate = Date()
        let completed = Set(dailyRecords.filter(\.completed).map(\.dateString))
        // Allow "today not yet played" → start from yesterday
        if !completed.contains(DailyRecord.dateString(for: checkDate)) {
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        while completed.contains(DailyRecord.dateString(for: checkDate)) {
            streak += 1
            checkDate = cal.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return streak
    }

    private var longestStreak: Int {
        let sorted = dailyRecords.filter(\.completed).map(\.dateString).sorted()
        guard !sorted.isEmpty else { return 0 }
        let cal = Calendar(identifier: .gregorian)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyyMMdd"
        var longest = 1, current = 1
        for i in 1..<sorted.count {
            let prev = fmt.date(from: sorted[i-1])!
            let curr = fmt.date(from: sorted[i])!
            if cal.dateComponents([.day], from: prev, to: curr).day == 1 {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }

    private var last30Days: [Date] {
        let cal = Calendar(identifier: .gregorian)
        return (0..<30).compactMap { cal.date(byAdding: .day, value: -$0, to: Date()) }.reversed()
    }
}
