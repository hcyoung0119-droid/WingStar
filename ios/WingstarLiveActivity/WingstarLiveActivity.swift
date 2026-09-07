import ActivityKit
import SwiftUI
import WidgetKit

@main
struct WingstarLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WalkingActivityAttributes.self) { context in
            HStack(spacing: 16) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 34)).foregroundStyle(.cyan)
                VStack(alignment: .leading, spacing: 4) {
                    Text("WingStar · 산책 중").font(.headline)
                    Text("\(context.state.steps.formatted()) 걸음")
                        .font(.title2.bold()).monospacedDigit()
                    HStack(spacing: 4) {
                        Text(context.isStale ? "마지막 기록" : "기록 시각")
                        Text(context.state.updatedAt, style: .time)
                    }.font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .activityBackgroundTint(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("WingStar", systemImage: "figure.walk")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.steps.formatted()) 걸음").monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.isStale ? "마지막 기록" : "산책 기록 중")
                        Spacer()
                        Text(context.state.updatedAt, style: .time)
                    }.font(.caption)
                }
            } compactLeading: {
                Image(systemName: "figure.walk")
            } compactTrailing: {
                Text(context.state.steps.formatted()).monospacedDigit()
            } minimal: {
                Image(systemName: "figure.walk")
            }
        }
    }
}
