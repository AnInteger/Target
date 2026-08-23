/// 共享次级顶栏 PageTopBar（005 T007，research D5+D6，契约 §2）。
///
/// 四个次级 push 页（全部目标/我的/编辑器/详情）顶栏同构一组件：
/// 返回圆钮（视觉 38px 冻结稿 .ga-btn/.dt-btn 几何：surface 底 +
/// divider 描边 + 低影 + chevron_left 24）触达外扩 44×44（SizedBox+
/// Center 模式，D6 视觉零变化）+ 标题（titleM，可携紧邻计数配件）+
/// 右侧 trailing 槽（新建胶囊 / ⋯菜单钮 / 空）。水平 padding =
/// AppSpace.s4（次级页列表档 16），栏内垂直 s3/s2（冻结稿现值）。
/// hero 两屏（今日/回顾冻结稿头部）不套用。
library;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

class PageTopBar extends StatelessWidget {
  const PageTopBar({
    super.key,
    required this.title,
    this.titleKey,
    this.titleAccessory,
    this.trailing,
    this.onBack,
  });

  /// 标题（titleM；四页标题皆短，不做溢出处理）。
  final String title;

  /// 标题挂 key（我的页 screenTitle 测试锚点沿用）。
  final Key? titleKey;

  /// 紧随标题的配件（全部目标页计数胶囊；其余页空）。
  final Widget? titleAccessory;

  /// 右缘槽（新建胶囊 / ⋯菜单钮；我的/编辑器空）。
  final Widget? trailing;

  /// 返回动作；null = `Navigator.maybePop` 默认（编辑器可注入等价语义）。
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final button = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.surface,
        border: Border.all(color: palette.divider),
        boxShadow: palette.shadowLow,
      ),
      child: Icon(Icons.chevron_left, size: 24, color: palette.onSurface),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s4,
        AppSpace.s3,
        AppSpace.s4,
        AppSpace.s2,
      ),
      child: Row(
        children: [
          // D6 触达 44：InkWell 铺满 44×44 槽、内 Center 38 视觉钮
          // （命中区 ≥44、视觉零变化）。
          SizedBox(
            width: 44,
            height: 44,
            child: InkWell(
              key: const ValueKey('pageTopBarBack'),
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Center(
                child: Tooltip(
                  // 无障碍语义与 AppBar 返回钮同源（读屏可寻）。
                  message: MaterialLocalizations.of(context).backButtonTooltip,
                  child: button,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.s3),
          Text(title, key: titleKey, style: Theme.of(context).textTheme.titleM),
          if (titleAccessory != null) ...[
            const SizedBox(width: AppSpace.s1),
            titleAccessory!,
          ],
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}
