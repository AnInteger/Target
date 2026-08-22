/// 账号资料（003 T018 · research D7 / ui-contract.md）：
/// 编辑 bottom sheet + 同源头像渲染（今日页账号区与我的页账号卡共用，
/// 未填写 = 渐变默认头像 + 昵称兜底「我」）。
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

  /// 直径（今日账号区 44 / sheet 预览 56 / 我的页账号卡 52）。
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
              colors: [kAvatarGradA, kAvatarGradB]),
          shape: BoxShape.circle,
        ),
        child: Text(
          profileNicknameOf(profile).characters.first,
          // 白字 + height 1：与我的页账号卡现有头像惯例一致。
          style: Theme.of(context)
              .textTheme
              .titleM
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
      child: Icon(GoalIconCatalog.byKey(profile?.avatarKey).icon,
          size: size * 0.5, color: ringColor),
    );
  }
}

/// 弹起资料编辑 sheet（今日页账号区 / 我的页账号卡共用入口）。
Future<void> showProfileSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ProfileSheet(),
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
    return Padding(
      // 键盘弹起时 sheet 随之上移（viewInsets），内容贴底。
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpace.s2),
          // 抓手条。
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: palette.divider,
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s6, AppSpace.s4, AppSpace.s5, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(Copy.profileSheetTitle,
                      style: Theme.of(context).textTheme.titleM),
                ),
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.accentOn,
                  ),
                  child: const Text(Copy.profileDone),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s6, AppSpace.s4, AppSpace.s6, 0),
            child: Row(
              children: [
                // 预览随输入即时刷新（昵称首字/所选头像）。
                ProfileAvatar(profile: _draft, size: 56),
                const SizedBox(width: AppSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Copy.profileNicknameLabel,
                          style: Theme.of(context)
                              .textTheme
                              .labelS
                              .copyWith(color: palette.onSurfaceVariant)),
                      TextField(
                        key: const ValueKey('profileNickField'),
                        controller: _nick,
                        maxLength: 12,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                            isDense: true, counterText: ''),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s6, AppSpace.s4, AppSpace.s6, AppSpace.s2),
            child: Text(Copy.profileAvatarLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelS
                    .copyWith(color: palette.onSurfaceVariant)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.s6, 0, AppSpace.s6, AppSpace.s6),
            child: Wrap(
              spacing: AppSpace.s3,
              runSpacing: AppSpace.s3,
              children: [
                for (final entry in kAvatarRingByKey.entries)
                  _AvatarCell(
                    entry: entry,
                    selected: _avatarKey == entry.key,
                    onTap: () => setState(() =>
                        // 再点一次 = 回默认枚（原型同款交互）。
                        _avatarKey = _avatarKey == entry.key ? null : entry.key),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 预设头像格：环色 22% 底 + 同色图标；选中 = 表面留缝 + accent 双环
/// （原型 .av.sel 的 box-shadow 双环语义）。
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
    final cell = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.lerp(palette.surface, ring, 0.22),
        shape: BoxShape.circle,
      ),
      child: Icon(GoalIconCatalog.byKey(entry.key).icon,
          size: 26, color: ring),
    );
    return Semantics(
      button: true,
      selected: selected,
      // 004：环色退役 zhLabel，无障碍名取图标所属领域（如「运动」）。
      label:
          '${Copy.profileAvatarLabel} ${GoalIconCatalog.byKey(entry.key).domain.zhLabel}',
      child: InkWell(
        key: ValueKey('avatarCell-${entry.key}'),
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: selected
            ? Container(
                padding: const EdgeInsets.all(2), // 表面留缝宽。
                decoration: BoxDecoration(
                  color: palette.accent,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    shape: BoxShape.circle,
                  ),
                  child: cell,
                ),
              )
            : cell,
      ),
    );
  }
}
