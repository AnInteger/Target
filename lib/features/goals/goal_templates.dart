/// 目标模板库（003 T027 对齐三类型编辑器）。
///
/// 模板只做"预填"——一句话名称（research D8 完整短句示范）、类型、
/// v3 图标键进编辑器后仍可改；无频率问答、无颜色步（FR-014/015），
/// 提醒档位用编辑器默认（习惯默认开 · 一天一次 09:00）。
library;

import '../../core/models/entities.dart';

class GoalTemplate {
  const GoalTemplate({
    required this.name,
    required this.goalType,
    required this.iconKey,
  });

  /// 预填名称（进入编辑框后仍可修改，40 字上限由编辑器把关）。
  final String name;

  /// 003 v3 三类型（三类型都有代表模板，策展见 kAllTemplates）。
  final GoalType goalType;

  /// v3 图标键（GoalIconCatalog 值域，snake_case）。
  final String iconKey;
}

/// 模板策展（9 枚：习惯 6 + 短期 2 + 长期 1）。
///
/// 名称语域 = 编辑器 placeholder 同款完整短句（research D8），
/// 图标取常用行策展同一批（T026 COMMON_ICONS 同源）。
const List<GoalTemplate> kHabitTemplates = [
  GoalTemplate(
      name: '睡前读 5 页书就好',
      goalType: GoalType.habit,
      iconKey: 'menu_book'),
  GoalTemplate(
      name: '饭后散步 20 分钟',
      goalType: GoalType.habit,
      iconKey: 'directions_run'),
  GoalTemplate(
      name: '十二点前上床睡觉',
      goalType: GoalType.habit,
      iconKey: 'bedtime'),
  GoalTemplate(
      name: '每天喝够 8 杯水',
      goalType: GoalType.habit,
      iconKey: 'water_drop'),
  GoalTemplate(
      name: '每天放空十分钟',
      goalType: GoalType.habit,
      iconKey: 'self_improvement'),
  GoalTemplate(
      name: '每周给家人打一个电话',
      goalType: GoalType.habit,
      iconKey: 'favorite'),
];

/// 短期/长线模板（有日子的给短期，无Deadline 的长线给长期）。
const List<GoalTemplate> kMilestoneTemplates = [
  GoalTemplate(
      name: '三个月内考过日语 N2',
      goalType: GoalType.shortTerm,
      iconKey: 'school'),
  GoalTemplate(
      name: '年底前去一次短途旅行',
      goalType: GoalType.shortTerm,
      iconKey: 'flight'),
  GoalTemplate(
      name: '把个人项目做到 1.0',
      goalType: GoalType.longTerm,
      iconKey: 'brush'),
];

/// 全量（引导页 chips 消费）。
const List<GoalTemplate> kAllTemplates = [...kHabitTemplates, ...kMilestoneTemplates];
