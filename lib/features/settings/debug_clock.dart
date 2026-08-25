/// Debug 时钟菜单（T049，research D6）：开发构建专用的运行时时间旅行。
///
/// 切换 dateProviderProvider 实现（System ⇄ Fixed）后 invalidate
/// today/stats，即可在真机/Web 上验证跨天状态、连击截至
/// 昨天等口径。仅 kDebugMode 渲染入口。
///
/// 004 T016 换装 v2 语言（无对应原型画板，按已冻结组件拼装）：入口行
/// = 设置页行语法（30px surfaceAlt 色格图标 + 标题/副题 + 箭头）；弹层
/// = surface 圆角顶 + 抓手条 + titleS 标题 + 菜单行（图标 20 + 标签）。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/calendar_types.dart';
import '../../core/models/date_provider.dart';

/// 设置页入口行（debug 构建才渲染；v2 行语言与 _SettingsRow 同构）。
class DebugClockTile extends ConsumerWidget {
  const DebugClockTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final dp = ref.watch(dateProviderProvider);
    final fixed = dp is FixedDateProvider;
    return InkWell(
      onTap: () => _showMenu(context, ref),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s4,
            vertical: AppSpace.s3,
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: palette.surfaceAlt,
                  borderRadius: AppRadius.rSm,
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  size: 17,
                  color: palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Copy.debugClock, style: theme.textTheme.bodyL),
                    Text(
                      fixed ? '已固定 ${dp.today.isoString}' : '跟随系统时间',
                      style: theme.textTheme.bodyS.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 14,
                color: palette.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 弹层（v2 sheet 容器：surface 圆角顶 + 高投影 + 抓手条）。
  void _showMenu(BuildContext context, WidgetRef ref) {
    final palette = TargetPalette.of(context);
    final dp = ref.read(dateProviderProvider);
    final today = dp.today;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        key: const ValueKey('debugClockSheet'),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.vertical(top: AppRadius.rXl.topLeft),
          boxShadow: palette.shadowHigh,
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s3,
          AppSpace.s5,
          AppSpace.s5 + 8,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 抓手条（冻结稿 .grab）。2026-08-25：stretch 列同款修正
              //（Center 回 40，见 notification_list 同日注记）。
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpace.s3),
                  decoration: BoxDecoration(
                    color: palette.divider,
                    borderRadius: AppRadius.rFull,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s1),
                child: Text(
                  Copy.debugClock,
                  style: Theme.of(sheetContext).textTheme.titleS,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.s2),
                child: Text(
                  '今天 = ${today.isoString}（${today.weekStart.isoString} 起）',
                  style: Theme.of(sheetContext).textTheme.bodyS
                      .copyWith(color: palette.onSurfaceVariant),
                ),
              ),
              _DebugActionRow(
                icon: Icons.skip_next_rounded,
                title: '跳到下周一',
                sub: '验证自然周切换后的状态与提醒',
                onTap: () {
                  _travel(ref, today.weekStart.next.monday);
                  Navigator.of(sheetContext).pop();
                },
              ),
              _DebugActionRow(
                icon: Icons.calendar_month_rounded,
                title: '去任意一天',
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
              _DebugActionRow(
                icon: Icons.restore_rounded,
                title: '回到真实时间',
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
      ),
    );
  }

  void _travel(WidgetRef ref, LocalDate day) {
    // 取正午避免 0 点边界歧义（R1 已有专门测试覆盖边界）。
    ref.read(dateProviderProvider.notifier).state = FixedDateProvider(
      day.atStartOfDay.add(const Duration(hours: 12)),
    );
    _refresh(ref);
  }

  void _refresh(WidgetRef ref) {
    ref.invalidate(todayProvider);
    ref.invalidate(statsProvider);
  }
}

/// 菜单行（目标菜单 .menu 行语法：图标 20 + 标题，副题可选）。
class _DebugActionRow extends StatelessWidget {
  const _DebugActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.sub,
  });

  final IconData icon;
  final String title;
  final String? sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s2,
          vertical: AppSpace.s4,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: palette.onSurfaceVariant),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyL),
                  if (sub case final s?) ...[
                    const SizedBox(height: 2),
                    Text(
                      s,
                      style: theme.textTheme.bodyS.copyWith(
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
