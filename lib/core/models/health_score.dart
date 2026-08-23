/// 三大类健康度（004 US2 · FR-004 · contracts/health-score.md 口径冻结）。
///
/// 减分制：每类满分 100 起，近 7 天零记录的活跃目标每个扣 3 分，
/// clamp(0, 100)。窗口 W = [today−6, today] 含今日滚动；打卡/补签
/// 同计（一行有效记录即令该目标退出零记录集合）；暂停/归档不参与；
/// 类内零活跃 = 无数据态（非满分非 0，UI 不显示数字）。
/// 状态式无记账：goals/checkIns 任一变化或跨天由 provider 整体重算。
library;

import 'calendar_types.dart';
import 'entities.dart';
import 'goal_icon_catalog.dart';

/// 单类读数：类内活跃数 + 近 7 天零记录数，分数为派生值。
class CategoryHealth {
  const CategoryHealth({
    required this.category,
    required this.activeGoals,
    required this.zeroRecordGoals,
  });

  final MajorCategory category;

  /// |A(c)|：类内活跃目标数（暂停/归档不计）。
  final int activeGoals;

  /// |Z(c)|：类内近 7 天（含今日）零有效记录的活跃目标数。
  final int zeroRecordGoals;

  /// 无数据态判定（UI：空置环 + 类名弱化，不显示数字）。
  bool get hasData => activeGoals > 0;

  /// score(c) = clamp(100 − 3 × |Z(c)|, 0, 100)；无数据态分数无意义。
  int get score => hasData ? (100 - 3 * zeroRecordGoals).clamp(0, 100) : 0;
}

/// 三大类快照（今日页三环数据源）。
class HealthSnapshot {
  const HealthSnapshot({required this.byCategory});

  /// 三键全量（健康/习惯/目标），零活跃类给 activeGoals=0 的无数据态。
  final Map<MajorCategory, CategoryHealth> byCategory;

  /// 全库零活跃目标 → 环区整体让位空态新建 CTA。
  bool get isEmpty => byCategory.values.every((c) => !c.hasData);
}

/// 全量重算（纯函数，注入 today 便于测试跨天窗口右移）。
///
/// 目标 → 大类经 iconKey → [GoalIconCatalog] 领域 → [MajorCategory]
/// 派生（FR-014 静态归属）；撤销行（revoked）不构成记录。
HealthSnapshot evaluateHealth({
  required List<Goal> goals,
  required List<CheckIn> checkIns,
  required LocalDate today,
}) {
  final windowStart = today.addDays(-6); // W = [today−6, today]
  final recorded = <String>{
    for (final r in checkIns)
      if (r.isValid && !r.day.isBefore(windowStart) && !r.day.isAfter(today))
        r.goalId,
  };
  final healths = <MajorCategory, CategoryHealth>{};
  for (final c in MajorCategory.values) {
    final active = goals
        .where(
          (g) =>
              g.status == GoalStatus.active &&
              GoalIconCatalog.byKey(g.iconKey).domain.major == c,
        )
        .toList();
    final zero = active.where((g) => !recorded.contains(g.id)).length;
    healths[c] = CategoryHealth(
      category: c,
      activeGoals: active.length,
      zeroRecordGoals: zero,
    );
  }
  return HealthSnapshot(byCategory: healths);
}
