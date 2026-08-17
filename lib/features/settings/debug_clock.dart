/// Debug 时钟菜单（T049，research D6）：开发构建专用的运行时时间旅行。
///
/// 切换 dateProviderProvider 实现（System ⇄ Fixed）后 invalidate
/// today/stats，即可在真机/Web 上验证周一结算、跨天电量、连击截至
/// 昨天等口径。仅 kDebugMode 渲染入口。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/date_provider.dart';

/// 设置页入口行（debug 构建才渲染）。
class DebugClockTile extends ConsumerWidget {
  const DebugClockTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dp = ref.watch(dateProviderProvider);
    final fixed = dp is FixedDateProvider;
    return ListTile(
      leading: const Icon(Icons.schedule),
      title: Text(Copy.debugClock),
      subtitle: fixed
          ? Text('已固定 ${dp.today.isoString}')
          : const Text('跟随系统时间'),
      onTap: () => _showMenu(context, ref),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final dp = ref.read(dateProviderProvider);
    final today = dp.today;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('今天 = ${today.isoString}（${today.weekStart.isoString} 起）',
                  style: Theme.of(sheetContext).textTheme.titleSmall),
            ),
            ListTile(
              leading: const Icon(Icons.skip_next),
              title: const Text('跳到下周一（验证周结算）'),
              subtitle: const Text('周一晨：概要带上周回顾 + 结算幂等'),
              onTap: () {
                _travel(ref, today.weekStart.next.monday);
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('去任意一天'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: sheetContext,
                  initialDate: today.atStartOfDay,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked == null) return;
                _travel(ref, LocalDate.fromDateTime(picked));
                if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('回到真实时间'),
              onTap: () {
                ref.read(dateProviderProvider.notifier).state =
                    const SystemDateProvider();
                _refresh(ref);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _travel(WidgetRef ref, LocalDate day) {
    // 取正午避免 0 点边界歧义（R1 已有专门测试覆盖边界）。
    ref.read(dateProviderProvider.notifier).state =
        FixedDateProvider(day.atStartOfDay.add(const Duration(hours: 12)));
    _refresh(ref);
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(todayProvider);
    ref.invalidate(statsProvider);
  }
}
