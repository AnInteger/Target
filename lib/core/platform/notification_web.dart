/// Web 通知实现：页内横幅模拟（无系统通知依赖，FR-007 精神：
/// Web 上通知缺席不阻塞任何功能）。
library;

import 'dart:async';

import '../models/calendar_types.dart';
import 'gateways.dart';

class SimulatedNotificationGateway implements NotificationGateway {
  final _banners = StreamController<NotificationBanner>.broadcast();
  final _timers = <int, Timer>{};
  final bool _granted = true; // Web 模拟默认"授权"（页内呈现，无系统权限）

  @override
  Future<bool> requestPermission() async => _granted;

  @override
  Future<bool> get isPermissionGranted async => _granted;

  @override
  Future<void> scheduleDaily({
    required int id,
    required LocalTime time,
    required String title,
    required String body,
  }) async {
    await cancel(id);
    final fireAt = _nextOccurrence(time);
    _timers[id] = Timer(fireAt.difference(DateTime.now()), () {
      _banners.add(NotificationBanner(id: id, title: title, body: body));
      // 次日同时再排（长时段页面的近似循环）。
      scheduleDaily(id: id, time: time, title: title, body: body);
    });
  }

  DateTime _nextOccurrence(LocalTime time) {
    final now = DateTime.now();
    var candidate = time.on(LocalDate.fromDateTime(now));
    if (!candidate.isAfter(now)) {
      candidate = time.on(LocalDate.fromDateTime(now).addDays(1));
    }
    return candidate;
  }

  @override
  Future<void> cancel(int id) async {
    _timers.remove(id)?.cancel();
  }

  @override
  Future<void> cancelAll() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }

  @override
  Stream<NotificationBanner> get banners => _banners.stream;
}

NotificationGateway createNotificationGateway() =>
    SimulatedNotificationGateway();
