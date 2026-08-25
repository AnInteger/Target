/// T019：通知列表推导（FR-005 · D6 四源）——各源独立 + 混排排序 +
/// 空态呈现。纯函数直测 [deriveNotifications]，sheet 走真库冒烟。
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:target/app/design_tokens.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/copy.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/repositories.dart'
    show GoalRepository, ReminderRepository;
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/stats/stats_engine.dart';
import 'package:target/features/notifications/notification_list.dart';

LocalDate _date(int y, int m, int d) => LocalDate(y, m, d);

/// 2026-08-19 周三锚点（与 reminder/stats 测试同锚）。
final LocalDate _today = _date(2026, 8, 19);
const _brief = LocalTime(8, 0);

Goal _habit(
  String id, {
  String name = '散步',
  String? cueScene,
  GoalStatus status = GoalStatus.active,
  LocalDate? createdAt,
}) {
  return Goal(
    id: id,
    name: name,
    goalType: GoalType.habit,
    iconKey: 'directions_run',
    colorKey: 'sage',
    status: status,
    cueScene: cueScene,
    createdAt: createdAt ?? _today.addDays(-30),
  );
}

Goal _shortTerm(
  String id, {
  required LocalDate deadline,
  GoalStatus status = GoalStatus.active,
}) {
  return Goal(
    id: id,
    name: 'OW 潜水证',
    goalType: GoalType.shortTerm,
    iconKey: 'pool',
    colorKey: 'sky',
    status: status,
    createdAt: _today.addDays(-30),
    deadline: deadline,
  );
}

void _checkIn(List<CheckIn> sink, String goalId, LocalDate day) {
  sink.add(
    CheckIn(goalId: goalId, day: day, createdAt: DateTime(2026, 8, 19, 10)),
  );
}

List<NotificationItem> _derive(
  List<Goal> goals,
  List<CheckIn> checkIns, {
  List<Reminder> reminders = const [],
}) => deriveNotifications(
  goals: goals,
  checkIns: checkIns,
  reminders: reminders,
  stats: StatsEngine.evaluate(goals: goals, checkIns: checkIns, today: _today),
  today: _today,
  nowTime: const LocalTime(12, 0),
  defaultBriefTime: _brief,
);

