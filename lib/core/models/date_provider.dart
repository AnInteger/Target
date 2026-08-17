/// 时钟注入（research D6）。
///
/// 业务与统计代码只读本接口，不直接触碰 DateTime.now()——
/// 时间旅行测试（R1 跨天、周一结算、连击截至昨天）与 Debug 时钟菜单
/// （T049）都建立在"时钟可替换"之上。生产实现走 clock 包的
/// clock.now()（测试可用 withClock 覆写，无需替换 Provider）。
library;

import 'package:clock/clock.dart';

import 'calendar_types.dart';

abstract class DateProvider {
  const DateProvider();

  /// 当前时刻（本地时区）。自然日换算：LocalDate.fromDateTime(now())。
  DateTime now();

  LocalDate get today => LocalDate.fromDateTime(now());

  LocalTime get timeNow => LocalTime.fromDateTime(now());

  /// 本周（周一锚点）。
  WeekStart get thisWeek => WeekStart.containing(today);
}

/// 生产时钟：clock.now()（测试经 withClockFromSettings / withClock 覆写）。
class SystemDateProvider extends DateProvider {
  const SystemDateProvider();

  @override
  DateTime now() => clock.now();
}

/// 固定时钟：单元测试与 Debug 时钟菜单用（直接改 [value] 即时间旅行）。
class FixedDateProvider extends DateProvider {
  FixedDateProvider(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}
