/// v3 设计令牌（iOS 原生 + 局部 Liquid Glass）。
///
/// 真源镜像：design/tokens.css（?v=v3b）↔ 本文件 ↔
/// ios/TargetWidgets/DesignTokens.swift——改值一次提交内三端同步
/// （006 contracts/design-language.md）。
/// 字体：平台默认（iOS=SF Pro/PingFang，不打包字体文件）。
/// 标题族字重统一 600（R2 裁定：PingFang 止于 Semibold）。
library;

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// 分类色板（iOS 系统色 · 浅深成对；goals.colorKey 值域）
// ---------------------------------------------------------------------------

/// 目标颜色板（9 键；gray 为未分类/其他默认）。
abstract final class GoalPalette {
  static const Map<String, Color> light = {
    'blue': Color(0xFF007AFF),
    'green': Color(0xFF34C759),
    'orange': Color(0xFFFF9500),
    'purple': Color(0xFFAF52DE),
    'pink': Color(0xFFFF2D55),
    'indigo': Color(0xFF5856D6),
    'teal': Color(0xFF30B0C7),
    'red': Color(0xFFFF3B30),
    'gray': Color(0xFF8E8E93),
  };

  static const Map<String, Color> dark = {
    'blue': Color(0xFF0A84FF),
    'green': Color(0xFF30D158),
    'orange': Color(0xFFFF9F0A),
    'purple': Color(0xFFBF5AF2),
    'pink': Color(0xFFFF375F),
    'indigo': Color(0xFF5E5CE6),
    'teal': Color(0xFF40C8E0),
    'red': Color(0xFFFF453A),
    'gray': Color(0xFF98989F),
  };

  /// 按 colorKey 取色（未知键回退 gray）。
  static Color byKey(String key, {required Brightness brightness}) =>
      (brightness == Brightness.light ? light : dark)[key] ??
      (brightness == Brightness.light ? light : dark)['gray']!;
}

// ---------------------------------------------------------------------------
// TargetPalette（ThemeExtension）
// ---------------------------------------------------------------------------

class TargetPalette extends ThemeExtension<TargetPalette> {
  const TargetPalette({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onSurfaceTertiary,
    required this.accent,
    required this.accentOn,
    required this.accentTint,
    required this.accentText,
    required this.milestone,
    required this.milestoneTint,
    required this.milestoneText,
    required this.positive,
    required this.positiveFill,
    required this.positiveOn,
    required this.warning,
    required this.divider,
    required this.scrim,
    required this.danger,
    required this.dangerOn,
    required this.headerGrad,
    required this.glassShell,
    required this.glassCard,
    required this.glassBorder,
    required this.glassHighlight,
    required this.blur,
    required this.shadowLow,
    required this.shadowMid,
    required this.shadowHigh,
    required this.shadowCta,
  });

  /// 页面底色（iOS 分组底）。
  final Color background;

  /// 卡片。
  final Color surface;

  /// 卡上内嵌控件底。
  final Color surfaceAlt;

  /// 主文 / 次文（AA）/ 三档（时间戳、占位，非正文级）。
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onSurfaceTertiary;

  /// 行动色（填充/图形）与实底按钮标签（17px/600 大字号档）。
  final Color accent;
  final Color accentOn;

  /// 选中态淡底（tab 胶囊透镜语境之外的内嵌底）。
  final Color accentTint;

  /// 正文级蓝（链接；≥4.5:1）。
  final Color accentText;

  /// 里程碑语义：图形橙 / 暖色 tile / 正文级橙。
  final Color milestone;
  final Color milestoneTint;
  final Color milestoneText;

  /// 完成/达成（iOS 绿族）。
  final Color positive;
  final Color positiveFill;
  final Color positiveOn;

  /// 落后/注意（克制琥珀）。
  final Color warning;

  /// 发丝分隔线。
  final Color divider;

  /// sheet/菜单遮罩。
  final Color scrim;

  /// 危险操作（删除）。
  final Color danger;
  final Color dangerOn;

  /// tab 屏头部渐变（淡紫→粉→灰；深色暗紫系；自上而下）。
  final List<Color> headerGrad;

  /// Liquid Glass（R2 定稿：dock/记录钮/头部控件 = 浅玻璃）。
  final Color glassShell;
  final Color glassCard;
  final Color glassBorder;
  final Color glassHighlight;
  final double blur;

