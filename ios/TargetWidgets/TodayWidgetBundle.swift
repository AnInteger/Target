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
import home_widget

// MARK: - Snapshot model（与 Dart buildTodaySnapshot 一一对应）

struct WidgetGoal: Codable, Identifiable {
    let id: String
    let name: String
    let colorKey: String
    let iconKey: String
    let targetCount: Int
    let doneCount: Int
    let met: Bool
    let busyMode: Bool
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
                        if goal.busyMode {
                            Text("忙碌中")
                                .font(.caption2)
                                .padding(.horizontal, 4)
                                .background(Capsule().fill(Color.secondary.opacity(0.2)))
                        }
                        Spacer()
                        Text("\(goal.doneCount)/\(goal.targetCount)")
                            .font(.footnote.monospacedDigit())
                            .foregroundStyle(.secondary)
                        // iOS 17 交互：行内打卡 → Dart 回调（校验+写库+快照回写）
                        Button(
                            intent: HomeWidgetBackgroundIntent(
                                url: URL(string: "target://checkin?goalId=\(goal.id)")!)
                        ) {
                            Image(systemName: goal.met
                                ? "checkmark.circle.fill"
                                : "plus.circle")
                                .foregroundStyle(goalColor(goal.colorKey))
                        }
                        .buttonStyle(.plain)
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
        let first = (entry.snapshot?.goals ?? []).first(where: { !$0.met })
        if let goal = first {
            VStack(alignment: .leading) {
                Text(goal.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(goal.doneCount)/\(goal.targetCount)")
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
