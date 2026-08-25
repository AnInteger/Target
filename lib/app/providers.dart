/// Riverpod 供货层：DB / 仓储 / 网关 / 时钟。
///
/// 测试与 Debug 用 ProviderScope overrides 替换（时钟→FixedDateProvider、
/// DB→NativeDatabase.memory）。
library;

import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart' show AppDatabase;
import '../core/db/connection.dart';
import '../core/db/repositories.dart';
import '../core/db/progress_repository.dart';
import '../core/models/calendar_types.dart';
import '../core/models/date_provider.dart';
import '../core/models/entities.dart';
import '../core/models/goal_advice.dart';
import '../core/models/goal_progress.dart';
import '../core/platform/file_pick_gateway.dart';
import '../core/platform/gateways.dart';
import '../core/platform/notification_gateway.dart';
import '../core/platform/share_gateway.dart';
import '../core/platform/widget_gateway.dart';
import '../core/stats/check_in_service.dart';
import '../core/stats/stats_engine.dart';
import '../features/settings/reminder_service.dart';

/// 注入时钟（research D6）；Debug 时钟菜单（T049）运行时切换实现
/// （StateProvider：debug 菜单换 FixedDateProvider 后 invalidate today/stats）。
final dateProviderProvider = StateProvider<DateProvider>(
  (ref) => const SystemDateProvider(),
);

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
});

final goalRepoProvider = Provider(
  (ref) => GoalRepository(ref.watch(dbProvider)),
);
final checkInRepoProvider = Provider(
  (ref) => CheckInRepository(ref.watch(dbProvider)),
);
final progressRepoProvider = Provider(
  (ref) => ProgressRepository(ref.watch(dbProvider)),
);

/// 打卡服务（T025）：统一注入时钟入口。
final checkInServiceProvider = Provider(
  (ref) => CheckInService(
    ref.watch(checkInRepoProvider),
    ref.watch(dateProviderProvider),
  ),
);
final reminderRepoProvider = Provider(
  (ref) => ReminderRepository(ref.watch(dbProvider)),
);
final settingsRepoProvider = Provider(
  (ref) => SettingsRepository(ref.watch(dbProvider)),
);

/// Settings 单例行流（今日占位/各页共用）。
final settingsProvider = StreamProvider<Settings>(
  (ref) => ref.watch(settingsRepoProvider).watch(),
);

/// 004 T004（research D2）：主题偏好三档注入 MaterialApp.themeMode。
/// 未加载/NULL → system（= 003 完结态行为，存量用户零感知）；
/// Settings 流变化即时生效（「我的」页单选行写入 → 此处重算）。
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(settingsProvider).valueOrNull?.themeMode;
  return switch (mode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// 账号资料流（003 T018：nickname/avatarKey 两列，今日账号区与
/// 我的页账号卡同源 watch）。
final profileProvider = StreamProvider<Profile>(
  (ref) => ref.watch(settingsRepoProvider).watchProfile(),
);

/// 提醒行流（设置页展示 + app 层 replan 触发）。
final remindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(reminderRepoProvider).watchAll(),
);

/// 提醒调度（US3）：数据/设置变化后全量重建 pending 通知。
final reminderServiceProvider = Provider(
  (ref) => ReminderService(
    ref.watch(notificationGatewayProvider),
    ref.watch(reminderRepoProvider),
  ),
);

// ---------------------------------------------------------------------------
// 领域数据流 → 统计引擎（research D13：仓储转发重算，UI 只读结果）
// ---------------------------------------------------------------------------

final goalsProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(goalRepoProvider).watchGoals(),
);

final checkInsProvider = StreamProvider<List<CheckIn>>(
  (ref) => ref.watch(checkInRepoProvider).watchAll(),
);

/// 里程碑步骤流（目标卡片/里程碑详情共用）。
final stepsProvider = StreamProvider.family<List<MilestoneStep>, String>(
  (ref, goalId) => ref.watch(goalRepoProvider).watchStepsOf(goalId),
);

final allStepsProvider = StreamProvider<List<MilestoneStep>>(
  (ref) => ref.watch(goalRepoProvider).watchAllSteps(),
);

/// 注入时钟的"今天"（自然日，本地时区）。
final todayProvider = Provider<LocalDate>(
  (ref) => ref.watch(dateProviderProvider).today,
);

/// 跨天 0 点 ticker（research D13）：到点 invalidate todayProvider →
/// statsProvider 重算 → app 层快照监听器重写小组件快照。
/// 被 app.dart watch 以激活；widget 测试用 overrideWith((ref) {}) 关闭。
final dayTickerProvider = Provider<void>((ref) {
  Timer? timer;
  void schedule() {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    timer = Timer(next.difference(now), () {
      ref.invalidate(todayProvider);
      schedule();
    });
  }

  schedule();
  ref.onDispose(() => timer?.cancel());
});

/// 统计评估（全部就绪前为 null，UI 呈现加载态）。
final statsProvider = Provider<StatsEvaluation?>((ref) {
  final goals = ref.watch(goalsProvider).value;
  final checkIns = ref.watch(checkInsProvider).value;
  final today = ref.watch(todayProvider);
  if (goals == null || checkIns == null) {
    return null;
  }
  return StatsEngine.evaluate(goals: goals, checkIns: checkIns, today: today);
});

/// 当前目标管理状态的一体化只读模型。所有依赖流到齐后才出值；页面无需
/// 自行拼接目标、记录、里程碑或复制评分与建议规则。
final goalProgressProvider = Provider<GoalProgressSnapshot?>((ref) {
  final goals = ref.watch(goalsProvider).value;
  final checkIns = ref.watch(checkInsProvider).value;
  final steps = ref.watch(allStepsProvider).value;
  final today = ref.watch(todayProvider);
  if (goals == null || checkIns == null || steps == null) return null;
  final groupedSteps = <String, List<MilestoneStep>>{};
  for (final step in steps) {
    groupedSteps.putIfAbsent(step.goalId, () => []).add(step);
  }
  final evaluation = evaluateGoalProgress(
    goals: goals,
    checkIns: checkIns,
    milestones: groupedSteps,
    today: today,
  );
  return buildProgressSnapshot(evaluation: evaluation, goals: goals);
});

final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => createNotificationGateway(),
);

final widgetGatewayProvider = Provider<WidgetGateway>(
  (ref) => createWidgetGateway(),
);

final shareGatewayProvider = Provider<ShareGateway>(
  (ref) => createShareGateway(),
);

final filePickGatewayProvider = Provider<FilePickGateway>(
  (ref) => createFilePickGateway(),
);
