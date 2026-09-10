//
//  TodayWidgetBundle.swift
//  TargetWidgets
//
//  v3 WidgetKit 小组件（006）：纯渲染，零业务逻辑——数据经 App Group
//  快照由 Dart 侧写入（key "snapshot"）。v4 快照 schema：
//  { updatedAt, todayRecordCount, todayMinutes, latestTitle?,
//    latestGoalName?, latestGoalColorKey?,
//    goals?: [ { name, colorKey, iconKey, category?, latestTitle?,
//                latestLabel?, nextMilestone? } ] }
//  深链 target://record → App 壳层记录钮路径（/goals 分支 + record sheet）。
//  取色一律经 DesignTokens（镜像 design_tokens.dart v3）。
//
//  R13c 目标卡片小组件（GoalPagesWidget · systemMedium 4×2）：
//  AppIntent 可配置——添加组件时从快照目标中选择一个，每实例展示
//  一个目标（卡片版式镜像目标页置顶大卡）。翻页交给系统原生：多个
//  实例在桌面叠放（Widget Stack）后即可上下滑动手动翻页 + 原生页点
//  （组件内不支持手势，不做自绘轮播）。未选择时回退置顶首个目标。
//

import AppIntents
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

    /// v4：目标卡片小组件的数据页（旧快照无此键 → nil）。
    let goals: [GoalPage]?
}

/// 单个目标页（展示串全部由 Dart 侧预计算）。
struct GoalPage: Codable {
    let id: String
    let name: String
    let colorKey: String
    let iconKey: String?
    let category: String?
    let latestTitle: String?
    let latestLabel: String?
    let nextMilestone: String?
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
        GoalPagesWidget()
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

// MARK: - 目标翻页小组件（R13 · systemMedium 4×2）

/// iconKey（38 枚 Material 目录键）→ SF Symbol 近似映射；未知键回退靶心。
enum GoalIconMap {
    static let sfSymbols: [String: String] = [
        "directions_bike": "figure.outdoor.cycle",
        "directions_run": "figure.run",
        "pool": "figure.pool.swim",
        "hiking": "figure.hiking",
        "fitness_center": "dumbbell",
        "menu_book": "text.book.closed",
        "school": "graduationcap",
        "translate": "translate",
        "auto_stories": "book",
        "favorite": "heart",
        "monitor_heart": "waveform.path.ecg",
        "bedtime": "moon.zzz",
        "water_drop": "drop",
        "brush": "paintbrush",
        "camera": "camera",
        "palette": "paintpalette",
        "music_note": "music.note",
        "flight": "airplane",
        "luggage": "bag",
        "map": "map",
        "cabin": "house",
        "explore": "safari",
        "savings": "banknote",
        "trending_up": "chart.line.uptrend.xyaxis",
        "account_balance_wallet": "wallet.pass",
        "paid": "dollarsign.circle",
        "home": "house",
        "restaurant": "fork.knife",
        "cleaning_services": "sparkles",
        "eco": "leaf",
        "self_improvement": "figure.mind.and.body",
        "spa": "leaf.circle",
        "air": "wind",
        "forest": "tree",
        "groups": "person.3",
        "volunteer_activism": "figure.arms.open",
        "forum": "bubble.left.and.bubble.right",
        "pets": "pawprint",
    ]

    static func symbol(_ key: String?) -> String {
        key.flatMap { sfSymbols[$0] } ?? "scope"
    }
}

struct GoalPagesEntry: TimelineEntry {
    let date: Date
    /// nil = 无目标（空态渲染）。
    let page: GoalPage?
}

/// 供 AppIntent 参数选择的目标实体（源自 App Group 快照）。
struct GoalEntity: AppEntity {
    static let typeDisplayIdentifier = "goal"
    static let defaultQuery = GoalEntityQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

/// 目标实体查询：快照里的目标即候选（添加/编辑组件时的原生选择器）。
struct GoalEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [GoalEntity] {
        identifiers.compactMap { id in
            GoalPagesWidgetData.pages()
                .first { $0.id == id }
                .map { GoalEntity(id: $0.id, name: $0.name) }
        }
    }

    func suggestedEntities() async throws -> [GoalEntity] {
        GoalPagesWidgetData.pages()
            .map { GoalEntity(id: $0.id, name: $0.name) }
    }
}

/// 组件配置意图：选择要展示的目标（nil = 回退置顶首个）。
struct SelectGoalIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择目标"

    @Parameter(title: "目标")
    var goal: GoalEntity?
}

/// 快照读取（今日/目标两组件共用）。
enum GoalPagesWidgetData {
    static func pages() -> [GoalPage] {
        guard
            let defaults = UserDefaults(suiteName: TodayProvider.appGroup),
            let json = defaults.string(forKey: TodayProvider.snapshotKey),
            let data = json.data(using: .utf8),
            let snapshot = try? JSONDecoder().decode(Snapshot.self, from: data)
        else { return [] }
        return snapshot.goals ?? []
    }
}

