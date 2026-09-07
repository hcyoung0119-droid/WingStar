import ActivityKit
import Foundation

struct WalkingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var steps: Int
        var updatedAt: Date
    }
    let sessionID: String
    let startedAt: Date
}
