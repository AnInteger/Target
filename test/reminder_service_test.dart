/// 提醒排程档位（003 T028 · contracts/goal-type-model「提醒排程」）：
/// Reminders 行 cadence 驱动（daily 每日 / threeDay 自启用日起每 3 天 /
/// weekly 每周同 weekday）+ 短期到期询问单次（deadline 当日 09:00）+
/// 关开关即时取消；dailyBrief 概览 + 周一行；权限降级。
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/platform/gateways.dart';
import 'package:target/core/stats/stats_engine.dart';
import 'package:target/features/settings/reminder_service.dart';

LocalDate _date(int y, int m, int d) => LocalDate(y, m, d);

/// 2026-08-19 周三锚点（与 stats 引擎测试同锚）。
final LocalDate _today = _date(2026, 8, 19);

class Fixture {
  final goals = <Goal>[];
  final checkIns = <CheckIn>[];

  Goal habit(String id,
      {String? name,
      GoalStatus status = GoalStatus.active,
      String? motivation,
      LocalDate? createdAt}) {
    final g = Goal(
      id: id,
      name: name ?? '目标$id',
      goalType: GoalType.habit,
      iconKey: 'fitness_center',
      colorKey: 'sage',
      status: status,
      motivation: motivation,
      createdAt: createdAt ?? _today.addDays(-7),
    );
    goals.add(g);
    return g;
  }

  Goal shortTerm(String id, {LocalDate? deadline, DateTime? achievedAt}) {
    final g = Goal(
      id: id,
      name: '目标$id',
      goalType: GoalType.shortTerm,
      iconKey: 'school',
      colorKey: 'teal',
      deadline: deadline,
      achievedAt: achievedAt,
      createdAt: _today.addDays(-7),
    );
    goals.add(g);
    return g;
  }

  void checkIn(String goalId, [LocalDate? day]) {
    checkIns.add(CheckIn(
        goalId: goalId,
        day: day ?? _today,
        createdAt: DateTime(2026, 8, 19, 10)));
  }

  StatsEvaluation get stats => StatsEngine.evaluate(
        goals: goals,
        busySessions: const [],
        checkIns: checkIns,
        today: _today,
      );
}

