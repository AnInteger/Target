/// 目标模板库（FR-012）：预设常见生活目标，30 秒内完成创建（FR-001）。
///
/// 模板只做"预填"——名称可改、频率可改、图标颜色可换；
/// editor 全程消费同一 GoalEditorDraft，模板是它的出厂值。
library;

import '../../core/models/entities.dart';
import '../../core/models/frequency_pattern.dart';

class GoalTemplate {
  const GoalTemplate({
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.colorKey,
    this.frequency,
  }) : assert(kind == GoalKind.habit || frequency == null,
            '里程碑模板不带频率');

  /// 预填名称（进入编辑框后仍可修改，≤30 字由 Goal 断言把关）。
  final String name;
  final GoalKind kind;

  /// 设计令牌键（design_tokens.dart 枚举 .name）。
  final String iconKey;
  final String colorKey;

  /// 习惯型默认频率；里程碑型为 null（由截止日期驱动）。
  final FrequencyPattern? frequency;
}

/// 习惯模板（spec FR-012 列举的 5 个 + 2 个常见补充）。
const List<GoalTemplate> kHabitTemplates = [
  GoalTemplate(
      name: '好好吃饭',
      kind: GoalKind.habit,
      iconKey: 'meal',
      colorKey: 'coral',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '规律运动',
      kind: GoalKind.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      frequency: WeeklyFrequency(3)),
  GoalTemplate(
      name: '早睡',
      kind: GoalKind.habit,
      iconKey: 'sleep',
      colorKey: 'indigo',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '屏幕休息',
      kind: GoalKind.habit,
      iconKey: 'screenRest',
      colorKey: 'sky',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '个人项目时间',
      kind: GoalKind.habit,
      iconKey: 'project',
      colorKey: 'amber',
      frequency: WeeklyFrequency(2)),
  GoalTemplate(
      name: '每天喝够水',
      kind: GoalKind.habit,
      iconKey: 'water',
      colorKey: 'teal',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '睡前阅读',
      kind: GoalKind.habit,
      iconKey: 'read',
      colorKey: 'plum',
      frequency: DailyFrequency(1)),
];

/// 里程碑模板（FR-013：截止日期 + 步骤清单，创建后再补步骤）。
const List<GoalTemplate> kMilestoneTemplates = [
  GoalTemplate(
      name: '去一次旅行',
      kind: GoalKind.milestone,
      iconKey: 'travel',
      colorKey: 'sky'),
  GoalTemplate(
      name: '完成个人项目 1.0',
      kind: GoalKind.milestone,
      iconKey: 'project',
      colorKey: 'teal'),
];

/// "自定义"入口（编辑器里模板区之后的空白草稿）。
const List<GoalTemplate> kAllTemplates = [...kHabitTemplates, ...kMilestoneTemplates];
