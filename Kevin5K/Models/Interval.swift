import Foundation

enum IntervalType: String, Codable {
    case run, walk
    var description: String { rawValue.capitalized }
}

struct Interval: Identifiable, Codable, Hashable {   // ← add Hashable here
    let id: UUID
    let type: IntervalType
    let duration: TimeInterval          // seconds

    init(id: UUID = UUID(),
         type: IntervalType,
         duration: TimeInterval) {
        self.id = id
        self.type = type
        self.duration = duration
    }
}
