//
//  TodayWidgetBundle.swift
//  TargetWidgets
//
//  WidgetKit 小组件（T029）：纯渲染，零业务逻辑——数据经 App Group 快照
//  由 Dart 侧写入（key "snapshot"，schema 见 contracts/widget-intent.md），
//  行内打卡按钮经 home_widget BackgroundIntent 回传 Dart 回调。
//

import SwiftUI
import WidgetKit

// MARK: - Snapshot model（与 Dart buildTodaySnapshot 一一对应）

struct WidgetGoal: Codable, Identifiable {
    let id: String
    let name: String
    let colorKey: String
    let iconKey: String
    // 习惯行必有；里程碑行为 nil（T044 可选键，兼容旧快照）。
    let targetCount: Int?
    let doneCount: Int?
    let met: Bool?
    let busyMode: Bool?
    // T044 里程碑扩展（可选）：kind == "milestone" 时有效。
    let kind: String?
    let stepsDone: Int?
    let stepsTotal: Int?
    let deadline: String?

    var isMilestone: Bool { kind == "milestone" }

    /// 距截止剩余天数（-1 = 已过）；仅里程碑行有意义。
    var daysLeft: Int? {
        guard let deadline else { return nil }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        guard let end = fmt.date(from: deadline) else { return nil }
        let days = Calendar.current.dateComponents(
            [.day], from: Calendar.current.startOfDay(for: Date()),
            to: end).day ?? 0
        return days
    }
}

struct WeekProgress: Codable {
    let weekStart: String
    let metGoals: Int
    let totalGoals: Int
}

struct Snapshot: Codable {
    let battery: Int?
    let updatedAt: String
    let goals: [WidgetGoal]
    let weekProgress: WeekProgress
}

// MARK: - Palette（镜像 GoalColor 设计令牌，浅色值）

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

let goalPalette: [String: Color] = [
    "coral": Color(hex: 0xE2725B),
    "amber": Color(hex: 0xD99A2B),
    "sage": Color(hex: 0x7A9B76),
    "teal": Color(hex: 0x4F9D8D),
    "sky": Color(hex: 0x5B8DB8),
    "indigo": Color(hex: 0x6674AC),
    "plum": Color(hex: 0x9C6B9F),
    "stone": Color(hex: 0x8A8D8F),
]

func goalColor(_ key: String) -> Color {
    goalPalette[key] ?? goalPalette["teal"]!
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
        // 预生成次日 0 点切换条目（同快照缓存渲染），到点由系统重取 timeline。
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

struct SmallView: View {
    let entry: TodayEntry

    var body: some View {
        let battery = entry.snapshot?.battery
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(UIColor.systemGray5), lineWidth: 9)
                Circle()
                    .trim(to: battery.map { Double($0) / 100 } ?? 0)
                    .stroke(
                        (battery ?? 100) < 30 ? Color.orange : goalColor("teal"),
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(battery.map { "\($0)%" } ?? "—")
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
            }
            if let wp = entry.snapshot?.weekProgress {
                Text("今日 \(wp.metGoals)/\(wp.totalGoals)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "target://today"))
    }
}

struct MediumView: View {
    let entry: TodayEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Target")
                    .font(.caption.weight(.semibold))
                if let battery = entry.snapshot?.battery {
                    Text(battery.map { "· \($0)%" } ?? "· —")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            let goals = Array((entry.snapshot?.goals ?? []).prefix(4))
            if goals.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("打开 App，从一件小事开始")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(goals) { goal in
                    if goal.isMilestone {
                        // 里程碑（T044）：只读进度行 — 步骤 x/y + 倒计时，整行点击进详情。
                        HStack(spacing: 8) {
                            Circle()
                                .fill(goalColor(goal.colorKey).opacity(0.22))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Text(String(goal.name.prefix(1)))
                                        .font(.caption2)
                                        .foregroundStyle(goalColor(goal.colorKey))
                                )
                            Text(goal.name)
                                .font(.footnote)
                                .lineLimit(1)
                            Spacer()
                            if let total = goal.stepsTotal, total > 0 {
                                Text("\(goal.stepsDone ?? 0)/\(total)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                            if let days = goal.daysLeft {
                                Text(days >= 0 ? "还剩\(days)天" : "过了\(-days)天")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(goalColor(goal.colorKey).opacity(0.22))
                                .frame(width: 26, height: 26)
                                .overlay(
                                    Text(String(goal.name.prefix(1)))
                                        .font(.caption2)
                                        .foregroundStyle(goalColor(goal.colorKey))
                                )
                            Text(goal.name)
                                .font(.footnote)
                                .lineLimit(1)
                            if goal.busyMode == true {
                                Text("忙碌中")
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .background(Capsule().fill(Color.secondary.opacity(0.2)))
                            }
                            Spacer()
                            Text("\(goal.doneCount ?? 0)/\(goal.targetCount ?? 0)")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(.secondary)
                            // iOS 17 交互：行内打卡 → Dart 回调（校验+写库+快照回写）。
                            // home_widget 0.9.x 已移除 HomeWidgetBackgroundIntent，
                            // 使用本项目双 target 编译的 WidgetCheckInIntent（BackgroundIntent.swift）。
                            Button(
                                intent: WidgetCheckInIntent(
                                    url: URL(string: "target://checkin?goalId=\(goal.id)")!,
                                    appGroup: TodayProvider.appGroup)
                            ) {
                                Image(systemName: goal.met == true
                                    ? "checkmark.circle.fill"
                                    : "plus.circle")
                                    .foregroundStyle(goalColor(goal.colorKey))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .widgetURL(URL(string: "target://today"))
    }
}

struct AccessoryCircularView: View {
    let entry: TodayEntry

    var body: some View {
        let battery = entry.snapshot?.battery
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.35), lineWidth: 5)
            Circle()
                .trim(to: battery.map { Double($0) / 100 } ?? 0)
                .stroke(.primary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(battery.map { "\($0)" } ?? "—")
                .font(.headline)
        }
        .widgetURL(URL(string: "target://today"))
    }
}

struct AccessoryRectangularView: View {
    let entry: TodayEntry

    var body: some View {
        let first = (entry.snapshot?.goals ?? []).first(where: { goal in
            if goal.isMilestone { return true }
            return goal.met != true
        })
        if let goal = first {
            VStack(alignment: .leading) {
                Text(goal.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(goal.isMilestone
                    ? (goal.stepsTotal ?? 0) > 0
                        ? "步骤 \(goal.stepsDone ?? 0)/\(goal.stepsTotal ?? 0)"
                        : "里程碑"
                    : "\(goal.doneCount ?? 0)/\(goal.targetCount ?? 0)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .widgetURL(URL(string: "target://goal/\(goal.id)"))
        } else {
            VStack(alignment: .leading) {
                Text("今天都照顾到了")
                    .font(.headline)
                Text("剩下的时间，安心休息。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .widgetURL(URL(string: "target://today"))
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
        .configurationDisplayName("今日")
        .description("生活电量与今日目标")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
        ])
    }
}
