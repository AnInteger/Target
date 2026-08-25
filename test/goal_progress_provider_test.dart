import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:target/app/providers.dart';
import 'package:target/core/models/calendar_types.dart';
import 'package:target/core/models/date_provider.dart';
import 'package:target/core/models/entities.dart';
import 'package:target/core/models/goal_progress.dart';

void main() {
  test(
    'goalProgressProvider waits for all streams and rebuilds advice',
    () async {
      const today = LocalDate(2026, 8, 25);
      final goals = StreamController<List<Goal>>.broadcast(sync: true);
      final checks = StreamController<List<CheckIn>>.broadcast(sync: true);
      final steps = StreamController<List<MilestoneStep>>.broadcast(sync: true);
      final container = ProviderContainer(
        overrides: [
          goalsProvider.overrideWith((ref) => goals.stream),
          checkInsProvider.overrideWith((ref) => checks.stream),
          allStepsProvider.overrideWith((ref) => steps.stream),
          dateProviderProvider.overrideWith(
            (ref) => FixedDateProvider(today.atStartOfDay),
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await goals.close();
        await checks.close();
        await steps.close();
      });

      expect(container.read(goalProgressProvider), isNull);
      goals.add([
        Goal(
          id: 'g',
          name: '拿到 OW 潜水证',
          goalType: GoalType.longTerm,
          iconKey: 'menu_book',
          colorKey: '',
          createdAt: today.addDays(-30),
        ),
      ]);
      checks.add(const []);
      await pumpEventQueue();
      expect(container.read(goalProgressProvider), isNull);

      steps.add(const []);
      await pumpEventQueue();
      final snapshot = container.read(goalProgressProvider)!;
      expect(snapshot.evaluation.byGoal['g']!.clarity, 40);
      expect(snapshot.advice[ProgressDimension.goal]!.action, contains('下一步'));
    },
  );
}
