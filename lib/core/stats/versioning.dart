/// 频率版本选择（stats-engine.md R2、research D7）。
///
/// 任一日 d 的有效版本 = `effectiveFromWeek ≤ d 所在周` 中
/// `effectiveFromWeek` 最大者；同周 busyMode 与非 busyMode 并存时
/// busyMode 优先（忙碌周的降档明确生效）。早于所有版本（目标创建前）→ null。
library;

import '../models/calendar_types.dart';
import '../models/entities.dart';
import '../models/frequency_pattern.dart';

FrequencyVersion? effectiveVersion(
    List<FrequencyVersion> versions, LocalDate day) {
  FrequencyVersion? best;
  for (final v in versions) {
    if (!v.covers(day)) continue; // 生效周 > 目标周
    final b = best;
    if (b == null ||
        v.effectiveFromWeek.compareTo(b.effectiveFromWeek) > 0 ||
        // 同周：busyMode 赢
        (v.effectiveFromWeek == b.effectiveFromWeek &&
            v.source == FrequencySource.busyMode &&
            b.source != FrequencySource.busyMode)) {
      best = v;
    }
  }
  return best;
}

FrequencyPattern? effectivePattern(
        List<FrequencyVersion> versions, LocalDate day) =>
    effectiveVersion(versions, day)?.pattern;
