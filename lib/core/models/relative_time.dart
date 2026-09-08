/// 相对日标签（今天/昨天/N 天前；R1 Figma 口径）。
library;

import 'calendar_types.dart';
import '../copy.dart';

String relativeDayLabel(LocalDate day, LocalDate today) {
  if (!day.isBefore(today)) return Copy.today;
  final diff = today.differenceInDays(day);
  if (diff == 1) return Copy.yesterday;
  return Copy.daysAgo(diff);
}
