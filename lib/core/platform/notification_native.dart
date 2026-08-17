/// 原生通知实现（flutter_local_notifications 22 / iOS Darwin）。
library;

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/calendar_types.dart';
import 'gateways.dart';

class NativeNotificationGateway implements NotificationGateway {
  NativeNotificationGateway() {
    tzdata.initializeTimeZones();
  }

  final _plugin = fln.FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _plugin.initialize(
      settings: const fln.InitializationSettings(
        iOS: fln.DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await _ensureInit();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        fln.IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return granted ?? false;
  }

  @override
  Future<bool> get isPermissionGranted async {
    await _ensureInit();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        fln.IOSFlutterLocalNotificationsPlugin>();
    // v22 未提供只读查询：以"未拒绝过请求"近似——首次请求后系统记住了答复。
    return await ios?.requestPermissions() ?? false;
  }

  @override
  Future<void> scheduleDaily({
    required int id,
    required LocalTime time,
    required String title,
    required String body,
  }) async {
    await _ensureInit();
    await cancel(id);
    final now = DateTime.now();
    var fireOn = time.on(LocalDate.fromDateTime(now));
    if (!fireOn.isAfter(now)) {
      fireOn = time.on(LocalDate.fromDateTime(now).addDays(1));
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(fireOn, tz.local),
      notificationDetails: const fln.NotificationDetails(
        iOS: fln.DarwinNotificationDetails(),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: fln.DateTimeComponents.time, // 每日重复
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Stream<NotificationBanner> get banners => const Stream.empty();
}

NotificationGateway createNotificationGateway() =>
    NativeNotificationGateway();
