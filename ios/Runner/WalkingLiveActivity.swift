import ActivityKit
import UIKit

/// Shows measured values only. iOS may delay background deliveries, so the
/// presentation always includes the time of the last actual sensor update.
final class WalkingLiveActivity {
    private var activity: Activity<WalkingActivityAttributes>?
    private var pending: Task<Void, Never>?
    private var lastUpdate = Date.distantPast
    private var lastSteps = 0
    private var period: Date?

    func update(steps: Int, startedAt: Date, periodStart: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let id = String(Int64(startedAt.timeIntervalSince1970 * 1000))
        if let current = activity, current.attributes.sessionID != id { end() }
        if period != periodStart { period = periodStart; lastSteps = 0 }
        lastSteps = max(lastSteps, steps)
        let now = Date()
        let content = ActivityContent(
            state: WalkingActivityAttributes.ContentState(steps: lastSteps, updatedAt: now),
            staleDate: now.addingTimeInterval(300))
        if activity == nil {
            activity = Activity<WalkingActivityAttributes>.activities.first {
                $0.attributes.sessionID == id && $0.activityState == .active
            }
            if activity == nil && UIApplication.shared.applicationState == .active {
                activity = try? Activity.request(
                    attributes: WalkingActivityAttributes(sessionID: id, startedAt: startedAt),
                    content: content, pushType: nil)
            }
        }
        guard let current = activity, now.timeIntervalSince(lastUpdate) >= 10 else { return }
        lastUpdate = now
        pending?.cancel()
        pending = Task {
            guard !Task.isCancelled else { return }
            await current.update(content)
        }
    }

    func end() {
        pending?.cancel()
        if let current = activity {
            Task { await current.end(nil, dismissalPolicy: .immediate) }
        }
        activity = nil
        lastUpdate = .distantPast
        lastSteps = 0
        period = nil
    }
}
