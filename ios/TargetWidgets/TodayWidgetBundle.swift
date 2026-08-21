//
//  TodayWidgetBundle.swift
//  TargetWidgets
//
//  WidgetKit 小组件（T029 视觉同步「柔彩仪表盘」）：纯渲染，零业务逻辑——
//  数据经 App Group 快照由 Dart 侧写入（key "snapshot"，schema 见
//  contracts/widget-intent.md），行内打卡按钮经 BackgroundIntent 回传
//  Dart 回调。取色一律经 DesignTokens（镜像 design_tokens.dart）。
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

// MARK: - Palette（全部取值经 DesignTokens，见 DesignTokens.swift）

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
    @Environment(\.colorScheme) private var colorScheme
    let entry: TodayEntry

    private var dark: Bool { colorScheme == .dark }
    private var tokens: WidgetPalette { DesignTokens.palette(dark) }

    var body: some View {
        let battery = entry.snapshot?.battery
        VStack(spacing: 8) {
            ZStack {
                // 轨道 = onSurface 15%（App 今日环同构）；进度 = 青柠达成/
                // 低电量琥珀（token positiveFill/warning，不再用系统色）。
                Circle()
                    .stroke(tokens.onSurface.opacity(0.15), lineWidth: 9)
                Circle()
                    .trim(to: battery.map { Double($0) / 100 } ?? 0)
                    .stroke(
                        (battery ?? 100) < 30 ? tokens.warning : tokens.positiveFill,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                Text(battery.map { "\($0)%" } ?? "—")
                    .font(.system(size: 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(tokens.onSurface)
            }
            if let wp = entry.snapshot?.weekProgress {
                Text("今日 \(wp.metGoals)/\(wp.totalGoals)")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(tokens.onSurfaceVariant)
            }
        }
        .widgetURL(URL(string: "target://today"))
    }
}

/// 目标图标徽（26pt 圆角方 = App 图标格语言按比例缩小）：
/// 目标色 18% 底 + 目标色首字。
struct GoalChip: View {
    let goal: WidgetGoal
    let dark: Bool

    var body: some View {
        let color = DesignTokens.goalColor(goal.colorKey, dark: dark)
        return RoundedRectangle(cornerRadius: 10)
            .fill(color.opacity(0.18))
            .frame(width: 26, height: 26)
            .overlay(
                Text(String(goal.name.prefix(1)))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            )
    }
}

struct MediumView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: TodayEntry

    private var dark: Bool { colorScheme == .dark }
    private var tokens: WidgetPalette { DesignTokens.palette(dark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                // 身份渐变小徽（App 身份卡同源渐变，「星行」首字）。
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(
                        colors: [DesignTokens.avatarGradA, DesignTokens.avatarGradB],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 15, height: 15)
                    .overlay(
                        Text("星")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                Text("Target")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tokens.onSurface)
                if let battery = entry.snapshot?.battery {
                    // if let 已解包（非 Optional，无 .map）——原写法把解包值当
                    // Optional 用导致编译错误；nil 分支本就走不到这里。
                    Text("· \(battery)%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(tokens.onSurfaceVariant)
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
                        .foregroundStyle(tokens.onSurfaceVariant)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(goals) { goal in
                    if goal.isMilestone {
                        // 里程碑（T044）：只读进度行 — 步骤 x/y + 倒计时，整行点击进详情。
                        HStack(spacing: 8) {
                            GoalChip(goal: goal, dark: dark)
                            Text(goal.name)
                                .font(.footnote)
                                .lineLimit(1)
                                .foregroundStyle(tokens.onSurface)
                            Spacer()
                            if let total = goal.stepsTotal, total > 0 {
                                Text("\(goal.stepsDone ?? 0)/\(total)")
                                    .font(.footnote.monospacedDigit())
                                    .foregroundStyle(tokens.onSurfaceVariant)
                            }
                            if let days = goal.daysLeft {
                                Text(days >= 0 ? "还剩\(days)天" : "过了\(-days)天")
                                    .font(.caption2)
                                    .foregroundStyle(tokens.onSurfaceVariant)
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            GoalChip(goal: goal, dark: dark)
                            Text(goal.name)
                                .font(.footnote)
                                .lineLimit(1)
                                .foregroundStyle(tokens.onSurface)
                            Spacer()
                            Text("\(goal.doneCount ?? 0)/\(goal.targetCount ?? 0)")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(tokens.onSurfaceVariant)
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
                                    // 达成 = 青柠（App 完成语义对），未达成 = 目标色。
                                    .foregroundStyle(goal.met == true
                                        ? tokens.positiveFill
                                        : DesignTokens.goalColor(goal.colorKey, dark: dark))
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
    @Environment(\.colorScheme) private var colorScheme
    let entry: TodayEntry

    private var dark: Bool { colorScheme == .dark }
    private var tokens: WidgetPalette { DesignTokens.palette(dark) }

    var body: some View {
        let battery = entry.snapshot?.battery
        ZStack {
            Circle()
                .stroke(.secondary.opacity(0.3), lineWidth: 5)
            Circle()
                .trim(to: battery.map { Double($0) / 100 } ?? 0)
                .stroke(
                    (battery ?? 100) < 30 ? tokens.warning : tokens.positiveFill,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
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
