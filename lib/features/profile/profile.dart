/// 账号资料（003 T018 · research D7 / ui-contract.md）：
/// 编辑 bottom sheet + 同源头像渲染（今日页账号区与我的页账号卡共用，
/// 未填写 = 渐变默认头像 + 昵称兜底「我」）。
///
/// 004 T016 按冻结稿 v2-settings 板 4 换装：头部内联「完成」与预览行
/// 退役 → 全宽昵称输入（surfaceAlt 底 + 1px divider 边，与编辑器输入
/// 同语言）+ 4 列 56px 头像格（surfaceAlt 底 + 26px 环色图标，选中 =
/// 2.5px 环色描边，替代 accent 双环）+ 底部全宽胶囊主按钮「保存」。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';
import '../../core/models/entities.dart' show Profile;
import '../../core/models/goal_icon_catalog.dart';

/// 8 枚预设头像（research D7：图标库取 + 令牌环色）。键即持久化
/// avatarKey 值域，环色表 [kAvatarRingByKey] 已随 004 T002 移入
/// design_tokens.dart（色值真源单一化，浅深自适应）。

/// 昵称展示值：空/未填 → 默认「我」。
String profileNicknameOf(Profile? p) {
  final n = (p?.nickname ?? '').trim();
  return n.isEmpty ? Copy.profileDefaultNickname : n;
}

/// 同源头像：预设 = 环色 22% 底（color-mix 语义）+ 同色图标；
/// 未选 = 头像渐变 + 昵称首字（兜底「我」）。
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, this.profile, this.size = 44});

  final Profile? profile;

  /// 直径（今日账号区 44 / 我的页账号卡 52）。
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final ring = kAvatarRingByKey[profile?.avatarKey ?? ''];
    if (ring == null) {
      // 默认枚：渐变底 + 首字。
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kAvatarGradA, kAvatarGradB],
          ),
          shape: BoxShape.circle,
        ),
        child: Text(
          profileNicknameOf(profile).characters.first,
          // 白字 + height 1：与我的页账号卡现有头像惯例一致。
          style: Theme.of(context).textTheme.titleM
              .copyWith(color: Colors.white, height: 1),
        ),
      );
    }
    final ringColor = ring.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        // color-mix(in srgb, ring 22%, surface) 的 Dart 等价。
        color: Color.lerp(palette.surface, ringColor, 0.22),
        shape: BoxShape.circle,
      ),
      child: Icon(
        GoalIconCatalog.byKey(profile?.avatarKey).icon,
        size: size * 0.5,
        color: ringColor,
      ),
    );
  }
}

/// 弹起资料编辑 sheet（今日页账号区 / 我的页账号卡共用入口；
/// 冻结稿 .sheet = surface 圆角顶 + 抓手条 + 高投影）。
Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final palette = TargetPalette.of(sheetContext);
      return Padding(
        // 键盘弹起时 sheet 随之上移（viewInsets），内容贴底。
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          key: const ValueKey('profileSheet'),
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
          child: const _ProfileSheet(),
        ),
      );
    },
  );
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet();

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  late final TextEditingController _nick;
  String? _avatarKey; // null = 默认渐变枚

  @override
  void initState() {
    super.initState();
    _nick = TextEditingController();
    final cached = ref.read(profileProvider).value;
    if (cached != null) {
      // 上游（今日账号区/我的页账号卡）已 watch：流里有现值。
      _nick.text = cached.nickname ?? '';
      _avatarKey = _validKey(cached.avatarKey);
    } else {
      // 首启无缓存：异步拉一次做初始回显（内存库毫秒级）。
      ref.read(settingsRepoProvider).getProfile().then((p) {
        if (!mounted) return;
        setState(() {
          _nick.text = p.nickname ?? '';
          _avatarKey = _validKey(p.avatarKey);
        });
      });
    }
  }

  /// 未知/遗留键一律落回默认枚。
  static String? _validKey(String? k) =>
      k != null && kAvatarRingByKey.containsKey(k) ? k : null;

  @override
  void dispose() {
    _nick.dispose();
    super.dispose();
  }

  /// 草稿：空白昵称归一为 NULL（未填语义，展示层兜底「我」）。
  Profile get _draft {
    final n = _nick.text.trim();
    return Profile(nickname: n.isEmpty ? null : n, avatarKey: _avatarKey);
  }

  Future<void> _save() async {
    await ref.read(settingsRepoProvider).updateProfile(_draft);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final theme = Theme.of(context);
    final cells = <Widget>[
      for (final entry in kAvatarRingByKey.entries)
        _AvatarCell(
          entry: entry,
          selected: _avatarKey == entry.key,
          onTap: () => setState(
            // 再点一次 = 回默认枚（原型同款交互）。
            () => _avatarKey = _avatarKey == entry.key ? null : entry.key,
          ),
        ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 抓手条（冻结稿 .grab）。
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: AppSpace.s3),
          decoration: BoxDecoration(
            color: palette.divider,
            borderRadius: AppRadius.rFull,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s3),
          child: Text(Copy.profileSheetTitle, style: theme.textTheme.titleS),
        ),
        // 全宽昵称输入（冻结稿 .input：surfaceAlt 底 + 1px divider 边，
        // rMd、bodyL、内垫 s4/s3——与编辑器输入同语言）。
        TextField(
          key: const ValueKey('profileNickField'),
          controller: _nick,
          maxLength: 12,
          style: theme.textTheme.bodyL,
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            filled: true,
            fillColor: palette.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s4,
              vertical: AppSpace.s3,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(color: palette.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.rMd,
              borderSide: BorderSide(color: palette.accent),
            ),
          ),
        ),
        // 头像格（冻结稿 .avgrid：4 等分列 gap s4，格内居中；两行间
        // 距 s4、组竖向 margin s4）。
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
          child: Column(
            children: [
              for (var r = 0; r < cells.length; r += 4)
                Padding(
                  padding: EdgeInsets.only(top: r == 0 ? 0 : AppSpace.s4),
                  child: Row(
                    children: [
                      for (final cell in cells.sublist(
                        r,
                        r + 4 > cells.length ? cells.length : r + 4,
                      ))
                        Expanded(child: Center(child: cell)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // 全宽胶囊主按钮（冻结稿 .btn-primary：accent 底 + accentOn
        // titleS + 中投影，与详情页 _PillButton 同族）。
        Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.rFull,
            boxShadow: palette.shadowMid,
          ),
          child: Material(
            color: palette.accent,
            borderRadius: AppRadius.rFull,
            child: InkWell(
              onTap: _save,
              borderRadius: AppRadius.rFull,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.s4),
                child: Center(
                  child: Text(
                    Copy.profileDone,
                    style: theme.textTheme.titleS.copyWith(
                      color: palette.accentOn,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 预设头像格（冻结稿 .avp）：56px 圆 + surfaceAlt 底 + 26px 环色
/// 图标；选中 = 2.5px 环色描边（transparent → ring，150ms 过渡）。
class _AvatarCell extends StatelessWidget {
  const _AvatarCell({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final MapEntry<String, MajorColor> entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = TargetPalette.of(context);
    final ring = entry.value.of(context);
    return Semantics(
      button: true,
      selected: selected,
      // 无障碍名取图标所属领域（如「运动」）。
      label: GoalIconCatalog.byKey(entry.key).domain.zhLabel,
      child: InkWell(
        key: ValueKey('avatarCell-${entry.key}'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? ring : Colors.transparent,
              width: 2.5,
            ),
          ),
          child: Icon(
            GoalIconCatalog.byKey(entry.key).icon,
            size: 26,
            color: ring,
          ),
        ),
      ),
    );
  }
}
