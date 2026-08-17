/// Riverpod 供货层：DB / 仓储 / 网关 / 时钟。
///
/// 测试与 Debug 用 ProviderScope overrides 替换（时钟→FixedDateProvider、
/// DB→NativeDatabase.memory）。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/db/app_database.dart';
import '../core/db/connection.dart';
import '../core/db/repositories.dart';
import '../core/models/date_provider.dart';
import '../core/models/entities.dart';
import '../core/platform/file_pick_gateway.dart';
import '../core/platform/gateways.dart';
import '../core/platform/notification_gateway.dart';
import '../core/platform/share_gateway.dart';
import '../core/platform/widget_gateway.dart';

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
final reminderRepoProvider =
    Provider((ref) => ReminderRepository(ref.watch(dbProvider)));
final reviewRepoProvider =
    Provider((ref) => ReviewRepository(ref.watch(dbProvider)));
final settingsRepoProvider =
    Provider((ref) => SettingsRepository(ref.watch(dbProvider)));

/// Settings 单例行流（今日占位/各页共用）。
final settingsProvider = StreamProvider<Settings>(
    (ref) => ref.watch(settingsRepoProvider).watch());

final notificationGatewayProvider =
    Provider<NotificationGateway>((ref) => createNotificationGateway());

final widgetGatewayProvider =
    Provider<WidgetGateway>((ref) => createWidgetGateway());

final shareGatewayProvider =
    Provider<ShareGateway>((ref) => createShareGateway());

final filePickGatewayProvider =
    Provider<FilePickGateway>((ref) => createFilePickGateway());
