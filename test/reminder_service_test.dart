/// US3 提醒计划逻辑（T032/T033，FR-006/SC-005）：
/// 已达标/不适用/非活跃目标 0 催促；dailyBrief 概览 + 周一行；权限降级。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/core/stats/stats_engine.dart';
import 'package:target/features/settings/reminder_service.dart';

LocalDate _date(int y, int m, int d) => LocalDate(y, m, d);

/// 2026-08-19 周三锚点（与 stats 引擎测试同锚）。
final LocalDate _today = _date(2026, 8, 19);

class Fixture {
  final goals = <Goal>[];
  final versions = <FrequencyVersion>[];
  final checkIns = <CheckIn>[];

  Goal habit(String id, {GoalStatus status = GoalStatus.active}) {
    final g = Goal(
      id: id,
      name: '目标$id',
      kind: GoalKind.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      status: status,
      createdAt: _today.addDays(-7),
    );
    goals.add(g);
    versions.add(FrequencyVersion(
      goalId: id,
      pattern: const DailyFrequency(1),
      id: 'v$id',
      effectiveFromWeek: WeekStart.containing(_today.addDays(-7)),
      source: FrequencySource.initial,
    ));
    return g;
  }

  Goal weekdayGoal(String id, {required List<Weekday> days}) {
    final g = Goal(
      id: id,
      name: '目标$id',
      kind: GoalKind.habit,
      iconKey: 'book',
      colorKey: 'indigo',
      createdAt: _today.addDays(-7),
    );
    goals.add(g);
    versions.add(FrequencyVersion(
      goalId: id,
      pattern: WeekdaysFrequency(days.toSet(), 1),
      id: 'v$id',
      effectiveFromWeek: WeekStart.containing(_today.addDays(-7)),
      source: FrequencySource.initial,
    ));
    return g;
  }

  void checkIn(String goalId, [LocalDate? day]) {
    checkIns.add(CheckIn(
        goalId: goalId, day: day ?? _today, createdAt: DateTime(2026, 8, 19, 10)));
  }

  StatsEvaluation get stats => StatsEngine.evaluate(
        goals: goals,
        frequencyVersions: versions,
        busySessions: const [],
        checkIns: checkIns,
        today: _today,
      );
}

class _FakeGateway implements NotificationGateway {
  _FakeGateway({this.granted = true});

  final bool granted;
  final scheduled = <PlannedNotification>[];
  int cancelAllCalls = 0;

  @override
  Future<bool> requestPermission() async => granted;
  @override
  Future<bool> get isPermissionGranted async => granted;
  @override
  Future<void> scheduleDaily(
      {required int id,
      required LocalTime time,
      required String title,
      required String body}) async {
    scheduled.add(PlannedNotification(
        id: id, time: time, title: title, body: body));
  }

  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async => cancelAllCalls++;
  @override
  Stream<NotificationBanner> get banners => const Stream.empty();
}