void main() {
  group('① 提醒时刻表（与 planReminders 同源 · 003 行=唯一真源）', () {
    Reminder row(
      String goalId, {
      LocalTime time = const LocalTime(20, 0),
      bool enabled = true,
    }) => Reminder(
      id: 'r-$goalId',
      goalId: goalId,
      time: time,
      isEnabled: enabled,
      cadence: Cadence.daily,
    );

    test('有 Reminders 行：brief+行提醒今日明日各两条，单目标可跳转', () {
      final items = _derive([_habit('g1')], [], reminders: [row('g1')]);
      final reminders = items
          .where((i) => i.kind == NotificationKind.reminder)
          .toList();
      // brief（08:00，无跳转）+ 行提醒（20:00，g1）× 今明两天。
      expect(reminders.length, 4);
      final cue = reminders
          .where((i) => i.subtitle == Copy.notifSubGoalReminder)
          .toList();
      expect(cue.length, 2);
      expect(cue.every((i) => i.goalId == 'g1'), isTrue);
      expect(cue[0].at, DateTime(2026, 8, 20, 20, 0)); // 明日
      expect(cue[1].at, DateTime(2026, 8, 19, 20, 0)); // 今日
      final brief = reminders
          .where((i) => i.subtitle == Copy.notifSubBrief)
          .toList();
      expect(brief.length, 2);
      expect(brief.every((i) => i.goalId == null), isTrue);
    });

    test('无行 → 无逐目标提醒（003：Reminders 行 = 唯一真源）', () {
      final items = _derive([_habit('g1')], const []);
      expect(
        items.where((i) => i.subtitle == Copy.notifSubGoalReminder),
        isEmpty,
      );
      expect(items.where((i) => i.subtitle == Copy.notifSubBrief).length, 2);
    });

    test('当日已留痕：行提醒条目消失（推导式实时性）', () {
      final checks = <CheckIn>[];
      _checkIn(checks, 'g1', _today);
      final items = _derive([_habit('g1')], checks, reminders: [row('g1')]);
      expect(
        items.where((i) => i.subtitle == Copy.notifSubGoalReminder),
        isEmpty,
      );
    });

    test('brief 禁用 + 无目标：空列表（sheet 空态源）', () {
      final items = _derive(
        const [],
        const [],
        reminders: [Reminder(time: _brief, isEnabled: false)],
      );
      expect(items, isEmpty);
    });
  });

  group('② 近 7 天成就', () {
    test('达成事件：achievedAt 真时刻 + 可跳转', () {
      final achieved = Goal(
        id: 'g9',
        name: '跑完 10km',
        goalType: GoalType.habit,
        iconKey: 'directions_run',
        colorKey: 'sage',
        status: GoalStatus.achieved,
        createdAt: _today.addDays(-30),
        achievedAt: DateTime(2026, 8, 18, 10, 30),
      );
      final items = _derive([achieved], const []);
      final hit = items.where((i) => i.kind == NotificationKind.achieved);
      expect(hit.length, 1);
      expect(hit.first.at, DateTime(2026, 8, 18, 10, 30));
      expect(hit.first.title, Copy.notifAchieved('跑完 10km'));
      expect(hit.first.goalId, 'g9');
    });

    test('全完成日：昨日全员留痕立一条，今日未完不立', () {
      final goals = [_habit('g1'), _habit('g2', name: '阅读')];
      final checks = <CheckIn>[];
      _checkIn(checks, 'g1', _today.addDays(-1));
      _checkIn(checks, 'g2', _today.addDays(-1));
      // 今日只有 g1 留痕 → 全完成仅昨日成立。
      _checkIn(checks, 'g1', _today);
      final items = _derive(goals, checks);
      final allDone = items.where((i) => i.kind == NotificationKind.allDone);
      expect(allDone.length, 1);
      expect(allDone.first.at, DateTime(2026, 8, 18, 21, 0));
      expect(allDone.first.title, Copy.notifAllDoneDay);
      expect(allDone.first.goalId, isNull); // 全完成日无处单点跳转
    });

    test('创建晚于该日的目标不计入当日全完成判定', () {
      final goals = [
        _habit('g1'),
        _habit('g2', name: '新目标', createdAt: _today), // 今天才创建
      ];
      final checks = <CheckIn>[];
      _checkIn(checks, 'g1', _today.addDays(-1));
      final items = _derive(goals, checks);
      // 昨日只有 g1 存在且留痕 → 全完成日成立。
      expect(items.where((i) => i.kind == NotificationKind.allDone).length, 1);
    });
  });

  group('③ streak 里程碑', () {
    test('连击 3 天 → 命中 3 档，达到日 = 今天', () {
      final checks = <CheckIn>[];
      for (var i = 0; i < 3; i++) {
        _checkIn(checks, 'g1', _today.addDays(-i));
      }
      final items = _derive([_habit('g1')], checks);
      final hit = items.where((i) => i.kind == NotificationKind.streak);
      expect(hit.length, 1);
      expect(hit.first.title, Copy.notifStreak(3));
      expect(hit.first.at, DateTime(2026, 8, 19, 21, 0));
      expect(hit.first.subtitle, Copy.notifSubMilestone);
    });

    test('连击 5 天 → 仍命 3 档（未到 7），达到日回溯 streak-k', () {
      final checks = <CheckIn>[];
      for (var i = 0; i < 5; i++) {
        _checkIn(checks, 'g1', _today.addDays(-i));
      }
      final items = _derive([_habit('g1')], checks);
      final hit = items.where((i) => i.kind == NotificationKind.streak);
      expect(hit.first.title, Copy.notifStreak(3));
      expect(hit.first.at, DateTime(2026, 8, 17, 21, 0)); // 达到 3 天那天
    });

    test('今日未留痕：连击自昨天起算，达到日随锚点前移', () {
      final checks = <CheckIn>[];
      for (var i = 1; i <= 3; i++) {
        _checkIn(checks, 'g1', _today.addDays(-i));
      }
      final items = _derive([_habit('g1')], checks);
      final hit = items.where((i) => i.kind == NotificationKind.streak);
      expect(hit.first.at, DateTime(2026, 8, 18, 21, 0));
    });

    test('连击不足 3 天 → 无里程碑条目', () {
      final checks = <CheckIn>[];
      _checkIn(checks, 'g1', _today);
      _checkIn(checks, 'g1', _today.addDays(-1));
      final items = _derive([_habit('g1')], checks);
      expect(items.where((i) => i.kind == NotificationKind.streak), isEmpty);
    });
  });

  group('④ 短期到期询问', () {
    test('deadline=今天且 active：今日 09:00 询问条目', () {
      final items = _derive([_shortTerm('s1', deadline: _today)], const []);
      final due = items.where((i) => i.kind == NotificationKind.due);
      expect(due.length, 1);
      expect(due.first.at, DateTime(2026, 8, 19, 9, 0));
      expect(due.first.title, Copy.notifDueTitle('OW 潜水证'));
      expect(due.first.subtitle, Copy.notifDueSub(0)); // 今天
      expect(due.first.goalId, 's1');
    });

    test('deadline 过去 2 天：副题带天数', () {
      final items = _derive([
        _shortTerm('s1', deadline: _today.addDays(-2)),
      ], const []);
      expect(
        items.where((i) => i.kind == NotificationKind.due).first.subtitle,
        '短期目标 · 2 天前',
      );
    });

    test('已达成/未到期的目标不询问', () {
      final items = _derive([
        _shortTerm(
          's1',
          deadline: _today.addDays(-1),
          status: GoalStatus.achieved,
        ),
        _shortTerm('s2', deadline: _today.addDays(3)),
      ], const []);
      expect(items.where((i) => i.kind == NotificationKind.due), isEmpty);
    });
  });

  group('混排与角标', () {
    test('四源混排：时间倒序，明日组居首', () {
      final goals = [
        _habit('g1'),
        _shortTerm('s1', deadline: _today.addDays(-1)),
      ];
      final checks = <CheckIn>[];
      for (var i = 0; i < 3; i++) {
        _checkIn(checks, 'g1', _today.addDays(-i));
      }
      final items = _derive(goals, checks);
      // 降序断言（允许同刻并列）。
      for (var i = 1; i < items.length; i++) {
        expect(
          items[i - 1].at.isAfter(items[i].at) ||
              items[i - 1].at.isAtSameMomentAs(items[i].at),
          isTrue,
        );
      }
      // 唯一的明日条目 = 明日提醒（g1 今日已留痕 → cue 档整体不排；
      // 明日仅剩 brief 镜像）。时间倒序 = 未来最前。
      final tomorrow = items.where((i) => i.at.day == 20).toList();
      expect(tomorrow.length, 1);
      expect(items.first.at.day, 20); // 明日组居首
      expect(items.last.at.day, 18); // 昨日到期垫底

      // 角标 = 今日归属条目数（streak + brief 今日；明日/昨日不计）。
      expect(todayBadgeCount(items, _today), 2);
    });

    test('notificationRelTime：日内粒度 + 跨日桶语（冻结稿 .tm）', () {
      // 日内已过：刚刚 → N 分钟前 → N 小时前。
      final now = const LocalTime(14, 0);
      expect(
        notificationRelTime(DateTime(2026, 8, 19, 14, 0), _today, now),
        Copy.notifJustNow,
      );
      expect(
        notificationRelTime(DateTime(2026, 8, 19, 13, 30), _today, now),
        Copy.notifMinutesAgo(30),
      );
      expect(
        notificationRelTime(DateTime(2026, 8, 19, 11, 0), _today, now),
        Copy.notifHoursAgo(3),
      );
      // 日内未到：今天 HH:mm（时刻表语义）。
      expect(
        notificationRelTime(DateTime(2026, 8, 19, 20, 0), _today, now),
        Copy.notifTodayAt('20:00'),
      );
      // 跨日：昨天/明天带时刻；2–6 天前只报天数；更远报 M月d日。
      expect(
        notificationRelTime(DateTime(2026, 8, 18, 21, 4), _today, now),
        Copy.notifYesterdayAt('21:04'),
      );
      expect(
        notificationRelTime(DateTime(2026, 8, 20, 8, 0), _today, now),
        Copy.notifTomorrowAt('08:00'),
      );
      expect(
        notificationRelTime(DateTime(2026, 8, 16, 9, 0), _today, now),
        Copy.notifDaysAgo(3),
      );
      expect(
        notificationRelTime(DateTime(2026, 8, 12, 9, 0), _today, now),
        Copy.notifDateAt(8, 12),
      );
    });
  });

  group('sheet 呈现', () {
    testWidgets('空态：一句话友好说明（FR-005 验收 8）', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      // 禁用 brief → 推导为空（见①组空列表用例）。
      await ReminderRepository(db)
          .upsert(Reminder(time: _brief, isEnabled: false));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                // fire-and-forget：sheet 的 Future 待关闭才完成，
                // 测试里经按钮触发（与真实交互同路径）。
                child: Builder(
                  builder: (context) => FilledButton(
                    onPressed: () => showNotificationSheet(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(Copy.notificationTitle), findsOneWidget);
      expect(find.text(Copy.notifEmptyTitle), findsOneWidget);
      expect(find.text(Copy.notificationEmptyHint), findsOneWidget);
      // 2026-08-25 回归：抓手条宽 40——本 sheet 列为 stretch，未包
      // Center 时固定 width 被紧约束拉成整屏宽（与其他弹层不同长；
      // rect 含底距 margin，故只断宽度）。
      final grab = tester.getRect(
        find.byKey(const ValueKey('notificationSheetGrab')),
      );
      expect(grab.width, 40);
      await db.close();
    });

    testWidgets('行形态：38px 语义色格图标 + 行尾相对时刻（T015）', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      final goal = await GoalRepository(db).create(
        Goal(
          name: '睡前拉伸',
          goalType: GoalType.habit,
          iconKey: 'self_improvement',
          colorKey: 'teal',
          createdAt: LocalDate.fromDateTime(DateTime.now()),
        ),
      );
      await ReminderRepository(db).upsert(
        Reminder(
          id: 'r-${goal.id}',
          goalId: goal.id,
          time: const LocalTime(9, 0),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [dbProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => FilledButton(
                    onPressed: () => showNotificationSheet(context),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 提醒类 = 蓝格日历图标；brief + 行提醒 × 今明两天 = 4 行同格。
      expect(find.byIcon(Icons.event_rounded), findsNWidgets(4));
      expect(find.text('睡前拉伸'), findsNWidgets(2));
      expect(find.text(Copy.notifSubBrief), findsNWidgets(2));
      // 行尾相对时刻在场：明日镜像 = 「明天 09:00」。
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('notificationSheet')),
          matching: find.text(Copy.notifTomorrowAt('09:00')),
        ),
        findsOneWidget,
      );
      await db.close();
    });
  });
}
