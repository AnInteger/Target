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

/// 分钟级时间标签：今天/昨天 HH:mm，更早 M月d日 HH:mm
/// （记录日期可选、时分取记录当下——v3.1 详情/动态共用口径；
/// R12 起秒级收窄为分钟）。
String timestampLabel(LocalDate day, LocalDate today, DateTime local) {
  final time = '${_pad2(local.hour)}:${_pad2(local.minute)}';
  if (day == today) return '${Copy.today} $time';
  if (day == today.addDays(-1)) return '${Copy.yesterday} $time';
  return '${local.month}月${local.day}日 $time';
}

String _pad2(int n) => n.toString().padLeft(2, '0');
