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

/// 秒级时间标签：今天/昨天 HH:mm:ss，更早 M月d日 HH:mm:ss
/// （记录日期可选、时分秒取记录当下——v3.1 详情/动态共用口径）。
String timestampLabel(LocalDate day, LocalDate today, DateTime local) {
  final time =
      '${_pad2(local.hour)}:${_pad2(local.minute)}:${_pad2(local.second)}';
  if (day == today) return '${Copy.today} $time';
  if (day == today.addDays(-1)) return '${Copy.yesterday} $time';
  return '${local.month}月${local.day}日 $time';
}

String _pad2(int n) => n.toString().padLeft(2, '0');
