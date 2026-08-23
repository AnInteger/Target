/// 关注卡轮播（004 T021，v2-today.html 冻结稿 .caro/.track/.fcard）。
///
/// 每个活跃目标一张大类渐变卡（R3 同构梯度 MajorGradients）：状态
/// 标签 ● + 目标名 + 一句话描述 + 白胶囊主行动（→ 该目标记录动线，
/// T022 挂载时接 /goal/{id}）+ 辅助行（短期 = 倒计时；习惯/长期 =
/// 连击，口径同详情页 meta 胶囊）。PageView viewportFraction 露邻卡
/// 边；卡序 = 最近互动优先（max(最新有效 CheckIn.createdAt,
/// goal.createdAt) 降序，派生不落库）；单卡退化无页点。节头
/// 「关注 · N」与「查看全部」入口属今日页挂载（T022）。005 D3：
/// 全出血——LayoutBuilder 取全宽 W 求 viewportFraction=(W−2·padX)/W
/// （PageView padEnds 默认 true 双端各补半差 = padX），首卡左缘/末卡
/// 右缘恒贴页基准、对侧邻卡 peek 恒 = padX；卡占满净宽槽位，无卡间内距。
library;

import 'package:flutter/material.dart';

import '../../app/design_tokens.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/entities.dart';
import '../../core/models/goal_icon_catalog.dart';
import '../../core/stats/stats_engine.dart';

/// 卡高（冻结稿 .fcard 内容高度 + s5 双侧内距）：固定高度供 PageView
/// 在纵向 ListView 内占位；卡内底部行动行经 [Spacer] 沉底对齐。
const double kFocusCardHeight = 208;

class FocusCarousel extends StatefulWidget {
  const FocusCarousel({
    super.key,
    required this.goals,
    required this.checkIns,
    required this.stats,
    required this.today,
    required this.onOpenGoal,
  });

  /// 全量目标（组件内过滤 active——暂停/删除经流实时移出轮播）。
  final List<Goal> goals;
  final List<CheckIn> checkIns;
  final StatsEvaluation stats;
  final LocalDate today;

  /// 主行动按钮回调（进该目标记录动线）。
  final void Function(Goal goal) onOpenGoal;

  @override
  State<FocusCarousel> createState() => _FocusCarouselState();
}

class _FocusCarouselState extends State<FocusCarousel> {
  /// 按净宽求出的 fraction 建 controller（005 D3；viewportFraction 构
  /// 造期定死，宽变时重建——见 build 内 LayoutBuilder）。
  PageController? _controller;
  double _fraction = -1;
  int _page = 0;
  PageController? _retired;

  @override
  void dispose() {
    _controller?.dispose();
    _retired?.dispose();
    super.dispose();
  }

  /// 卡序派生（每次 build 纯计算）：仅 active，按最近互动降序。
  List<Goal> _ordered() {
    final byGoal = <String, DateTime>{};
    for (final c in widget.checkIns) {
      if (!c.isValid) continue;
      final key = byGoal[c.goalId];
      if (key == null || c.createdAt.isAfter(key)) {
        byGoal[c.goalId] = c.createdAt;
      }
    }
    final active = widget.goals
        .where((g) => g.status == GoalStatus.active)
        .toList();
    active.sort((a, b) {
      final ka = _sortKey(byGoal[a.id], a);
      final kb = _sortKey(byGoal[b.id], b);
      return kb.compareTo(ka); // 降序：最近互动在前
    });
    return active;
  }

  /// 互动键 = max(最新有效记录 createdAt, 目标创建日)。
  DateTime _sortKey(DateTime? latest, Goal goal) {
    final created = goal.createdAt.atStartOfDay;
    return latest != null && latest.isAfter(created) ? latest : created;
  }

