import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/goal_plan_repository.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/frequency_pattern.dart';
import 'package:target/core/models/goal_plan.dart';

Goal baseGoal(String id) => Goal(
  id: id,
  name: '21 天跑步计划',
  goalType: GoalType.shortTerm,
  iconKey: 'directions_run',
  colorKey: '',
  createdAt: const LocalDate(2026, 8, 1),
  targetDate: const LocalDate(2026, 9, 1),
  frequency: const WeeklyFrequency(3),
);

void main() {
  late AppDatabase db;
  late GoalPlanRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GoalPlanRepository(db);
  });

  tearDown(() => db.close());

  test(
    'create atomically stores goal, ordered milestones, and reminder',
    () async {
      final input = GoalPlanInput(
        goal: baseGoal('create'),
        milestones: const [
          MilestoneDraft(title: '坚持 7 天'),
          MilestoneDraft(title: '坚持 21 天'),
        ],
        reminder: ReminderDraft(
          enabled: true,
          time: const LocalTime(9, 0),
          cadence: Cadence.daily,
        ),
      );
      final created = await repo.create(input);
      final loaded = await repo.load(created.id);
      expect(loaded!.goal.frequency, const WeeklyFrequency(3));
      expect(loaded.milestones.map((m) => m.position), [0, 1]);
      expect(loaded.reminder!.isEnabled, isTrue);
    },
  );

  test(
    'update can clear date and frequency and preserves completed milestone',
    () async {
      final doneAt = DateTime.utc(2026, 8, 20, 8);
      final created = await repo.create(
        GoalPlanInput(
          goal: baseGoal('edit'),
          milestones: [
            MilestoneDraft(
              id: 'keep',
              title: '坚持 7 天',
              isDone: true,
              doneAt: doneAt,
            ),
            const MilestoneDraft(id: 'remove', title: '坚持 14 天'),
          ],
          reminder: const ReminderDraft(
            id: 'edit-reminder',
            enabled: true,
            time: LocalTime(9, 0),
            cadence: Cadence.daily,
          ),
        ),
      );

      await repo.update(
        GoalPlanInput(
          goal: created.copyWith(clearTargetDate: true, clearFrequency: true),
          milestones: [
            MilestoneDraft(
              id: 'keep',
              title: '连续完成第一阶段',
              isDone: true,
              doneAt: doneAt,
            ),
          ],
          reminder: null,
        ),
      );

      final loaded = await repo.load(created.id);
      expect(loaded!.goal.targetDate, isNull);
      expect(loaded.goal.frequency, isNull);
      expect(loaded.milestones, hasLength(1));
      expect(loaded.milestones.single.id, 'keep');
      expect(loaded.milestones.single.title, '连续完成第一阶段');
      expect(loaded.milestones.single.isDone, isTrue);
      expect(loaded.milestones.single.doneAt, doneAt);
      expect(loaded.reminder, isNull);
    },
  );

  test(
    'invalid update leaves goal milestones and reminder unchanged',
    () async {
      final created = await repo.create(
        GoalPlanInput(
          goal: baseGoal('rollback'),
          milestones: const [MilestoneDraft(id: 'original', title: '原里程碑')],
          reminder: const ReminderDraft(
            id: 'rollback-reminder',
            enabled: true,
            time: LocalTime(9, 0),
            cadence: Cadence.daily,
          ),
        ),
      );

      await expectLater(
        repo.update(
          GoalPlanInput(
            goal: created.copyWith(name: '不应保存的新名称'),
            milestones: [MilestoneDraft(title: List.filled(51, '超').join())],
            reminder: const ReminderDraft(
              id: 'rollback-reminder',
              enabled: false,
              time: LocalTime(18, 0),
              cadence: Cadence.weekly,
            ),
          ),
        ),
        throwsArgumentError,
      );

      final loaded = await repo.load(created.id);
      expect(loaded!.goal.name, '21 天跑步计划');
      expect(loaded.milestones.single.id, 'original');
      expect(loaded.milestones.single.title, '原里程碑');
      expect(loaded.reminder!.isEnabled, isTrue);
      expect(loaded.reminder!.time, const LocalTime(9, 0));
    },
  );

  test(
    'update preserves incomplete retained milestone completion metadata',
    () async {
      final created = await repo.create(
        GoalPlanInput(
          goal: baseGoal('incomplete'),
          milestones: const [MilestoneDraft(id: 'keep-open', title: '还没完成的步骤')],
          reminder: null,
        ),
      );

      await repo.update(
        GoalPlanInput(
          goal: created,
          milestones: [
            MilestoneDraft(
              id: 'keep-open',
              title: '改名但仍未完成',
              doneAt: DateTime.utc(2026, 8, 21, 8),
            ),
          ],
          reminder: null,
        ),
      );

      final loaded = await repo.load(created.id);
      expect(loaded!.milestones.single.title, '改名但仍未完成');
      expect(loaded.milestones.single.isDone, isFalse);
      expect(loaded.milestones.single.doneAt, isNull);
    },
  );
}
