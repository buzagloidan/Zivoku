import SwiftData
import Foundation

@Model
final class DailyRecord {
    @Attribute(.unique) var dateString: String  // "YYYYMMDD"
    var completed: Bool
    var elapsedSeconds: Double

    init(dateString: String) {
        self.dateString = dateString
        self.completed = false
        self.elapsedSeconds = 0
    }

    static func dateString(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: date)
    }
}