  /// 阴影：low=卡 / mid=悬浮 / high=sheet / cta=主行动钮光晕。
  final List<BoxShadow> shadowLow;
  final List<BoxShadow> shadowMid;
  final List<BoxShadow> shadowHigh;
  final List<BoxShadow> shadowCta;

  /// 浅色 · v3（同步 tokens.css :root ?v=v3b）。
  static const TargetPalette light = TargetPalette(
    background: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2F2F7),
    onSurface: Color(0xFF1C1C1E),
    onSurfaceVariant: Color(0xFF6C6C70),
    onSurfaceTertiary: Color(0xFF8E8E93),
    accent: Color(0xFF007AFF),
    accentOn: Color(0xFFFFFFFF),
    accentTint: Color(0x1A007AFF),
    accentText: Color(0xFF0066D6),
    milestone: Color(0xFFFF9500),
    milestoneTint: Color(0xFFFFF3E0),
    milestoneText: Color(0xFF9A5700),
    positive: Color(0xFF188038),
    positiveFill: Color(0xFF34C759),
    positiveOn: Color(0xFF0A3D1D),
    warning: Color(0xFF9A5700),
    divider: Color(0xFFE5E5EA),
    scrim: Color(0x52000000),
    danger: Color(0xFFFF3B30),
    dangerOn: Color(0xFFFFFFFF),
    headerGrad: [
      Color(0xFFE2D5F0),
      Color(0xFFEDD8E8),
      Color(0xFFF2F2F7),
      Color(0xFFF2F2F7),
    ],
    glassShell: Color(0xB8F2F2F7),
    glassCard: Color(0x9EFFFFFF),
    glassBorder: Color(0xA6FFFFFF),
    glassHighlight: Color(0xD9FFFFFF),
    blur: 24,
    shadowLow: [BoxShadow(offset: Offset(0, 1), blurRadius: 6, color: Color(0x12000000))],
    shadowMid: [BoxShadow(offset: Offset(0, 2), blurRadius: 16, color: Color(0x1A000000))],
    shadowHigh: [BoxShadow(offset: Offset(0, -6), blurRadius: 40, color: Color(0x2E000000))],
    shadowCta: [BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x59007AFF))],
  );

  /// 深色 · v3（iOS 暗色系：纯黑分组底 + #1C1C1E 卡）。
  static const TargetPalette dark = TargetPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF1C1C1E),
    surfaceAlt: Color(0xFF2C2C2E),
    onSurface: Color(0xFFF5F5F7),
    onSurfaceVariant: Color(0xFFA5A5AB),
    onSurfaceTertiary: Color(0xFF7C7C83),
    accent: Color(0xFF0A84FF),
    accentOn: Color(0xFFFFFFFF),
    accentTint: Color(0x380A84FF),
    accentText: Color(0xFF409CFF),
    milestone: Color(0xFFFF9F0A),
    milestoneTint: Color(0xFF3A2A10),
    milestoneText: Color(0xFFFFB86B),
    positive: Color(0xFF30D158),
    positiveFill: Color(0xFF30D158),
    positiveOn: Color(0xFF062B15),
    warning: Color(0xFFFFB86B),
    divider: Color(0xFF38383A),
    scrim: Color(0x8C000000),
    danger: Color(0xFFFF453A),
    dangerOn: Color(0xFFFFFFFF),
    headerGrad: [
      Color(0xFF362F4A),
      Color(0xFF2B2539),
      Color(0xFF161618),
      Color(0xFF000000),
    ],
    glassShell: Color(0xB81C1C1E),
    glassCard: Color(0x9E2C2C2E),
    glassBorder: Color(0x1FFFFFFF),
    glassHighlight: Color(0x2EFFFFFF),
    blur: 24,
    shadowLow: [BoxShadow(offset: Offset(0, 1), blurRadius: 6, color: Color(0x59000000))],
    shadowMid: [BoxShadow(offset: Offset(0, 2), blurRadius: 16, color: Color(0x73000000))],
    shadowHigh: [BoxShadow(offset: Offset(0, -6), blurRadius: 40, color: Color(0x8C000000))],
    shadowCta: [BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x660A84FF))],
  );

  /// 取当前主题注入的令牌（[AppTheme] 恒安装，非空）。
  static TargetPalette of(BuildContext context) =>
      Theme.of(context).extension<TargetPalette>()!;

  @override
  TargetPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? onSurfaceTertiary,
    Color? accent,
    Color? accentOn,
    Color? accentTint,
    Color? accentText,
    Color? milestone,
    Color? milestoneTint,
    Color? milestoneText,
    Color? positive,
    Color? positiveFill,
    Color? positiveOn,
    Color? warning,
    Color? divider,
    Color? scrim,
    Color? danger,
    Color? dangerOn,
    List<Color>? headerGrad,
    Color? glassShell,
    Color? glassCard,
    Color? glassBorder,
    Color? glassHighlight,
    double? blur,
    List<BoxShadow>? shadowLow,
    List<BoxShadow>? shadowMid,
    List<BoxShadow>? shadowHigh,
    List<BoxShadow>? shadowCta,
  }) =>
      TargetPalette(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        onSurface: onSurface ?? this.onSurface,
        onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
        onSurfaceTertiary: onSurfaceTertiary ?? this.onSurfaceTertiary,
        accent: accent ?? this.accent,
        accentOn: accentOn ?? this.accentOn,
        accentTint: accentTint ?? this.accentTint,
        accentText: accentText ?? this.accentText,
        milestone: milestone ?? this.milestone,
        milestoneTint: milestoneTint ?? this.milestoneTint,
        milestoneText: milestoneText ?? this.milestoneText,
        positive: positive ?? this.positive,
        positiveFill: positiveFill ?? this.positiveFill,
        positiveOn: positiveOn ?? this.positiveOn,
        warning: warning ?? this.warning,
        divider: divider ?? this.divider,
        scrim: scrim ?? this.scrim,
        danger: danger ?? this.danger,
        dangerOn: dangerOn ?? this.dangerOn,
        headerGrad: headerGrad ?? this.headerGrad,
        glassShell: glassShell ?? this.glassShell,
        glassCard: glassCard ?? this.glassCard,
        glassBorder: glassBorder ?? this.glassBorder,
        glassHighlight: glassHighlight ?? this.glassHighlight,
        blur: blur ?? this.blur,
        shadowLow: shadowLow ?? this.shadowLow,
        shadowMid: shadowMid ?? this.shadowMid,
        shadowHigh: shadowHigh ?? this.shadowHigh,
        shadowCta: shadowCta ?? this.shadowCta,
      );

  @override
  TargetPalette lerp(TargetPalette? other, double t) {
    if (other is! TargetPalette) return this;
    return TargetPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      onSurfaceTertiary: Color.lerp(onSurfaceTertiary, other.onSurfaceTertiary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      accentTint: Color.lerp(accentTint, other.accentTint, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      milestone: Color.lerp(milestone, other.milestone, t)!,
      milestoneTint: Color.lerp(milestoneTint, other.milestoneTint, t)!,
      milestoneText: Color.lerp(milestoneText, other.milestoneText, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      positiveFill: Color.lerp(positiveFill, other.positiveFill, t)!,
      positiveOn: Color.lerp(positiveOn, other.positiveOn, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerOn: Color.lerp(dangerOn, other.dangerOn, t)!,
      headerGrad: [
        for (var i = 0; i < headerGrad.length; i++)
          Color.lerp(headerGrad[i], other.headerGrad[i], t)!,
      ],
      glassShell: Color.lerp(glassShell, other.glassShell, t)!,
      glassCard: Color.lerp(glassCard, other.glassCard, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
      blur: blur + (other.blur - blur) * t,
      shadowLow: BoxShadow.lerpList(shadowLow, other.shadowLow, t) ?? shadowLow,
      shadowMid: BoxShadow.lerpList(shadowMid, other.shadowMid, t) ?? shadowMid,
      shadowHigh: BoxShadow.lerpList(shadowHigh, other.shadowHigh, t) ?? shadowHigh,
      shadowCta: BoxShadow.lerpList(shadowCta, other.shadowCta, t) ?? shadowCta,
    );
  }
}

// ---------------------------------------------------------------------------
// 刻度（间距 / 屏级 / 圆角 / 动效）
// ---------------------------------------------------------------------------

abstract final class AppSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s12 = 48;
}

abstract final class AppScreen {
  /// 页缘 20（R1 Figma px-5）。
  static const double padX = 20;

  /// 卡缘 16。
  static const double cardPadX = 16;
  static const double titleTop = 8;
  static const double titleBand = 44;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double full = 9999;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);

  /// sheet 升降。
  static const Duration sheet = Duration(milliseconds: 320);
  static const Curve easeStandard = Cubic(0.2, 0, 0, 1);
}

// ---------------------------------------------------------------------------
// 字阶便捷取用（Material 15 槽位的子集命名；数字恒 tabular）
// ---------------------------------------------------------------------------

extension AppTextStyle on TextTheme {
  /// displayL：34 / 600（tab 屏大标题）。
  TextStyle get displayL => displayLarge!;

  /// displayM：32 / 600（次级屏题）。
  TextStyle get displayM => displayMedium!;

  /// displayS：26 / 600（sheet 主标题）。
  TextStyle get displayS => displaySmall!;

  /// titleL：22 / 600（卡题/大数字）。
  TextStyle get titleL => titleLarge!;

  /// titleM：17 / 600（区块头/行主文）。
  TextStyle get titleM => titleMedium!;

  /// titleS：15 / 600（行内强调）。
  TextStyle get titleS => titleSmall!;

  /// bodyL：17 / 400（iOS body）。
  TextStyle get bodyL => bodyLarge!;

  /// bodyM：15 / 400。
  TextStyle get bodyM => bodyMedium!;

  /// bodyS：13 / 400（辅助）。
  TextStyle get bodyS => bodySmall!;

  /// labelS：11 / 400。
  TextStyle get labelS => labelSmall!;
}

// ---------------------------------------------------------------------------
// App 主题
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  static ThemeData light() => _build(TargetPalette.light, Brightness.light);

  static ThemeData dark() => _build(TargetPalette.dark, Brightness.dark);

  static ThemeData _build(TargetPalette p, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.accentOn,
      secondary: p.positiveFill,
      onSecondary: p.positiveOn,
      tertiary: p.milestone,
      onTertiary: p.milestoneText,
      error: p.danger,
      onError: p.dangerOn,
      surface: p.surface,
      onSurface: p.onSurface,
      onSurfaceVariant: p.onSurfaceVariant,
      surfaceContainerLowest: brightness == Brightness.light
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000),
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surfaceAlt,
      surfaceContainerHigh: brightness == Brightness.light
          ? const Color(0xFFEBEBF0)
          : const Color(0xFF2C2C2E),
      surfaceContainerHighest: brightness == Brightness.light
          ? const Color(0xFFE3E3EA)
          : const Color(0xFF343436),
      outline: p.onSurfaceTertiary,
      outlineVariant: p.divider,
      inverseSurface: brightness == Brightness.light
          ? const Color(0xFF2C2C2E)
          : const Color(0xFFF2F2F7),
      onInverseSurface: brightness == Brightness.light
          ? const Color(0xFFF2F2F7)
          : const Color(0xFF1C1C1E),
      scrim: p.scrim,
    );
    final text = _textTheme(p);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      textTheme: text,
      extensions: [p],
    ).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: p.divider),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: AppSpace.s1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          backgroundColor: p.accent,
          foregroundColor: p.accentOn,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s5,
            vertical: AppSpace.s4,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.surface,
        contentTextStyle: text.bodyM.copyWith(color: p.onSurface),
        actionTextColor: p.accentText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.divider, thickness: 1, space: 1),
    );
  }

  /// SF 阶梯 → Material 槽位（全档 tabular；标题族 600——R2 裁定）。
  static TextTheme _textTheme(TargetPalette p) {
    const f = [FontFeature.tabularFigures()];
    final on = p.onSurface;
    final variant = p.onSurfaceVariant;
    final tertiary = p.onSurfaceTertiary;
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
        color: on,
        fontFeatures: f,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02,
        color: on,
        fontFeatures: f,
      ),
      displaySmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01,
        color: on,
        fontFeatures: f,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: on,
        fontFeatures: f,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: on,
        fontFeatures: f,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: on,
        fontFeatures: f,
      ),
      titleSmall: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: on,
        fontFeatures: f,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: on,
        fontFeatures: f,
      ),
      bodyMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: variant,
        fontFeatures: f,
      ),
      bodySmall: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: variant,
        fontFeatures: f,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: tertiary,
        fontFeatures: f,
      ),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: variant,
        fontFeatures: f,
      ),
    );
  }
}
