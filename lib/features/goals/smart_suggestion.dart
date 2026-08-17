/// SMART 具体化建议（FR-001）：模糊目标名 → 一键采用的具体表述。
///
/// 纯 Dart：编辑器输入框 onChanged 调用 [suggest]，非 null 时内联呈现
/// 「换成更具体的？」chip（Copy.smartSuggest / smartApply）。
library;

/// 判断 + 建议表。关键词命中即模糊；建议文案自带可执行动作。
abstract final class SmartSuggestion {
  /// 模糊词 → 具体建议（顺序即优先级，先命中先用）。
  static const Map<String, String> _table = {
    '变健康': '每天散步 20 分钟',
    '更健康': '每天散步 20 分钟',
    '健康': '每天吃一份蔬菜',
    '多运动': '每周运动 3 次，每次 30 分钟',
    '锻炼': '每周运动 3 次，每次 30 分钟',
    '健身': '每周去 2 次健身房',
    '减肥': '每晚饭后快走 30 分钟',
    '早睡': '23 点前上床',
    '早点睡': '23 点前上床',
    '少熬夜': '23 点前上床',
    '熬夜': '23 点前上床',
    '少玩手机': '睡前 30 分钟不碰手机',
    '手机': '睡前 30 分钟不碰手机',
    '戒手机': '睡前 30 分钟不碰手机',
    '多喝水': '每天 8 杯水',
    '喝水': '每天 8 杯水',
    '读书': '每晚读 10 页',
    '阅读': '每晚读 10 页',
    '看书': '每晚读 10 页',
    '学习': '每晚学习 25 分钟',
    '编程': '每周写 2 次代码，每次 1 小时',
    '做项目': '每周推进 2 次，每次 1 小时',
    '冥想': '每天冥想 10 分钟',
    '旅行': '季度内安排一次 2 天的短途',
    '旅游': '季度内安排一次 2 天的短途',
    '陪家人': '每周留一个晚上陪家人',
    '家人': '每周留一个晚上陪家人',
  };

  /// 已经足够具体的信号：出现数字或量化单位。
  static final RegExp _specific = RegExp(r'[0-9０-９]|[点分]钟|分钟|小时|页|次|杯|公里|千米|步|天前');

  /// [name] 模糊则返回建议，已具体返回 null（不打扰）。
  static String? suggest(String name) {
    final n = name.trim();
    if (n.isEmpty) return null;
    if (_specific.hasMatch(n)) return null; // 已带量化，视为具体
    for (final e in _table.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return null;
  }
}
