/// Riverpod 供货层：DB / 仓储 / 网关 / 时钟 / 领域数据流（v3）。
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
import '../core/models/calendar_types.dart';
import '../core/models/date_provider.dart';
import '../core/models/entities.dart';
import '../core/platform/file_pick_gateway.dart';
import '../core/platform/gateways.dart';
import '../core/platform/image_pick_gateway.dart';
import '../core/platform/notification_gateway.dart';
import '../core/platform/share_gateway.dart';
import '../core/platform/widget_gateway.dart';
import '../core/stats/stats_engine.dart';
import '../features/settings/reminder_service.dart';

/// 注入时钟（Debug 菜单运行时可换 FixedDateProvider）。
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
final milestoneRepoProvider = Provider(
  (ref) => MilestoneRepository(ref.watch(dbProvider)),
);
final recordRepoProvider = Provider(
  (ref) => RecordRepository(ref.watch(dbProvider)),
);
final reminderRepoProvider = Provider(
  (ref) => ReminderRepository(ref.watch(dbProvider)),
);
final settingsRepoProvider = Provider(
  (ref) => SettingsRepository(ref.watch(dbProvider)),
);

/// Settings 单例行流。
final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepoProvider).watch(),
);

/// 主题三档（NULL=跟随系统）。
final themeModeProvider = Provider<ThemeMode>((ref) {
  final mode = ref.watch(settingsProvider).valueOrNull?.themeMode;
  return switch (mode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

/// 提醒行流（设置页展示 + app 层 replan 触发）。
final remindersProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(reminderRepoProvider).watchAll(),
);

final reminderServiceProvider = Provider(
  (ref) => ReminderService(ref.watch(notificationGatewayProvider)),
);

// ---------------------------------------------------------------------------
// 领域数据流
// ---------------------------------------------------------------------------

final goalsProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(goalRepoProvider).watchGoals(),
);

final recordsProvider = StreamProvider<List<ProgressRecord>>(
  (ref) => ref.watch(recordRepoProvider).watchAll(),
);

final milestonesProvider = StreamProvider<List<Milestone>>(
  (ref) => ref.watch(milestoneRepoProvider).watchAll(),
);

final milestonesOfProvider =
    StreamProvider.family<List<Milestone>, String>(
      (ref, goalId) => ref.watch(milestoneRepoProvider).watchOf(goalId),
    );

final recordsOfProvider = StreamProvider.family<List<ProgressRecord>, String>(
  (ref, goalId) => ref.watch(recordRepoProvider).watchOf(goalId),
);

/// 注入时钟的"今天"（自然日，本地时区）。
final todayProvider = Provider<LocalDate>(
  (ref) => ref.watch(dateProviderProvider).today,
);

/// 跨天 0 点 ticker：到点 invalidate todayProvider → 统计/快照重算。
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

/// 动态页一体化只读模型（周切换由页面自管 state）。
typedef ActivityData = ({WeekInvestment week, MilestoneSummary milestones});

final activityProvider = Provider<ActivityData?>((ref) {
  final records = ref.watch(recordsProvider).value;
  final milestones = ref.watch(milestonesProvider).value;
  final today = ref.watch(todayProvider);
  if (records == null || milestones == null) return null;
  final week = WeekStart.containing(today);
  return (
    week: StatsEngine.weekInvestment(records, week),
    milestones: StatsEngine.milestoneSummary(milestones, week),
  );
});

/// 网关。
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

/// 头像选图（相册/拍照；settings.avatarKey 存 base64 data URL）。
final imagePickGatewayProvider = Provider((ref) => ImagePickGateway());