  @override
  Widget build(BuildContext context) {
    final goals = _ordered();
    if (goals.isEmpty) return const SizedBox.shrink();
    final page = _page.clamp(0, goals.length - 1);
    // 005 D3（FR-004）：全出血——净宽 = W−2·padX；padEnds 双端各补
    // (W−W·f)/2 = padX，故首卡左缘/末卡右缘/对侧 peek 恒 = padX。
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fraction = width > 2 * AppScreen.padX
            ? (width - 2 * AppScreen.padX) / width
            : 1.0;
        if (_controller == null || (fraction - _fraction).abs() > 0.001) {
          // 宽变（旋转/分屏）重建 controller 保住当前页；旧件待帧末旧
          // PageView 分离后再弃置（build 期即时 dispose 会打断在挂位置）。
          _retired = _controller;
          _controller = PageController(
            viewportFraction: fraction,
            initialPage: page,
          );
          _fraction = fraction;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _retired?.dispose();
            _retired = null;
          });
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: kFocusCardHeight,
              child: PageView.builder(
                controller: _controller!,
                itemCount: goals.length,
                onPageChanged: (i) => setState(() => _page = i),
                // 卡占满净宽槽位（342@390）——无卡间内距，peek 即邻卡本体。
                itemBuilder: (context, i) => _FocusCard(
                  goal: goals[i],
                  stats: widget.stats,
                  today: widget.today,
                  onTap: () => widget.onOpenGoal(goals[i]),
                ),
              ),
            ),
            // 单卡退化：无滑动指示（冻结稿 .dots，去彩 = on-surface/divider）。
            if (goals.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.s4),
                child: Row(
                  // 004 T022：页点区挂 key——单卡退化（无页点）测试锚点。
                  key: const ValueKey('focusDots'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final (i, _) in goals.indexed)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == page ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == page
                              ? TargetPalette.of(context).onSurface
                              : TargetPalette.of(context).divider,
                          borderRadius: AppRadius.rFull,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 单张关注卡（冻结稿 .fcard：大类渐变底 + 白字，右上 40px 白透
/// 图标格；状态胶囊 → 目标名 → 一句话描述 → 行动行沉底）。
class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.goal,
    required this.stats,
    required this.today,
    required this.onTap,
  });

  final Goal goal;
  final StatsEvaluation stats;
  final LocalDate today;
  final VoidCallback onTap;

  /// 状态标签（板 1/2/3 拟合）：短期推进中或今日已记录 → 进行中；
  /// 否则 → 待办（今日该做未做）。
  String get _tag => goal.isShortTerm || stats.dayStatusOf(goal.id).done
      ? Copy.focusTagActive
      : Copy.focusTagTodo;

  /// 一句话描述：怎样算做到 → 为什么 → 提示场景，取先非空者。
  String? get _desc {
    for (final s in [goal.successCriterion, goal.motivation, goal.cueScene]) {
      if (s != null && s.trim().isNotEmpty) return s;
    }
    return null;
  }

  /// 辅助行（单行首选信号，口径同详情页 meta 胶囊）：短期 = 距截止
  /// 天数；习惯/长期 = 连击（0 连击无辅助行）。
  String? _meta() {
    if (goal.isShortTerm) {
      return Copy.deadlineCountdownMeta(goal.deadline!.differenceInDays(today));
    }
    final streak = stats.streakOf(goal.id);
    return streak > 0 ? Copy.streakMeta(streak) : null;
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final gradient = MajorGradients.byKey(
      GoalIconCatalog.byKey(goal.iconKey).domain.major.name,
    );
    final meta = _meta();
    final white = Colors.white;

    return SizedBox.expand(
      // 004 T022：卡根挂 goal id key——测试翻页定位（露边轮播邻卡
      // onstage 但不可点，须以 hitTestable 判定当前页）。
      key: ValueKey('focusCard-${goal.id}'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradient.a.of(context), gradient.b.of(context)],
          ),
          borderRadius: AppRadius.rLg,
          boxShadow: palette.shadowMid,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.s5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 状态胶囊（.tag）：白 22% 底 + ● 前缀白字。
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 3,
                        horizontal: AppSpace.s2,
                      ),
                      decoration: BoxDecoration(
                        color: white.withValues(alpha: 0.22),
                        borderRadius: AppRadius.rFull,
                      ),
                      child: Text(
                        '● $_tag',
                        style: theme.textTheme.labelS.copyWith(
                          color: white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    Text(
                      goal.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleM.copyWith(color: white),
                    ),
                    if (_desc != null) ...[
                      const SizedBox(height: AppSpace.s1),
                      Text(
                        _desc!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyS.copyWith(
                          color: white.withValues(alpha: 0.85),
                          height: 1.6,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        // 主行动白胶囊（.go）：中性墨字，→ 记录动线。
                        Material(
                          color: white,
                          borderRadius: AppRadius.rFull,
                          child: InkWell(
                            onTap: onTap,
                            borderRadius: AppRadius.rFull,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpace.s2,
                                horizontal: AppSpace.s5,
                              ),
                              child: Text(
                                Copy.goalCheckInAction,
                                style: theme.textTheme.bodyM.copyWith(
                                  color: kFocusGoInk,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (meta != null) ...[
                          const SizedBox(width: AppSpace.s3),
                          Expanded(
                            child: Text(
                              meta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyS.copyWith(
                                color: white.withValues(alpha: 0.85),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // 右上图标格（.mini）：白 18% 底圆角格 + 白色目标图标。
            Positioned(
              top: AppSpace.s4,
              right: AppSpace.s4,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.rMd,
                ),
                child: Icon(
                  GoalIconCatalog.byKey(goal.iconKey).icon,
                  size: 22,
                  color: white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
