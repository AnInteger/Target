import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/db/app_database.dart' show AppDatabase;
import 'package:target/core/db/progress_repository.dart';
import 'package:target/core/db/repositories.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/progress_record.dart';

void main() {
  late AppDatabase db;
  late GoalRepository goals;
  late CheckInRepository checks;
  late ProgressRepository progress;
  const today = LocalDate(2026, 8, 25);
  final now = DateTime.utc(2026, 8, 25, 10);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    goals = GoalRepository(db);
    checks = CheckInRepository(db);
    progress = ProgressRepository(db);
    await goals.create(
      Goal(
        id: 'g',
        name: '拿到 OW 潜水证',
        goalType: GoalType.longTerm,
        iconKey: 'pool',
        colorKey: '',
        createdAt: const LocalDate(2026, 8, 1),
      ),
    );
  });

  tearDown(() => db.close());

  test(
    'record can check in, complete current milestone and add next step',
    () async {
      await goals.addStep(
        MilestoneStep(id: 'm1', goalId: 'g', title: '完成 DSD 体验潜水', position: 0),
      );
      await progress.record(
        ProgressRecordInput(
          goalId: 'g',
          day: today,
          createdAt: now,
          note: '完成 DSD',
          completedMilestoneId: 'm1',
          nextMilestoneTitle: '  完成理论课程  ',
        ),
      );

      expect((await checks.all()).single.note, '完成 DSD');
      final steps = await goals.stepsOf('g');
      expect(steps.first.isDone, isTrue);
      expect(steps.first.doneAt, now);
      expect(steps.last.title, '完成理论课程');
      expect(steps.last.position, 1);
    },
  );

  test(
    'blank next step records progress without creating a placeholder',
    () async {
      await progress.record(
        ProgressRecordInput(
          goalId: 'g',
          day: today,
          createdAt: now,
          note: '查了课程安排',
          nextMilestoneTitle: '   ',
        ),
      );

      expect((await checks.all()).single.note, '查了课程安排');
      expect(await goals.stepsOf('g'), isEmpty);
    },
  );

  test(
    'a failed milestone update rolls back the inserted progress record',
    () async {
      expect(
        () => progress.record(
          ProgressRecordInput(
            goalId: 'g',
            day: today,
            createdAt: now,
            note: '不应被保留',
            completedMilestoneId: 'missing',
          ),
        ),
        throwsStateError,
      );
      expect(await checks.all(), isEmpty);
    },
  );

  test('new milestone appends after the largest existing position', () async {
    await goals.addStep(
      MilestoneStep(id: 'm3', goalId: 'g', title: '已有计划', position: 3),
    );
    await progress.record(
      ProgressRecordInput(
        goalId: 'g',
        day: today,
        createdAt: now,
        nextMilestoneTitle: '下一步',
      ),
    );
    expect((await goals.stepsOf('g')).last.position, 4);
  });
}
