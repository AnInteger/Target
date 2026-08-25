import 'package:flutter_test/flutter_test.dart';
import 'package:target/core/models/goal_advice.dart';
import 'package:target/core/models/goal_progress.dart';

void main() {
  test('advice chooses the largest objective loss driver', () {
    final advice = buildDimensionAdvice(
      dimension: ProgressDimension.goal,
      band: ScoreBand.calibrate,
      facts: const ProgressFacts(overdueCadence: 1, missingNextStep: 2),
    );
    expect(advice.driver, ScoreDriver.clarity);
    expect(advice.principle, isNotEmpty);
    expect(advice.currentInterpretation, contains('2 个'));
    expect(advice.action, contains('下一步'));
  });

  test('advice is factual and always keeps the three-part explanation', () {
    final advice = buildDimensionAdvice(
      dimension: ProgressDimension.habit,
      band: ScoreBand.adjust,
      facts: const ProgressFacts(lowFrequency: 3),
    );
    expect(advice.driver, ScoreDriver.frequency);
    expect(advice.principle, contains('频率'));
    expect(advice.currentInterpretation, contains('3 个'));
    expect(advice.action, isNotEmpty);
    final all =
        '${advice.principle}${advice.currentInterpretation}${advice.action}';
    expect(all, isNot(contains('加班')));
    expect(all, isNot(contains('情绪')));
    expect(all, isNot(contains('疾病')));
  });

  test('stable dimensions explain maintenance without inventing a deficit', () {
    final advice = buildDimensionAdvice(
      dimension: ProgressDimension.health,
      band: ScoreBand.stable,
      facts: const ProgressFacts(),
    );
    expect(advice.currentInterpretation, contains('稳定'));
    expect(advice.currentInterpretation, isNot(contains('0 个目标还没有')));
    expect(advice.action, contains('保持'));
  });
}
