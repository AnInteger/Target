//
//  TodayWidgetBundle.swift
//  TargetWidgets
//
//  v3 WidgetKit 小组件（006）：纯渲染，零业务逻辑——数据经 App Group
//  快照由 Dart 侧写入（key "snapshot"）。v3 快照 schema：
//  { updatedAt, todayRecordCount, todayMinutes, latestTitle?,
//    latestGoalName?, latestGoalColorKey? }
//  深链 target://record → App 壳层记录钮路径（/goals 分支 + record sheet）。
//  取色一律经 DesignTokens（镜像 design_tokens.dart v3）。
//

import SwiftUI
import WidgetKit

// MARK: - Snapshot model（与 Dart buildTodaySnapshot 一一对应）

struct Snapshot: Codable {
    let updatedAt: String
    let todayRecordCount: Int
    let todayMinutes: Int
    let latestTitle: String?
    let latestGoalName: String?
    let latestGoalColorKey: String?
}

// MARK: - Timeline

struct TodayEntry: TimelineEntry {
    let date: Date
    // nil = 快照缺失（首装/后台受限）：按空态渲染，不崩溃。
    let snapshot: Snapshot?
}

struct TodayProvider: TimelineProvider {
    static let appGroup = "group.com.target.shared"
    static let snapshotKey = "snapshot"

    func readSnapshot() -> Snapshot? {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroup),
            let json = defaults.string(forKey: Self.snapshotKey),
            let data = json.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(Snapshot.self, from: data)
    }

    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), snapshot: readSnapshot())
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: Date(), snapshot: readSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let now = Date()
        let snapshot = readSnapshot()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: now)!)
        completion(Timeline(
            entries: [
                TodayEntry(date: now, snapshot: snapshot),
                TodayEntry(date: midnight, snapshot: snapshot),
            ],
            policy: .after(midnight)
        ))
    }
}

// MARK: - Views

/// v3 小组件（systemSmall）：今日记录数大数字 + 「条」单位。
struct SmallView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: TodayEntry

    private var dark: Bool { colorScheme == .dark }
    private var tokens: WidgetPalette { DesignTokens.palette(dark) }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(entry.snapshot?.todayRecordCount ?? 0)")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(tokens.onSurface)
            Text("条")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(tokens.onSurfaceVariant)
            Text("今天的进展记录")
                .font(.system(size: 13))
                .foregroundStyle(tokens.onSurfaceVariant)
        }
        .widgetURL(URL(string: "target://record"))
    }
}

/// v3 中组件（systemMedium）：左 = 今日计数 + 分钟；右 = 最近记录。
struct MediumView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: TodayEntry

    private var dark: Bool { colorScheme == .dark }
    private var tokens: WidgetPalette { DesignTokens.palette(dark) }

    var body: some View {
        let snap = entry.snapshot
        HStack(spacing: 16) {
            // 左列：计数 + 分钟
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(snap?.todayRecordCount ?? 0)")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(tokens.onSurface)
                    Text("条")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(tokens.onSurfaceVariant)
                }
                if let minutes = snap?.todayMinutes, minutes > 0 {
                    Text("投入 \(minutes) 分钟")
                        .font(.system(size: 12))
                        .foregroundStyle(tokens.onSurfaceVariant)
                }
                Spacer()
            }
            // 竖分隔
            Rectangle()
                .fill(tokens.divider)
                .frame(width: 0.5)
            // 右列：最近记录
            VStack(alignment: .leading, spacing: 4) {
                if let title = snap?.latestTitle {
                    Text("最近记录")
                        .font(.system(size: 11))
                        .foregroundStyle(tokens.onSurfaceTertiary)
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                        .foregroundStyle(tokens.onSurface)
                    Spacer()
                    if let goalName = snap?.latestGoalName {
                        let colorKey = snap?.latestGoalColorKey ?? "gray"
                        let color = DesignTokens.goalColor(colorKey, dark: dark)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                            Text(goalName)
                                .font(.system(size: 12))
                                .foregroundStyle(tokens.onSurfaceVariant)
                        }
                    }
                } else {
                    Spacer()
                    Text("还没有记录")
                        .font(.system(size: 15))
                        .foregroundStyle(tokens.onSurfaceVariant)
                    Spacer()
                }
            }
        }
        .widgetURL(URL(string: "target://record"))
    }
}

/// 锁屏圆形（accessoryCircular）：今日计数。
struct AccessoryCircularView: View {
    let entry: TodayEntry

    var body: some View {
        Text("\(entry.snapshot?.todayRecordCount ?? 0)")
            .font(.headline)
            .widgetURL(URL(string: "target://record"))
    }
}

/// 锁屏矩形（accessoryRectangular）：最近记录标题 + 目标名。
struct AccessoryRectangularView: View {
    let entry: TodayEntry

    var body: some View {
        if let title = entry.snapshot?.latestTitle {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                if let goalName = entry.snapshot?.latestGoalName {
                    Text(goalName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .widgetURL(URL(string: "target://record"))
        } else {
            VStack(alignment: .leading) {
                Text("记录一笔")
                    .font(.headline)
                Text("每一次尝试，都值得留下。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .widgetURL(URL(string: "target://record"))
        }
    }
}

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodayEntry

    var body: some View {
        Group {
            switch family {
            case .systemMedium: MediumView(entry: entry)
            case .accessoryCircular: AccessoryCircularView(entry: entry)
            case .accessoryRectangular: AccessoryRectangularView(entry: entry)
            default: SmallView(entry: entry)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget

@main
struct TargetWidgetBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TodayWidget", provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName("Target · 今日")
        .description("今日记录数与最近进展")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}
