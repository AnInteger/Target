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
    required this.goalType,
    required this.iconKey,
    required this.colorKey,
    this.frequency,
  }) : assert(goalType == GoalType.habit || frequency == null,
            '仅习惯模板带频率');

  /// 预填名称（进入编辑框后仍可修改，≤30 字由 Goal 断言把关）。
  final String name;

  /// 003 v3 三类型（模板策展随 US2 编辑器重构再整理）。
  final GoalType goalType;

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
      goalType: GoalType.habit,
      iconKey: 'meal',
      colorKey: 'coral',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '规律运动',
      goalType: GoalType.habit,
      iconKey: 'fitness',
      colorKey: 'sage',
      frequency: WeeklyFrequency(3)),
  GoalTemplate(
      name: '早睡',
      goalType: GoalType.habit,
      iconKey: 'sleep',
      colorKey: 'indigo',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '屏幕休息',
      goalType: GoalType.habit,
      iconKey: 'screenRest',
      colorKey: 'sky',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '个人项目时间',
      goalType: GoalType.habit,
      iconKey: 'project',
      colorKey: 'amber',
      frequency: WeeklyFrequency(2)),
  GoalTemplate(
      name: '每天喝够水',
      goalType: GoalType.habit,
      iconKey: 'water',
      colorKey: 'teal',
      frequency: DailyFrequency(1)),
  GoalTemplate(
      name: '睡前阅读',
      goalType: GoalType.habit,
      iconKey: 'read',
      colorKey: 'plum',
      frequency: DailyFrequency(1)),
];

/// 冲刺/长线模板（FR-013：截止日期 + 步骤清单，创建后再补步骤；
/// 003 v3：旅行=短期（有日子），项目 1.0=长期）。
const List<GoalTemplate> kMilestoneTemplates = [
  GoalTemplate(
      name: '去一次旅行',
      goalType: GoalType.shortTerm,
      iconKey: 'travel',
      colorKey: 'sky'),
  GoalTemplate(
      name: '完成个人项目 1.0',
      goalType: GoalType.longTerm,
      iconKey: 'project',
      colorKey: 'teal'),
];

/// "自定义"入口（编辑器里模板区之后的空白草稿）。
const List<GoalTemplate> kAllTemplates = [...kHabitTemplates, ...kMilestoneTemplates];
