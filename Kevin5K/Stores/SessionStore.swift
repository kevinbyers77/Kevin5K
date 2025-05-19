//
//  SessionStore.swift
//  Kevin5K
//
//  Created by Kevin Byers on 2/5/2025.
//


import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var activeSessionID: UUID? = nil
    @Published private(set) var sessions: [Session] = []
    
    private let defaults = UserDefaults.standard
    private let saveURL = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("sessions.json")
    
    // MARK: init
    init() {
        load()
        if sessions.isEmpty,
           let start = defaults.object(forKey: "startDate") as? Date {
            initialise(from: start)
        }
    }
    
    // MARK: public
    func initialise(from start: Date) {
        sessions = SeedData.generate(starting: start)
        defaults.set(start, forKey: "startDate")
        save()
        NotificationManager.shared.scheduleAll(for: sessions)
    }
    /// Remove all generated sessions and clear the saved start date.
     func reset() {
         sessions.removeAll()                           // forget progress
         defaults.removeObject(forKey: "startDate")     // forget chosen date
         try? FileManager.default.removeItem(at: saveURL) // delete sessions.json
     }
   
    /// Number of consecutive days (including today) with a completed workout.
    var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var day = cal.startOfDay(for: .now)
        while sessions.contains(where: { cal.isDate($0.date, inSameDayAs: day) && $0.completed }) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
    
    func toggle(_ session: Session) {
        guard let i = sessions.firstIndex(where: { $0.id == session.id }) else { return }
        sessions[i].completed.toggle()
        if sessions[i].completed {
            // Treat swipe as completed today
            let today = Calendar.current.startOfDay(for: Date())
            sessions[i].date = today
        }
        resequence()    // saves, updates labels, reschedules notifications
    }
    /// Re-label and reschedule from the most recent completed session onward.
    private func resequence() {
        print("🔁 resequence() called — now is", Date())
        // 1. Find the last completed session (or start date if none)
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var lastDate = defaults.object(forKey: "startDate") as? Date ?? today
        var week = 1
        var day  = 1

        // 2. Walk sessions in chronological order
        for i in sessions.indices {
            if sessions[i].completed {
                // keep original date & update counters
                lastDate = sessions[i].date
                (week, day) = nextLabel(week: week, day: day)   // helper below
                continue
            }
            // 3. Future session: bump date +2 days and assign new labels
            lastDate = cal.date(byAdding: .day, value: 2, to: lastDate)!
            sessions[i].date = lastDate
            sessions[i].week = week
            sessions[i].day  = day
            (week, day) = nextLabel(week: week, day: day)
        }
        save()
        NotificationManager.shared.scheduleAll(for: sessions)
    }

    /// Helper to increment W/D counters
    private func nextLabel(week: Int, day: Int) -> (Int, Int) {
        if day < 3 { return (week, day + 1) }
        else       { return (week + 1, 1) }
    }
    
    /// Groups sessions by week and exposes collapsed/completed info
    var weeks: [(title: String, sessions: [Session], done: Bool)] {
        Dictionary(grouping: sessions) { $0.week }
            .sorted { $0.key < $1.key }
            .map { week, items in
                let done = items.allSatisfy(\.completed)
                return ("Week \(week)", items, done)
            }
    }
    
    /// Slide all future (incomplete) sessions forward by `days`.
    func shiftPlan(by days: Int) {
        guard days != 0 else { return }
        for i in sessions.indices {
            if !sessions[i].completed {
                sessions[i].date = Calendar.current.date(byAdding: .day,
                                                         value: days,
                                                         to: sessions[i].date)!
            }
        }
        save()
        NotificationManager.shared.scheduleAll(for: sessions)
    }
    
    // MARK: persistence
    private func load() {
        guard
            let data = try? Data(contentsOf: saveURL),
            let decoded = try? JSONDecoder().decode([Session].self, from: data)
        else { return }
        sessions = decoded
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: saveURL, options: .atomic)
        }
    }
}
