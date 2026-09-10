/// 小组件设计预览（R13）：在 App 内（含 Web）还原 iOS WidgetKit 四个
/// 家族的渲染——布局与色值逐一镜像 `ios/TargetWidgets/TodayWidgetBundle.swift`
/// + `DesignTokens.swift`，真机重新打包前先在此查看设计效果。
///
/// * systemSmall / systemMedium —— 主屏小组件（iOS 17 containerBackground
///   以 surfaceAlt 实底近似）；
/// * accessoryCircular / accessoryRectangular —— 锁屏小组件（恒深色玻璃）；
/// * 数据源三档：实时（当前库内数据，与写入 App Group 的快照同构）/
///   示例 / 空态；亮暗独立切换（不随系统）。
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/controls.dart';
import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../app/sheet.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart';
import '../../core/platform/widgets/widget_snapshot.dart';
import '../shared/goal_card.dart' show goalIconData;

class WidgetPreviewPage extends ConsumerStatefulWidget {
  const WidgetPreviewPage({super.key});

  @override
  ConsumerState<WidgetPreviewPage> createState() => _WidgetPreviewPageState();
}

enum _DataSource { live, sample, empty }

class _WidgetPreviewPageState extends ConsumerState<WidgetPreviewPage> {
  var _dark = false;
  var _source = _DataSource.sample;

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(_dark ? Brightness.dark : Brightness.light);
    final snap = _snapshotFor();

