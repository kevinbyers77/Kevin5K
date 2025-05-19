import Foundation

struct Session: Identifiable, Codable, Hashable {
    let id: UUID
    var week: Int
    var day:  Int
    let intervals: [Interval]
    var date: Date
    var completed = false
    
    var title: String { "Week \(week) • Day \(day)" }

    init(id: UUID = UUID(),
         week: Int,
         day: Int,
         intervals: [Interval],
         date: Date,
         completed: Bool = false) {
        self.id = id
        self.week = week
        self.day = day
        self.intervals = intervals
        self.date = date
        self.completed = completed
    }
}
