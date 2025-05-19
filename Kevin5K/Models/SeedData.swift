//
//  SeedData.swift
//  Kevin5K
//
//  Created by Kevin Byers on 2/5/2025.
//


import Foundation

struct SeedData {
    static func generate(starting start: Date) -> [Session] {
        var sessions: [Session] = []
        let cal = Calendar.current
        var date = start
        
        func add(_ w: Int, _ d: Int, _ pattern: [(IntervalType, Int)]) {
            sessions.append(
                Session(week: w,
                        day:  d,
                        intervals: pattern.map { Interval(type: $0.0,
                                                           duration: TimeInterval($0.1)) },
                        date: date)
            )
            date = cal.date(byAdding: .day, value: 2, to: date)!
        }
        
        func r(_ s: Int) -> (IntervalType, Int) { (.run,  s) }
        func w(_ s: Int) -> (IntervalType, Int) { (.walk, s) }
        let W = w(300)         // 5-min walk
        
        // Week 1  run 60 / walk 90 × 8
        for d in 1...3 {
            add(1, d, [W] + Array(repeating: [r(60), w(90)],  count: 8).flatMap { $0 } + [W])
        }
        // Week 2  run 90 / walk 120 × 6
        for d in 1...3 {
            add(2, d, [W] + Array(repeating: [r(90), w(120)], count: 6).flatMap { $0 } + [W])
        }
        // Week 3
        let w3 = [W, r(90), w(90), r(180), w(180), r(90), w(90), r(180), w(180), W]
        for d in 1...3 { add(3, d, w3) }
        // Week 4
        let w4 = [W, r(180), w(90), r(300), w(150), r(180), w(90), r(300), W]
        for d in 1...3 { add(4, d, w4) }
        // Week 5
        add(5, 1, [W] + Array(repeating: [r(300), w(180)], count: 3).flatMap { $0 } + [W])
        add(5, 2, [W, r(480), w(300), r(480), W])
        add(5, 3, [W, r(1200), W])
        // Week 6
        add(6, 1, [W, r(300), w(180), r(480), w(180), r(300), W])
        add(6, 2, [W, r(600), w(180), r(600), W])
        add(6, 3, [W, r(1500), W])
        // Week 7  run 25 min
        for d in 1...3 { add(7, d, [W, r(1500), W]) }
        // Week 8  run 28 min
        for d in 1...3 { add(8, d, [W, r(1680), W]) }
        // Week 9  run 30 min
        for d in 1...3 { add(9, d, [W, r(1800), W]) }
        
        return sessions
    }
}