struct GoalPagesProvider: AppIntentTimelineProvider {
    typealias Entry = GoalPagesEntry
    typealias Intent = SelectGoalIntent

    /// 选中目标（未选/已删 → 回退置顶首个）。
    private func resolvePage(_ configuration: SelectGoalIntent) -> GoalPage? {
        let pages = GoalPagesWidgetData.pages()
        guard let selected = configuration.goal else {
            return pages.first
        }
        return pages.first { $0.id == selected.id } ?? pages.first
    }

    func placeholder(in context: Context) -> GoalPagesEntry {
        GoalPagesEntry(date: Date(), page: resolvePage(SelectGoalIntent()))
    }

    func snapshot(
        for configuration: SelectGoalIntent,
        in context: Context
    ) async -> GoalPagesEntry {
        GoalPagesEntry(date: Date(), page: resolvePage(configuration))
    }

    func timeline(
        for configuration: SelectGoalIntent,
        in context: Context
    ) async -> Timeline<GoalPagesEntry> {
        let now = Date()
        let page = resolvePage(configuration)
        guard page != nil else {
            // 无目标：空态，一小时后再看。
            return Timeline(
                entries: [GoalPagesEntry(date: now, page: nil)],
                policy: .after(now.addingTimeInterval(3600))
            )
        }
        // 静态单页；午夜补一条刷新相对日标签（今天 → 昨天）。
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: 1, to: now)!
        )
        return Timeline(
            entries: [
                GoalPagesEntry(date: now, page: page),
                GoalPagesEntry(date: midnight, page: page),
            ],
            policy: .after(midnight)
        )
    }
}

/// 单页目标卡（版式镜像目标页置顶大卡）。
struct GoalPageCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let page: GoalPage

    private var dark: Bool { colorScheme == .dark }
    private var tokens: WidgetPalette { DesignTokens.palette(dark) }

    var body: some View {
        let color = DesignTokens.goalColor(page.colorKey, dark: dark)
        VStack(alignment: .leading, spacing: 0) {
            // 顶行：图标 tile（目标色）+ 目标名 + 分类。
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 7)
                    .fill(color.opacity(0.14))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Image(systemName: GoalIconMap.symbol(page.iconKey))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(color)
                    )
                Text(page.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tokens.onSurface)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if let category = page.category {
                    Text(category)
                        .font(.system(size: 11))
                        .foregroundStyle(tokens.onSurfaceTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 6)
            if let title = page.latestTitle {
                // 最近记录：标签 / 相对日 两端对齐。
                HStack {
                    Text("最近记录")
                        .font(.system(size: 11))
                        .foregroundStyle(tokens.onSurfaceTertiary)
                    Spacer()
                    Text(page.latestLabel ?? "")
                        .font(.system(size: 11))
                        .foregroundStyle(tokens.onSurfaceTertiary)
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tokens.onSurface)
                    .lineLimit(2)
            } else {
                Text("尚未记录")
                    .font(.system(size: 12))
                    .foregroundStyle(tokens.onSurfaceTertiary)
            }
            if let milestone = page.nextMilestone {
                Spacer(minLength: 4)
                HStack(spacing: 5) {
                    Image(systemName: "flag")
                        .font(.system(size: 10))
                        .foregroundStyle(tokens.onSurfaceTertiary)
                    Text("下个里程碑 · \(milestone)")
                        .font(.system(size: 11))
                        .foregroundStyle(tokens.onSurfaceVariant)
                        .lineLimit(1)
                }
            }
        }
        .widgetURL(URL(string: "target://goals"))
    }
}

struct GoalPagesView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: GoalPagesEntry

    private var dark: Bool { colorScheme == .dark }
    private var tokens: WidgetPalette { DesignTokens.palette(dark) }

    var body: some View {
        Group {
            if let page = entry.page {
                GoalPageCard(page: page)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.title3)
                        .foregroundStyle(tokens.onSurfaceTertiary)
                    Text("还没有目标")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(tokens.onSurface)
                    Text("在 App 里创建第一个目标")
                        .font(.system(size: 12))
                        .foregroundStyle(tokens.onSurfaceVariant)
                }
                .widgetURL(URL(string: "target://goals"))
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct GoalPagesWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "GoalPagesWidget",
            intent: SelectGoalIntent.self,
            provider: GoalPagesProvider()
        ) { entry in
            GoalPagesView(entry: entry)
        }
        .configurationDisplayName("Target · 目标")
        .description("单个目标的进展卡；添加多个实例叠放即可上下翻页")
        .supportedFamilies([.systemMedium])
    }
}