Reminder _row(String goalId,
        {LocalTime time = const LocalTime(9, 0),
        Cadence cadence = Cadence.daily,
        bool enabled = true}) =>
    Reminder(
        id: 'r-$goalId',
        goalId: goalId,
        time: time,
        isEnabled: enabled,
        cadence: cadence);

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

  List<PlannedNotification> plan(Fixture f, {List<Reminder> rows = const []}) =>
      planReminders(
        reminders: rows,
        defaultBriefTime: const LocalTime(8, 0),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );

  List<PlannedNotification> nudges(List<PlannedNotification> p) =>
      p.where((x) => x.id != kDailyBriefNotificationId).toList();

  group('planReminders · cadence 三档', () {
    test('daily：每日行时间，标题=目标名、正文轻推；留痕后静默（SC-005）', () {
      final f = Fixture()..habit('g1', name: '散步');
      final p1 = nudges(plan(f, rows: [_row('g1', time: const LocalTime(21, 30))]));
      expect(p1, hasLength(1));
      expect(p1.single.time, const LocalTime(21, 30));
      expect(p1.single.title, '散步');
      expect(p1.single.body, Copy.reminderNudge);
      expect(p1.single.goalIds, ['g1']);

      // 当日已留痕 → 0 催促。
      f.checkIn('g1');
      expect(nudges(plan(f, rows: [_row('g1')])), isEmpty);
    });

    test('threeDay：自启用日（最近打卡，无打卡回落创建日）起每 3 天', () {
      // 创建日 7 天前（diff 7，7%3≠0）→ 今日不适用。
      final f1 = Fixture()..habit('g1', createdAt: _today.addDays(-7));
      expect(
          nudges(plan(f1, rows: [_row('g1', cadence: Cadence.threeDay)])),
          isEmpty);

      // 最近打卡 = 3 天前（diff 3）→ 今日适用。
      final f2 = Fixture()
        ..habit('g1', createdAt: _today.addDays(-7))
        ..checkIn('g1', _today.addDays(-3));
      expect(
          nudges(plan(f2, rows: [_row('g1', cadence: Cadence.threeDay)])),
          hasLength(1));

      // 最近打卡 = 昨天（diff 1）→ 不适用（周期自打卡日重置）。
      final f3 = Fixture()
        ..habit('g1', createdAt: _today.addDays(-7))
        ..checkIn('g1', _today.addDays(-1));
      expect(
          nudges(plan(f3, rows: [_row('g1', cadence: Cadence.threeDay)])),
          isEmpty);

      // 创建日 = 今天（diff 0）→ 适用。
      final f4 = Fixture()..habit('g1', createdAt: _today);
      expect(
          nudges(plan(f4, rows: [_row('g1', cadence: Cadence.threeDay)])),
          hasLength(1));
    });

    test('weekly：每周同 weekday（锚 = 最近打卡/创建日的星期）', () {
      // 创建日 8-12 周三（同 weekday）→ 今日适用。
      final f1 = Fixture()..habit('g1', createdAt: _date(2026, 8, 12));
      expect(nudges(plan(f1, rows: [_row('g1', cadence: Cadence.weekly)])),
          hasLength(1));

      // 最近打卡 8-15 周六（非今日周三）→ 不适用。
      final f2 = Fixture()
        ..habit('g1', createdAt: _date(2026, 8, 12))
        ..checkIn('g1', _date(2026, 8, 15));
      expect(nudges(plan(f2, rows: [_row('g1', cadence: Cadence.weekly)])),
          isEmpty);

      // 最近打卡 8-18 周二 → 不适用；8-12 周三打卡 → 适用。
      final f3 = Fixture()
        ..habit('g1', createdAt: _date(2026, 8, 5))
        ..checkIn('g1', _date(2026, 8, 12));
      expect(nudges(plan(f3, rows: [_row('g1', cadence: Cadence.weekly)])),
          hasLength(1));
    });

    test('关开关/非活跃/无目标行 → 不排；存量「为什么」附正文（FR-016）', () {
      final f = Fixture()
        ..habit('off')
        ..habit('paused', status: GoalStatus.paused)
        ..habit('archived', status: GoalStatus.archived)
        ..habit('why', motivation: '身体轻一点');
      final p = nudges(plan(f, rows: [
        _row('off', enabled: false), // 关 = 不排（即时取消）
        _row('paused'),
        _row('archived'),
        _row('noGoal'), // 行在、目标不在
        _row('why'),
      ]));
      expect(p, hasLength(1));
      expect(p.single.body, Copy.reminderAsk('身体轻一点', '目标why'));
    });

    test('通知 id：逐目标与到期询问分段互异、同 goal 稳定、不与概要冲突', () {
      expect(goalReminderNotificationId('a'), goalReminderNotificationId('a'));
      expect(dueAskNotificationId('a'), dueAskNotificationId('a'));
      for (final id in ['a', 'b', 'c']) {
        expect(goalReminderNotificationId(id),
            isNot(equals(kDailyBriefNotificationId)));
        expect(goalReminderNotificationId(id),
            isNot(equals(dueAskNotificationId(id))));
      }
    });
  });

  group('planReminders · 短期到期询问（D4）', () {
    test('deadline 当日 → 09:00 单次「到日子了」；明日/已过/已达成 → 无', () {
      final f = Fixture()
        ..shortTerm('dueToday', deadline: _today)
        ..shortTerm('dueTomorrow', deadline: _today.addDays(1))
        ..shortTerm('overdue', deadline: _today.addDays(-2))
        ..shortTerm('done',
            deadline: _today, achievedAt: DateTime(2026, 8, 19, 9));
      final p = nudges(plan(f));
      expect(p, hasLength(1));
      expect(p.single.title, '目标dueToday');
      expect(p.single.body, Copy.shortTermDueAsk);
      expect(p.single.time, kDueAskTime);
    });

    test('到期询问不依赖 Reminders 行（排程器按 deadline 推导）', () {
      final f = Fixture()..shortTerm('due', deadline: _today);
      expect(nudges(plan(f, rows: const [])), hasLength(1));
      // 行存在但关着：逐目标提醒不排，到期询问照发。
      expect(
          nudges(plan(f, rows: [_row('due', enabled: false)])), hasLength(1));
    });
  });

  group('planReminders · dailyBrief', () {
    test('无行→默认时间；有行→行时间/开关生效；全达标文案', () {
      final f1 = Fixture()..habit('g1')..checkIn('g1');
      final p1 = plan(f1);
      final brief1 = p1.single;
      expect(brief1.id, kDailyBriefNotificationId);
      expect(brief1.time, const LocalTime(8, 0));
      expect(brief1.body, contains(Copy.dailyBriefAllDone));

      final f2 = Fixture()..habit('g2')..checkIn('g2');
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
      final f = Fixture()..habit('g1')..checkIn('g1');
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
      final fSun = Fixture()..habit('g1')..checkIn('g1', sunday);
      final mon = planReminders(
        reminders: const [],
        defaultBriefTime: const LocalTime(20, 0),
        goals: fSun.goals,
        stats: StatsEngine.evaluate(
          goals: fSun.goals,
          busySessions: const [],
          checkIns: fSun.checkIns,
          today: sunday,
        ),
        today: sunday,
        nowTime: const LocalTime(21, 0),
      );
      expect(mon.single.body, contains(Copy.dailyBriefReviewLine));
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

    test('关开关即时取消：先排后关，replan 全量重建后不再在场', () async {
      final gateway = _FakeGateway();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() => db.close());
      final repo = ReminderRepository(db);
      final f = Fixture()..habit('g1');
      final service = ReminderService(gateway, repo);

      // 开 → 排上（概要 + 逐目标）。
      await repo.upsert(_row('g1', time: const LocalTime(21, 0)));
      await service.replan(
        settings: const Settings(),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(
          gateway.scheduled.map((p) => p.id).toSet(),
          {kDailyBriefNotificationId, goalReminderNotificationId('g1')});

      // 关 → replan 清空重建，逐目标通知消失。
      gateway.scheduled.clear();
      final rows = await repo.all();
      await repo.upsert(Reminder(
          id: rows.single.id,
          goalId: 'g1',
          time: const LocalTime(21, 0),
          isEnabled: false));
      await service.replan(
        settings: const Settings(),
        goals: f.goals,
        stats: f.stats,
        today: _today,
        nowTime: nowTime,
      );
      expect(gateway.cancelAllCalls, 2);
      expect(gateway.scheduled.map((p) => p.id),
          [kDailyBriefNotificationId]); // 仅概要残留
    });
  });
}
