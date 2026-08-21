/// Riverpod 供货层：DB / 仓储 / 网关 / 时钟。
///
/// 测试与 Debug 用 ProviderScope overrides 替换（时钟→FixedDateProvider、
/// DB→NativeDatabase.memory）。
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart' show AppDatabase;
import '../core/db/connection.dart';
import '../core/db/repositories.dart';
import '../core/models/calendar_types.dart';
import '../core/models/date_provider.dart';
import '../core/models/entities.dart';
import '../core/platform/file_pick_gateway.dart';
import '../core/platform/gateways.dart';
import '../core/platform/notification_gateway.dart';
import '../core/platform/share_gateway.dart';
import '../core/platform/widget_gateway.dart';
import '../core/stats/busy_mode_service.dart';
import '../core/stats/check_in_service.dart';
import '../core/stats/settlement_service.dart';
import '../core/stats/stats_engine.dart';
import '../features/settings/reminder_service.dart';

/// 注入时钟（research D6）；Debug 时钟菜单（T049）运行时切换实现
/// （StateProvider：debug 菜单换 FixedDateProvider 后 invalidate today/stats）。
final dateProviderProvider =
    StateProvider<DateProvider>((ref) => const SystemDateProvider());

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openConnection());
  ref.onDispose(db.close);
  return db;
});

final goalRepoProvider = Provider((ref) => GoalRepository(ref.watch(dbProvider)));
final checkInRepoProvider =
    Provider((ref) => CheckInRepository(ref.watch(dbProvider)));

/// 打卡服务（T025）：统一注入时钟入口。
final checkInServiceProvider = Provider(
    (ref) => CheckInService(ref.watch(checkInRepoProvider), ref.watch(dateProviderProvider)));
final reminderRepoProvider =
    Provider((ref) => ReminderRepository(ref.watch(dbProvider)));
final reviewRepoProvider =
    Provider((ref) => ReviewRepository(ref.watch(dbProvider)));

/// 周回顾流（回顾页 + 结算幂等查询）。
final reviewsProvider = StreamProvider<List<WeeklyReview>>(
    (ref) => ref.watch(reviewRepoProvider).watchAll());

/// 周结算（US4）：启动/数据变化时幂等结算上一周。
final settlementServiceProvider = Provider((ref) => WeeklySettlementService(
    ref.watch(goalRepoProvider),
    ref.watch(checkInRepoProvider),
    ref.watch(reviewRepoProvider)));

/// 忙碌收尾（2026-08-21 裁决：忙碌态全 App 移除）：入口与视图已删，
/// 服务仅用于 App 启动时自动收尾升级前遗留的活跃降档会话（见 app.dart）。
final busyModeServiceProvider =
    Provider((ref) => BusyModeService(ref.watch(goalRepoProvider)));
final settingsRepoProvider =
    Provider((ref) => SettingsRepository(ref.watch(dbProvider)));

/// Settings 单例行流（今日占位/各页共用）。
final settingsProvider = StreamProvider<Settings>(
    (ref) => ref.watch(settingsRepoProvider).watch());

/// 提醒行流（设置页展示 + app 层 replan 触发）。
final remindersProvider = StreamProvider<List<Reminder>>(
    (ref) => ref.watch(reminderRepoProvider).watchAll());

/// 提醒调度（US3）：数据/设置变化后全量重建 pending 通知。
final reminderServiceProvider = Provider((ref) => ReminderService(
    ref.watch(notificationGatewayProvider), ref.watch(reminderRepoProvider)));

// ---------------------------------------------------------------------------
// 领域数据流 → 统计引擎（research D13：仓储转发重算，UI 只读结果）
// ---------------------------------------------------------------------------

final goalsProvider =
    StreamProvider<List<Goal>>((ref) => ref.watch(goalRepoProvider).watchGoals());

final versionsProvider = StreamProvider<List<FrequencyVersion>>(
    (ref) => ref.watch(goalRepoProvider).watchAllVersions());

final checkInsProvider = StreamProvider<List<CheckIn>>(
    (ref) => ref.watch(checkInRepoProvider).watchAll());

final busySessionsProvider = StreamProvider<List<BusyModeSession>>(
    (ref) => ref.watch(goalRepoProvider).watchSessions());

/// 里程碑步骤流（目标卡片/里程碑详情共用）。
final stepsProvider = StreamProvider.family<List<MilestoneStep>, String>(
    (ref, goalId) => ref.watch(goalRepoProvider).watchStepsOf(goalId));

/// 注入时钟的"今天"（自然日，本地时区）。
final todayProvider = Provider<LocalDate>(
    (ref) => ref.watch(dateProviderProvider).today);

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
  final versions = ref.watch(versionsProvider).value;
  final checkIns = ref.watch(checkInsProvider).value;
  final sessions = ref.watch(busySessionsProvider).value;
  final today = ref.watch(todayProvider);
  if (goals == null ||
      versions == null ||
      checkIns == null ||
      sessions == null) {
    return null;
  }
  return StatsEngine.evaluate(
    goals: goals,
    frequencyVersions: versions,
    busySessions: sessions,
    checkIns: checkIns,
    today: today,
  );
});

final notificationGatewayProvider =
    Provider<NotificationGateway>((ref) => createNotificationGateway());

final widgetGatewayProvider =
    Provider<WidgetGateway>((ref) => createWidgetGateway());

final shareGatewayProvider =
    Provider<ShareGateway>((ref) => createShareGateway());

final filePickGatewayProvider =
    Provider<FilePickGateway>((ref) => createFilePickGateway());