    return CupertinoPageScaffold(
      backgroundColor: TargetPalette.of(context).background,
      resizeToAvoidBottomInset: false,
      child: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: AppScreen.safeTop),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  HeaderTextButton(
                    label: Copy.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text('小组件预览', style: AppText.of(context).titleM),
                    ),
                  ),
                  const SizedBox(width: 56),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                children: [
                  _sourceControl(),
                  const SizedBox(height: 16),
                  _brightnessControl(),
                  const SizedBox(height: 24),
                  _label('主屏 · 小（2×2 · 155×155）'),
                  const SizedBox(height: 8),
                  _SmallWidgetFrame(p: p, snap: snap),
                  const SizedBox(height: 24),
                  _label('主屏 · 中 · 今日（4×2 · 329×155）'),
                  const SizedBox(height: 8),
                  _MediumWidgetFrame(
                    p: p,
                    brightness: _dark ? Brightness.dark : Brightness.light,
                    snap: snap,
                  ),
                  const SizedBox(height: 24),
                  _label('主屏 · 中 · 目标（4×2 · 每实例一个目标 · 左右滑预览）'),
                  const SizedBox(height: 8),
                  _buildGoalPager(p),
                  const SizedBox(height: 24),
                  _label('锁屏 · 圆形 / 矩形'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AccessoryCircularFrame(snap: snap),
                      const SizedBox(width: 16),
                      Expanded(child: _AccessoryRectFrame(snap: snap)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _noteCard(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 目标翻页小组件（R13） ----

  List<_GoalPageData> _goalPagesFor() => switch (_source) {
    _DataSource.live => [
      for (final m in buildGoalPages(
        goals: [
          for (final g in ref.watch(goalsProvider).value ?? const <Goal>[])
            if (g.archivedAt == null) g,
        ],
        records: ref.watch(recordsProvider).value ?? const [],
        milestones: ref.watch(milestonesProvider).value ?? const [],
        today: ref.watch(todayProvider),
      ))
        _GoalPageData.fromMap(m),
    ],
    _DataSource.sample => const [
      _GoalPageData(
        name: '学会电吉他',
        iconKey: 'music_note',
        colorKey: 'orange',
        category: '学习与成长',
        latestTitle: '练习第一节课程',
        latestLabel: '今天',
        nextMilestone: '学完初阶课程',
      ),
      _GoalPageData(
        name: '半程马拉松训练',
        iconKey: 'directions_run',
        colorKey: 'green',
        category: '运动',
        latestTitle: '晨跑 8 公里，配速稳定',
        latestLabel: '昨天',
        nextMilestone: '完成一次 15 公里长距离',
      ),
      _GoalPageData(
        name: '每日阅读',
        iconKey: 'auto_stories',
        colorKey: 'teal',
        latestTitle: null,
      ),
    ],
    _DataSource.empty => const [],
  };

  Widget _buildGoalPager(TargetPalette p) {
    final pages = _goalPagesFor();
    final brightness = _dark ? Brightness.dark : Brightness.light;
    // 预览载体：横滑 PageView 逐个查看每个实例的卡片（真机为多个
    // 组件实例叠放，系统原生上下滑动翻页——组件内不做任何自绘翻页）。
    return SizedBox(
      height: 155,
      child: PageView.builder(
        itemCount: pages.isEmpty ? 1 : pages.length,
        itemBuilder: (_, i) => Center(
          child: _WidgetSurface(
            p: p,
            size: const Size(329, 155),
            padding: const EdgeInsets.all(14),
            child: pages.isEmpty
                ? _GoalPagesEmpty(p: p)
                : _GoalPageCard(p: p, brightness: brightness, page: pages[i]),
          ),
        ),
      ),
    );
  }

  // ---- 数据与控制 ----

  _PreviewSnap _snapshotFor() => switch (_source) {
    _DataSource.live => _PreviewSnap.fromMap(
      buildTodaySnapshot(
        goals: ref.watch(goalsProvider).value ?? const <Goal>[],
        records: ref.watch(recordsProvider).value ?? const <ProgressRecord>[],
        milestones: ref.watch(milestonesProvider).value ?? const <Milestone>[],
        today: ref.watch(todayProvider),
        now: DateTime.now(),
      ),
    ),
    _DataSource.sample => const _PreviewSnap(
      count: 3,
      minutes: 95,
      title: '练习第一节课程',
      goalName: '学会电吉他',
      colorKey: 'orange',
    ),
    _DataSource.empty => const _PreviewSnap(count: 0, minutes: 0),
  };

  Widget _sourceControl() {
    return CupertinoSlidingSegmentedControl<_DataSource>(
      groupValue: _source,
      onValueChanged: (s) => setState(() => _source = s!),
      children: {
        for (final s in _DataSource.values)
          s: SegmentedLabel(
            label: switch (s) {
              _DataSource.live => '实时',
              _DataSource.sample => '示例',
              _DataSource.empty => '空态',
            },
            selected: _source == s,
          ),
      },
    );
  }

  Widget _brightnessControl() {
    return CupertinoSlidingSegmentedControl<bool>(
      groupValue: _dark,
      onValueChanged: (s) => setState(() => _dark = s!),
      children: {
        false: SegmentedLabel(label: '浅色', selected: !_dark),
        true: SegmentedLabel(label: '深色', selected: _dark),
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppText.of(context).bodyS
          .copyWith(color: TargetPalette.of(context).onSurfaceVariant),
    );
  }

  Widget _noteCard(BuildContext context) {
    final p = TargetPalette.of(context);
    final text = AppText.of(context);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('「Target · 目标」组件怎么翻页？', style: text.titleS),
          const SizedBox(height: 4),
          Text(
            '添加组件时选择一个目标，每个实例展示一个目标；把多个实例拖到一起'
            '叠放后，即可上下滑动手动翻页（系统原生交互与页点，组件内不自绘）。'
            '不选择目标时回退置顶第一个目标。',
            style: text.bodyS.copyWith(color: p.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text('真机不显示？', style: text.titleS),
          const SizedBox(height: 4),
          Text(
            '扩展 Info.plist 的扩展点标识已由 com.apple.widget-kit-extension 修正为 '
            'com.apple.widgetkit-extension（该拼写错误会导致小组件不出现在添加列表）。'
            '需重新构建安装包（Codemagic → iLoader）后生效。',
            style: text.bodyS.copyWith(color: p.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 预览数据（与 buildTodaySnapshot 的 schema 一一对应）
// ---------------------------------------------------------------------------

class _PreviewSnap {
  const _PreviewSnap({
    required this.count,
    required this.minutes,
    this.title,
    this.goalName,
    this.colorKey,
  });

  factory _PreviewSnap.fromMap(Map<String, Object?> map) => _PreviewSnap(
    count: (map['todayRecordCount'] as int? ?? 0),
    minutes: (map['todayMinutes'] as int? ?? 0),
    title: map['latestTitle'] as String?,
    goalName: map['latestGoalName'] as String?,
    colorKey: map['latestGoalColorKey'] as String?,
  );

  final int count;
  final int minutes;
  final String? title;
  final String? goalName;
  final String? colorKey;
}

// ---------------------------------------------------------------------------
// 主屏小组件（containerBackground 近似 = surfaceAlt 实底 + 发丝描边 + 22 圆角）
// ---------------------------------------------------------------------------

class _WidgetSurface extends StatelessWidget {
  const _WidgetSurface({
    required this.p,
    required this.child,
    this.size,
    this.padding = const EdgeInsets.all(16),
  });

  final TargetPalette p;
  final Widget? child;
  final Size? size;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size?.width,
      height: size?.height,
      padding: padding,
      decoration: BoxDecoration(
        color: p.surfaceAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.divider, width: 0.5),
      ),
      child: child,
    );
  }
}

/// systemSmall：今日记录数大数字 +「条」+ 说明。
class _SmallWidgetFrame extends StatelessWidget {
  const _SmallWidgetFrame({required this.p, required this.snap});

  final TargetPalette p;
  final _PreviewSnap snap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _WidgetSurface(
        p: p,
        size: const Size(155, 155),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${snap.count}',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: p.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '条',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: p.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '今天的进展记录',
              style: TextStyle(fontSize: 13, color: p.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// systemMedium：左 = 今日计数 + 分钟；右 = 最近记录。
class _MediumWidgetFrame extends StatelessWidget {
  const _MediumWidgetFrame({
    required this.p,
    required this.brightness,
    required this.snap,
  });

  final TargetPalette p;

  /// 目标取色所用亮暗（与 [p] 同档）。
  final Brightness brightness;
  final _PreviewSnap snap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _WidgetSurface(
        p: p,
        size: const Size(329, 155),
        child: Row(
          children: [
            // 左列：计数 + 分钟
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${snap.count}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: p.onSurface,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '条',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: p.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (snap.minutes > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '投入 ${snap.minutes} 分钟',
                      style: TextStyle(fontSize: 12, color: p.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            // 竖分隔
            Container(width: 0.5, color: p.divider),
            const SizedBox(width: 16),
            // 右列：最近记录
            Expanded(
              child: snap.title == null
                  ? Center(
                      child: Text(
                        '还没有记录',
                        style: TextStyle(
                          fontSize: 15,
                          color: p.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '最近记录',
                          style: TextStyle(
                            fontSize: 11,
                            color: p.onSurfaceTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          snap.title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: p.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (snap.goalName != null)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: GoalPalette.byKey(
                                    snap.colorKey ?? 'gray',
                                    brightness: brightness,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  snap.goalName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: p.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 锁屏小组件（恒深色渲染）
// ---------------------------------------------------------------------------

/// accessoryCircular：今日计数。
class _AccessoryCircularFrame extends StatelessWidget {
  const _AccessoryCircularFrame({required this.snap});

  final _PreviewSnap snap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 66,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        shape: BoxShape.circle,
      ),
      child: Text(
        '${snap.count}',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFFF5F5F7),
        ),
      ),
    );
  }
}

/// accessoryRectangular：最近记录标题 + 目标名。
class _AccessoryRectFrame extends StatelessWidget {
  const _AccessoryRectFrame({required this.snap});

  final _PreviewSnap snap;

  @override
  Widget build(BuildContext context) {
    final hasTitle = snap.title != null;
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hasTitle ? snap.title! : '记录一笔',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF5F5F7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasTitle ? (snap.goalName ?? '') : '每一次尝试，都值得留下。',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xB3F5F5F7)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 目标翻页小组件（R13 · systemMedium 4×2 · 每个目标一屏）
// 版式镜像 Swift GoalPageCard / 目标页置顶大卡；预览用 Material 图标，
// 真机渲染为 SF Symbols 近似映射。
// ---------------------------------------------------------------------------

class _GoalPageData {
  const _GoalPageData({
    this.id,
    required this.name,
    required this.iconKey,
    required this.colorKey,
    this.category,
    this.latestTitle,
    this.latestLabel,
    this.nextMilestone,
  });

  factory _GoalPageData.fromMap(Map<String, Object?> map) => _GoalPageData(
    id: map['id'] as String?,
    name: map['name']! as String,
    iconKey: map['iconKey']! as String,
    colorKey: map['colorKey']! as String,
    category: map['category'] as String?,
    latestTitle: map['latestTitle'] as String?,
    latestLabel: map['latestLabel'] as String?,
    nextMilestone: map['nextMilestone'] as String?,
  );

  /// 真机上供 AppIntent 参数选择/还原匹配（预览内未用）。
  final String? id;
  final String name;
  final String iconKey;
  final String colorKey;
  final String? category;
  final String? latestTitle;
  final String? latestLabel;
  final String? nextMilestone;
}

/// 单页目标卡（镜像 Swift GoalPageCard / 目标页置顶大卡）：
/// 顶行图标 tile + 目标名 + 分类 → 最近记录两端行 → 标题 → 里程碑行。
class _GoalPageCard extends StatelessWidget {
  const _GoalPageCard({
    required this.p,
    required this.brightness,
    required this.page,
  });

  final TargetPalette p;
  final Brightness brightness;
  final _GoalPageData page;

  @override
  Widget build(BuildContext context) {
    final color = GoalPalette.byKey(page.colorKey, brightness: brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(goalIconData(page.iconKey), size: 15, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                page.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.onSurface,
                ),
              ),
            ),
            if (page.category != null) ...[
              const SizedBox(width: 8),
              Text(
                page.category!,
                maxLines: 1,
                style: TextStyle(fontSize: 11, color: p.onSurfaceTertiary),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (page.latestTitle != null) ...[
          Row(
            children: [
              Text(
                '最近记录',
                style: TextStyle(fontSize: 11, color: p.onSurfaceTertiary),
              ),
              const Spacer(),
              Text(
                page.latestLabel ?? '',
                style: TextStyle(fontSize: 11, color: p.onSurfaceTertiary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            page.latestTitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: p.onSurface,
            ),
          ),
        ] else
          Text(
            '尚未记录',
            style: TextStyle(fontSize: 12, color: p.onSurfaceTertiary),
          ),
        const Spacer(),
        if (page.nextMilestone != null)
          Row(
            children: [
              Icon(CupertinoIcons.flag, size: 10, color: p.onSurfaceTertiary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '下个里程碑 · ${page.nextMilestone}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: p.onSurfaceVariant),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// 翻页小组件空态（无目标）。
class _GoalPagesEmpty extends StatelessWidget {
  const _GoalPagesEmpty({required this.p});

  final TargetPalette p;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(CupertinoIcons.scope, size: 20, color: p.onSurfaceTertiary),
        const SizedBox(height: 6),
        Text(
          '还没有目标',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: p.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '在 App 里创建第一个目标',
          style: TextStyle(fontSize: 12, color: p.onSurfaceVariant),
        ),
      ],
    );
  }
}
