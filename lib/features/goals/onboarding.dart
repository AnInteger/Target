/// 首启初始屏 v2（004 US6 · 基准图 03 黑底极简品牌屏，FR-011）。
///
/// 纯深底（品牌屏恒深——不随系统主题）+ 左上品牌图形（accent 圆 +
/// 点阵字形 TodayGlyphPainter，与 dock 今日页签同源）+ 一句中文主张
///（正式语域）+ 单一主行动按钮「开始使用」→ 今日页（SC-005 ≤1 击）。
/// 机制不动：onboardingCompleted 判定在 app 层，按钮即写库，再次
/// 启动直达。基准图英文主张/服务条款/社交证明数字为模板残留，MUST
/// NOT 引入；002 模板 chip 动线随屏退役——编辑器仍带「从一句熟悉的
/// 话开始」入口。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_glyph.dart';
import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/copy.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  /// 主行动 = 完成引导并进入主界面（≤1 交互，FR-011）。
  Future<void> _start() async {
    final repo = ref.read(settingsRepoProvider);
    final s = await repo.get();
    await repo.update(s.copyWith(onboardingCompleted: true));
    if (!mounted) return;
    context.go('/today');
  }

  @override
  Widget build(BuildContext context) {
    // 品牌屏恒深底（基准图 03 纯黑极简）——覆写主题不随系统切换。
    return Theme(
      data: AppTheme.dark(),
      child: Builder(
        builder: (context) {
          final palette = TargetPalette.of(context);
          final theme = Theme.of(context);
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppScreen.padX),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpace.s12),
                    // 品牌图形：accent 圆 + 点阵字形（v2 唯一源）。
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: palette.accent,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CustomPaint(
                            painter: TodayGlyphPainter(
                              color: palette.background,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Copy.onboardingTitle,
                      style: theme.textTheme.displayM.copyWith(height: 1.3),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    Text(
                      Copy.onboardingSubtitle,
                      style: theme.textTheme.bodyL.copyWith(
                        color: palette.onSurfaceVariant,
                        height: 1.7,
                      ),
                    ),
                    const Spacer(),
                    // 单一主行动：浅底胶囊整宽 → 今日页；无注册/登录/
                    // 条款/社交证明（FR-011 MUST NOT 清单）。
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('onboardingStart'),
                        onPressed: _start,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.onSurface,
                          foregroundColor: palette.background,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpace.s4,
                          ),
                        ),
                        child: Text(
                          Copy.onboardingStart,
                          style: theme.textTheme.titleM,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