void main() {
  final nowTime = const LocalTime(9, 0);

  group('planReminders', () {
    test('SC-005：当日已达标目标 0 催促', () {
      final f = Fixture()..habit('g1')..checkIn('g1')..habit('g2');
      final plan = planReminders(
        reminders: [
          Reminder(id: 'r1', goalId: 'g1', time: const LocalTime(20, 0)),
          Reminder(id: 'r2', goalId: 'g2', time: const LocalTime(20, 0)),
        ],
        defaultBriefTime: const LocalTime(8, 0),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      final goalTitles = plan.where((p) => p.id != kDailyBriefNotificationId);
      expect(goalTitles.map((p) => p.title), ['目标g2']);
    });

    test('暂停/归档目标与里程碑目标不催促', () {
      final f = Fixture()
        ..habit('paused', status: GoalStatus.paused)
        ..habit('closed', status: GoalStatus.archived);
      final milestone = Goal(
        id: 'm1',
        name: '去旅行',
        kind: GoalKind.milestone,
        iconKey: 'travel',
        colorKey: 'sky',
        createdAt: _today.addDays(-7),
      );
      f.goals.add(milestone);
      final plan = planReminders(
        reminders: [
          Reminder(id: 'a', goalId: 'paused', time: const LocalTime(9, 0)),
          Reminder(id: 'b', goalId: 'closed', time: const LocalTime(9, 0)),
          Reminder(id: 'c', goalId: 'm1', time: const LocalTime(9, 0)),
        ],
        defaultBriefTime: const LocalTime(8, 0),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(plan.where((p) => p.id != kDailyBriefNotificationId), isEmpty);
    });

    test('频率不覆盖今日（周三不在一二）不催促；禁用提醒不排', () {
      final f = Fixture()
        ..weekdayGoal('wd', days: const [Weekday.mon, Weekday.tue])
        ..habit('g2');
      final plan = planReminders(
        reminders: [
          Reminder(id: 'a', goalId: 'wd', time: const LocalTime(9, 0)),
          Reminder(
              id: 'b',
              goalId: 'g2',
              time: const LocalTime(9, 0),
              isEnabled: false),
        ],
        defaultBriefTime: const LocalTime(8, 0),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(plan.where((p) => p.id != kDailyBriefNotificationId), isEmpty);
    });

    test('dailyBrief 无行→默认时间；有行→行时间/开关生效；全达标文案', () {
      final f1 = Fixture()..habit('g1')..checkIn('g1');
      final p1 = planReminders(
        reminders: const [],
        defaultBriefTime: const LocalTime(8, 30),
        goals: f1.goals,
        stats: f1.stats,
        today: _today,
        nowTime: nowTime,
      );
      final brief1 = p1.single;
      expect(brief1.id, kDailyBriefNotificationId);
      expect(brief1.time, const LocalTime(8, 30));
      expect(brief1.body, contains(Copy.dailyBriefAllDone));

      final f2 = Fixture()..habit('g2');
      final p2 = planReminders(
        reminders: [
          Reminder(id: 'brief', time: const LocalTime(7, 0), isEnabled: false),
        ],
        defaultBriefTime: const LocalTime(8, 0),
        goals: f2.goals,
        stats: f2.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(p2, isEmpty);
    });

    test('下一次触发为周一 → 概要附周回顾行；否则无', () {
      // nowTime 09:00 < 20:00 → 下次=当日周三，无周一行。
      final f = Fixture()..habit('g1');
      final wed = planReminders(
        reminders: const [],
        defaultBriefTime: const LocalTime(20, 0),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(wed.single.body, isNot(contains('回顾')));

      // 2026-08-16 周日 21:00 > 20:00 → 下次=周一。
      final sunday = _date(2026, 8, 16);
      final mon = planReminders(
        reminders: const [],
        defaultBriefTime: const LocalTime(20, 0),
        goals: f.goals,
        stats: StatsEngine.evaluate(
          goals: f.goals,
          frequencyVersions: f.versions,
          busySessions: const [],
          checkIns: const [],
          today: sunday,
        ),
        today: sunday,
        nowTime: const LocalTime(21, 0),
      );
      expect(mon.single.body, contains(Copy.dailyBriefReviewLine));
    });

    test('稳定 id：同一 goalId 恒等且不与概要冲突', () {
      final a = goalReminderId('g1');
      expect(goalReminderId('g1'), a);
      expect(goalReminderId('g2'), isNot(a));
      expect(goalReminderId('g2'), isNot(kDailyBriefNotificationId));
    });
  });

  group('ReminderService.replan', () {
    test('权限被拒 → 全量取消、零调度（FR-007 降级）', () async {
      final gateway = _FakeGateway(granted: false);
      final service = ReminderService(gateway, null);
      final f = Fixture()..habit('g1');
      await service.replan(
        settings: const Settings(),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(gateway.cancelAllCalls, 1);
      expect(gateway.scheduled, isEmpty);
    });

    test('授权 → 先清空再按计划调度（已达标剔除）', () async {
      final gateway = _FakeGateway();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = ReminderRepository(db);
      await repo.upsert(
          Reminder(id: 'a', goalId: 'g1', time: const LocalTime(20, 0)));
      await repo.upsert(
          Reminder(id: 'b', goalId: 'g2', time: const LocalTime(20, 0)));
      final service = ReminderService(gateway, repo);
      final f = Fixture()..habit('g1')..checkIn('g1')..habit('g2');
      await service.replan(
        settings: const Settings(),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(gateway.cancelAllCalls, 1);
      expect(
        gateway.scheduled.map((p) => p.id),
        containsAll([kDailyBriefNotificationId, goalReminderId('g2')]),
      );
      expect(
          gateway.scheduled.map((p) => p.id), isNot(contains(goalReminderId('g1'))));
    });
  });
}
