/// Riverpod 供货层：DB / 仓储 / 网关 / 时钟。
///
/// 测试与 Debug 用 ProviderScope overrides 替换（时钟→FixedDateProvider、
/// DB→NativeDatabase.memory）。
library;

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
import '../core/stats/check_in_service.dart';
import '../core/stats/stats_engine.dart';

/// 注入时钟（research D6）；Debug 时钟菜单（T049）运行时切换实现。
final dateProviderProvider = Provider<DateProvider>((ref) {
  return SystemDateProvider();
});

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
final settingsRepoProvider =
    Provider((ref) => SettingsRepository(ref.watch(dbProvider)));

/// Settings 单例行流（今日占位/各页共用）。
final settingsProvider = StreamProvider<Settings>(
    (ref) => ref.watch(settingsRepoProvider).watch());

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
