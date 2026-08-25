/// 基于客观损失项生成固定三段式说明，不做个人状态或因果推断。
library;

import 'goal_progress.dart';
import 'entities.dart';
import 'goal_icon_catalog.dart';

class ProgressFacts {
  const ProgressFacts({
    this.overdueCadence = 0,
    this.missingNextStep = 0,
    this.deadlineNear = 0,
    this.lowFrequency = 0,
  });

  final int overdueCadence;
  final int missingNextStep;
  final int deadlineNear;
  final int lowFrequency;
}

class GoalAdvice {
  const GoalAdvice({
    required this.dimension,
    required this.band,
    required this.driver,
    required this.principle,
    required this.currentInterpretation,
    required this.action,
  });

  final ProgressDimension dimension;
  final ScoreBand band;
  final ScoreDriver driver;
  final String principle;
  final String currentInterpretation;
  final String action;
}

class GoalProgressSnapshot {
  const GoalProgressSnapshot({required this.evaluation, required this.advice});

  final GoalProgressEvaluation evaluation;
  final Map<ProgressDimension, GoalAdvice> advice;
}

GoalProgressSnapshot buildProgressSnapshot({
  required GoalProgressEvaluation evaluation,
  required List<Goal> goals,
}) {
  final advice = <ProgressDimension, GoalAdvice>{};
  for (final entry in evaluation.dimensions.entries) {
    final dimension = entry.key;
    var overdueCadence = 0;
    var missingNextStep = 0;
    var deadlineNear = 0;
    var lowFrequency = 0;
    for (final goal in goals) {
      final score = evaluation.byGoal[goal.id];
      if (score == null ||
          _dimensionOf(goal.effectiveDomain.major) != dimension) {
        continue;
      }
      if (!goal.isHabit && score.momentum < 100) overdueCadence++;
      if (score.clarity < 100) missingNextStep++;
      if (score.deadlineBuffer != null && score.deadlineBuffer! <= 40) {
        deadlineNear++;
      }
      if (score.frequency != null && score.frequency! < 100) lowFrequency++;
    }
    advice[dimension] = buildDimensionAdvice(
      dimension: dimension,
      band: entry.value.band,
      facts: ProgressFacts(
        overdueCadence: overdueCadence,
        missingNextStep: missingNextStep,
        deadlineNear: deadlineNear,
        lowFrequency: lowFrequency,
      ),
    );
  }
  return GoalProgressSnapshot(
    evaluation: evaluation,
    advice: Map.unmodifiable(advice),
  );
}

GoalAdvice buildDimensionAdvice({
  required ProgressDimension dimension,
  required ScoreBand band,
  required ProgressFacts facts,
}) {
  final factCount =
      facts.overdueCadence +
      facts.missingNextStep +
      facts.deadlineNear +
      facts.lowFrequency;
  if (factCount == 0) {
    final driver = dimension == ProgressDimension.habit
        ? ScoreDriver.frequency
        : ScoreDriver.momentum;
    return GoalAdvice(
      dimension: dimension,
      band: band,
      driver: driver,
      principle: _principle(driver),
      currentInterpretation: '当前进行中的目标在这一维度保持稳定，没有出现需要优先处理的节奏、规划或期限信号。',
      action: '保持现在的记录方式，并在下一次正常回顾时确认计划仍然适用；无需为了提高分数额外增加任务。',
    );
  }
  final driver = _largestDriver(facts);
  return GoalAdvice(
    dimension: dimension,
    band: band,
    driver: driver,
    principle: _principle(driver),
    currentInterpretation: _interpretation(driver, facts),
    action: _action(driver, band),
  );
}

ScoreDriver _largestDriver(ProgressFacts facts) {
  final values = <ScoreDriver, int>{
    ScoreDriver.clarity: facts.missingNextStep,
    ScoreDriver.deadlineBuffer: facts.deadlineNear,
    ScoreDriver.momentum: facts.overdueCadence,
    ScoreDriver.frequency: facts.lowFrequency,
  };
  return values.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

String _principle(ScoreDriver driver) => switch (driver) {
  ScoreDriver.momentum =>
    '推进节奏观察目标是否在自己设定的检查周期内留下有效进展。它不评价进展大小，而是帮助你尽早发现目标已经失去反馈循环。',
  ScoreDriver.clarity =>
    '下一步清晰度观察目标是否已经被转化为一个可以开始的具体动作。明确下一步能减少每次重新理解目标的成本，也让记录进展更容易发生。',
  ScoreDriver.deadlineBuffer =>
    '截止缓冲比较剩余天数与目标推进周期。缓冲越少，能够检验、调整和补充下一步的机会越少；这个指标只描述时间余量，不预测目标能否完成。',
  ScoreDriver.frequency =>
    '频率完成度比较最近七天的实际记录次数与计划次数。它关注节奏是否与计划一致，而不是要求每天都达到同样的表现。',
};

String _interpretation(ScoreDriver driver, ProgressFacts facts) =>
    switch (driver) {
      ScoreDriver.momentum =>
        '当前有 ${facts.overdueCadence} 个目标超过了各自的推进周期，最近一次有效进展距离今天较远。',
      ScoreDriver.clarity =>
        '当前有 ${facts.missingNextStep} 个目标还没有确认下一步，目标方向存在，但下一次可执行动作尚未落定。',
      ScoreDriver.deadlineBuffer =>
        '当前有 ${facts.deadlineNear} 个短期目标的剩余时间不超过一个推进周期，时间缓冲已经进入需要优先确认的区间。',
      ScoreDriver.frequency =>
        '当前有 ${facts.lowFrequency} 个习惯在最近七天的实际完成次数低于计划频率。',
    };

String _action(ScoreDriver driver, ScoreBand band) {
  final priority = band == ScoreBand.replan || band == ScoreBand.adjust
      ? '先只处理最重要的一项：'
      : '下一次整理目标时，';
  return switch (driver) {
    ScoreDriver.momentum =>
      '$priority为一个超出周期的目标补充一次真实进展；如果暂时不再推进，就把它暂停，避免活跃列表持续失真。',
    ScoreDriver.clarity => '$priority给一个目标写下可在当前条件下开始的下一步，动作可以很小，但要能明确判断是否完成。',
    ScoreDriver.deadlineBuffer =>
      '$priority检查截止日前仍需完成的步骤，保留一个最近动作；若期限已不适用，请明确调整日期而不是继续沿用旧计划。',
    ScoreDriver.frequency =>
      '$priority核对计划频率是否仍然合理，并安排下一次具体行动；需要降低频率时直接修改计划，让分数继续反映真实承诺。',
  };
}

ProgressDimension _dimensionOf(MajorCategory category) => switch (category) {
  MajorCategory.health => ProgressDimension.health,
  MajorCategory.habit => ProgressDimension.habit,
  MajorCategory.goal => ProgressDimension.goal,
};
